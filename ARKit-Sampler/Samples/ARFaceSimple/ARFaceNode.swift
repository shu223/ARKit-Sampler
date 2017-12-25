//
//  ARFaceNode.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/12/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class ARFaceNode: SCNNode {

    init(device: MTLDevice, color: UIColor = .white) {
        let faceGeometry = ARSCNFaceGeometry(device: device)
        if let material = faceGeometry?.firstMaterial {
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
        }
        super.init()
        self.geometry = faceGeometry
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with faceAnchor: ARFaceAnchor) {
        guard let faceGeometry = geometry as? ARSCNFaceGeometry else {return}
        faceGeometry.update(from: faceAnchor.geometry)
    }
}
