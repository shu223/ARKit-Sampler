//
//  ARPlaneAnchor+Visualize.swift
//
//  Created by Shuichi Tsutsumi on 2017/08/29.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import ARKit

extension ARPlaneAnchor {
    
    func addPlaneNode(on node: SCNNode, color: UIColor) {
        
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        geometry.materials.first?.diffuse.contents = color

        let planeNode = SCNNode(geometry: geometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
    }
    
    func updatePlaneNode(on node: SCNNode) {
        
        DispatchQueue.main.async(execute: {
            for childNode in node.childNodes {
                guard let plane = childNode.geometry as? SCNPlane else {continue}
                guard !PlaneSizeEqualToExtent(plane: plane, extent: self.extent) else {continue}

//                print("current plane size: (\(plane.width), \(plane.height))")
                plane.width = CGFloat(self.extent.x)
                plane.height = CGFloat(self.extent.z)
//                print("updated plane size: (\(plane.width), \(plane.height))")
                
                break
            }
        })
    }
}

fileprivate func PlaneSizeEqualToExtent(plane: SCNPlane, extent: vector_float3) -> Bool {
    if plane.width != CGFloat(extent.x) || plane.height != CGFloat(extent.z) {
        return false
    } else {
        return true
    }
}
