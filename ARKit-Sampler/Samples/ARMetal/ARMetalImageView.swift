//
//  ARMetalImageView.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Metal

class ARMetalImageView: MetalImageView {

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        guard let device = device else {fatalError()}
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        registerShaders(library: library, vertexFunctionName: "vertexShader", fragmentFunctionName: "fragmentShader")
    }
    
    private var timeBuffer: MTLBuffer?
    var time: Float? {
        didSet {
            if time != nil {
                timeBuffer = makeBuffer(bytes: &time, length: MemoryLayout<Float>.size)
            } else {
                timeBuffer = nil
            }
            if let timeBuffer = timeBuffer {
                additionalBuffers = [timeBuffer]
            } else {
                additionalBuffers = []
            }
        }
    }
    
    internal func registerTexturesFor(cameraImage: CGImage, snapshotImage: CGImage) {
        guard let textureCamera = try? self.textureLoader.newTexture(cgImage: cameraImage) else {return}
        additionalTextures = [textureCamera]
        guard let textureSnapshot = try? self.textureLoader.newTexture(cgImage: snapshotImage) else {return}
        texture = textureSnapshot
    }
}
