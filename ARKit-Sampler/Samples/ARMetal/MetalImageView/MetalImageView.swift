//
//  MetalImageView.swift
//
//  Created by Shuichi Tsutsumi on 2016/12/11.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders

let vertexData: [Float] =
[
        -1, -1, 0, 1,
        1, -1, 0, 1,
        -1,  1, 0, 1,
        1,  1, 0, 1
]

let textureCoordinateData: [Float] =
[
    0, 1,
    1, 1,
    0, 0,
    1, 0
]

class MetalImageView: MTKView, MTKViewDelegate {

    private var commandQueue: MTLCommandQueue!

    private var textureLoader: MTKTextureLoader!
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
    

    // FIXME: temporary implementation
    private var vertexBuffer: MTLBuffer?
    private var texCoordBuffer: MTLBuffer?
    private var timeBuffer: MTLBuffer?
    private var renderPipeline: MTLRenderPipelineState?
    var secondTexture: MTLTexture?
    var time: Float? {
        didSet {
            if let time = time, let timeBuffer = timeBuffer {
                let pTimeData = timeBuffer.contents()
                let vTimeData = pTimeData.bindMemory(to: Float.self, capacity: 1 / MemoryLayout<Float>.stride)
                vTimeData[0] = time
            }
        }
    }

    func applyShaders(library: MTLLibrary, vertexFunctionName: String, fragmentFunctionName: String) {
        guard let device = device else {fatalError()}
        if vertexBuffer == nil {
            let size = vertexData.count * MemoryLayout<Float>.size
            vertexBuffer = device.makeBuffer(bytes: vertexData, length: size, options: [])
        }
        if texCoordBuffer == nil {
            let size = textureCoordinateData.count * MemoryLayout<Float>.size
            texCoordBuffer = device.makeBuffer(bytes: textureCoordinateData, length: size, options: [])
        }
        if timeBuffer == nil {
            timeBuffer = device.makeBuffer(bytes: &time, length: MemoryLayout<Float>.size, options: [])
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        descriptor.fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
        if let secondTexture = secondTexture {
            renderEncoder.setFragmentTexture(secondTexture, index: 1)
        }
        if time != nil {
            renderEncoder.setFragmentBuffer(timeBuffer, offset: 0, index: 0)
        }

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }


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
    
    // =========================================================================
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {return}
        guard let transformedTexture = transformedTexture else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}


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
