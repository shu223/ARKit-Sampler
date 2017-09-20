//
//  CVPixelBuffer+Metal.swift
//  VideoProcessing
//
//  Created by Shuichi Tsutsumi on 2016/12/21.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import CoreVideo

extension CVPixelBuffer {
    
    // https://github.com/navoshta/MetalRenderCamera
    func texture(textureCache: CVMetalTextureCache?, planeIndex: Int = 0, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture?
    {
        guard let textureCache = textureCache else {return nil}
        
        let isPlanar = CVPixelBufferIsPlanar(self)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(self, planeIndex) : CVPixelBufferGetWidth(self)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(self, planeIndex) : CVPixelBufferGetHeight(self)
        
        var imageTexture: CVMetalTexture?
        
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, self, nil, pixelFormat, width, height, planeIndex, &imageTexture)
        
        guard
            let unwrappedImageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
            result == kCVReturnSuccess
            else {
                return nil
        }
        
//        CVMetalTextureCacheFlush(textureCache, CVOptionFlags())
        
        return texture
    }
}
