//
//  MetalImageView.swift
//
//  Created by Shuichi Tsutsumi on 2016/12/11.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders

class MetalImageView: MTKView, MTKViewDelegate {

    private var commandQueue: MTLCommandQueue!

    internal var textureLoader: MTKTextureLoader!
    var texture: MTLTexture? {
        didSet {
            if let texture = texture {
                let pixelFormat = texture.pixelFormat
                colorPixelFormat = pixelFormat != MTLPixelFormat.invalid ? pixelFormat : MTLPixelFormat.rgba8Unorm
                DispatchQueue.main.async(execute: {
                    let contentMode = self.contentMode
                    self.transform(contentMode: contentMode)
                    self.setNeedsDisplay()
                })
            }
        }
    }
    private var lanczos: MPSImageLanczosScale!
    var transformedTexture: MTLTexture? // TODO: only get for external
    
    private let vertexData: [Float] = [
            -1, -1, 0, 1,
            1, -1, 0, 1,
            -1,  1, 0, 1,
            1,  1, 0, 1
    ]
    private lazy var vertexBuffer: MTLBuffer? = {
        let size = vertexData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: vertexData, length: size)
    }()

    private let textureCoordinateData: [Float] = [
            0, 1,
            1, 1,
            0, 0,
            1, 0
    ]
    private lazy var texCoordBuffer: MTLBuffer? = {
        let size = textureCoordinateData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: textureCoordinateData, length: size)
    }()

    // additional textures to pass to the fragment shader
    var additionalTextures: [MTLTexture] = []
    // additional buffers to pass to the fragment shader
    var additionalBuffers: [MTLBuffer] = []
    
    private var renderDescriptor: MTLRenderPipelineDescriptor?
    private var renderPipeline: MTLRenderPipelineState?

    // =========================================================================
    // MARK: - Initialization
    
    init(frame frameRect: CGRect) {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        self.device = device
        commonInit()
    }
    
    private func commonInit() {
        guard let device = device else {fatalError()}
        commandQueue = device.makeCommandQueue()
        textureLoader = MTKTextureLoader(device: device)
        lanczos = MPSImageLanczosScale(device: device)
        
        framebufferOnly = false
        enableSetNeedsDisplay = true
        isPaused = true
        delegate = self
    }

    // =========================================================================
    // MARK: - Private
        
    private func transform(contentMode: UIViewContentMode) {
        guard let device = device else {fatalError()}
        guard let drawable = currentDrawable, let texture = texture else {return}
        guard texture.width != drawable.texture.width || texture.height != drawable.texture.height else {
            transformedTexture = texture
            return
        }
        
        var transform: MPSScaleTransform = contentMode.scaleTransform(
            from: texture,
            to: drawable.texture)
        
        // make dest texture
        transformedTexture = device.makeTexture(pixelFormat: texture.pixelFormat, width: drawable.texture.width, height: drawable.texture.height)
        guard let transformedTexture = transformedTexture else {fatalError()}
        
        // resize
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) in
            lanczos.scaleTransform = transformPtr
            lanczos.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: transformedTexture)
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func makeBuffer(bytes: UnsafeRawPointer, length: Int) -> MTLBuffer {
        guard let device = device else {fatalError()}
        return device.makeBuffer(bytes: bytes, length: length, options: [])!
    }
    
    func registerShaders(library: MTLLibrary, vertexFunctionName: String, fragmentFunctionName: String) {
        renderDescriptor = MTLRenderPipelineDescriptor()
        guard let descriptor = renderDescriptor else {return}
        descriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        descriptor.fragmentFunction = library.makeFunction(name: fragmentFunctionName)
    }
    
    private func makePipelineIfNeeded() {
        guard let texture = texture else {return}
        guard let descriptor = renderDescriptor else {return}
        guard let device = device else {fatalError()}
        descriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
        renderPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func encodeShaders(commandBuffer: MTLCommandBuffer) {
        guard let renderPipeline = renderPipeline else {fatalError()}
        guard let renderPassDescriptor = currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentTexture(texture, index: 0)
        var textureIndex = 1
        for additionalTex in additionalTextures {
            renderEncoder.setFragmentTexture(additionalTex, index: textureIndex)
            textureIndex += 1
        }
        var bufferIndex = 0
        for additionalBuf in additionalBuffers {
            renderEncoder.setFragmentBuffer(additionalBuf, offset: 0, index: bufferIndex)
            bufferIndex += 1
        }
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
    
    // =========================================================================
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {return}
        guard let transformedTexture = transformedTexture else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}

        makePipelineIfNeeded()
        if renderPipeline != nil {
            encodeShaders(commandBuffer: commandBuffer)
        } else {
            // just copy to drawable
            guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {fatalError()}
            blitEncoder.copy(from: transformedTexture,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                             sourceSize: MTLSizeMake(transformedTexture.width, transformedTexture.height, transformedTexture.depth),
                             to: drawable.texture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

extension MTLDevice {
    func makeTexture(pixelFormat: MTLPixelFormat, width: Int, height: Int) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: true)
        textureDescriptor.usage = .shaderWrite
        return makeTexture(descriptor: textureDescriptor)!
    }
}

extension UIViewContentMode {
    func scaleTransform(from inTexture: MTLTexture, to outTexture: MTLTexture) -> MPSScaleTransform {
        var scaleX: Double
        var scaleY: Double
        switch self {
        case .scaleToFill:
            scaleX = Double(outTexture.width)  / Double(inTexture.width)
            scaleY = Double(outTexture.height) / Double(inTexture.height)
        case .scaleAspectFill:
            scaleX = Double(outTexture.width)  / Double(inTexture.width)
            scaleY = Double(outTexture.height) / Double(inTexture.height)
            if scaleX > scaleY {
                scaleY = scaleX
            } else {
                scaleX = scaleY
            }
        case .scaleAspectFit:
            scaleX = Double(outTexture.width)  / Double(inTexture.width)
            scaleY = Double(outTexture.height) / Double(inTexture.height)
            if scaleX > scaleY {
                scaleX = scaleY
            } else {
                scaleY = scaleX
            }
        default:
            scaleX = 1
            scaleY = 1
        }
        
        let translateX: Double
        let translateY: Double
        switch self {
        case .center, .scaleAspectFill, .scaleToFill:
            translateX = (Double(outTexture.width)  - Double(inTexture.width)  * scaleX) / 2
            translateY = (Double(outTexture.height) - Double(inTexture.height) * scaleY) / 2
        case .scaleAspectFit:
            translateX = 0
            translateY = 0
        default:
            fatalError("I'm sorry, this contentMode is not supported for now. Welcome your pull request!")
        }

        return MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
    }
}
