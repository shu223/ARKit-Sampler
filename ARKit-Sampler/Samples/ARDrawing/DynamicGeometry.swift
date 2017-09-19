//
//  DynamicGeometry.swift
//
//  Created by Shuichi Tsutsumi on 2016/12/01.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import SceneKit

open class DynamicGeometryNode: SCNNode {
    
    private var vertices: [SCNVector3] = []
    private var indices: [Int32] = []
    private let lineWidth: Float
    private let color: UIColor
    private var verticesPool: [SCNVector3] = []

    public init(color: UIColor, lineWidth: Float) {
        self.color = color
        self.lineWidth = lineWidth
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addVertice(_ vertice: SCNVector3) {
        var smoothed = SCNVector3Zero
        if verticesPool.count < 3 {
            if !SCNVector3EqualToVector3(vertice, SCNVector3Zero) {
                verticesPool.append(vertice)
            }
            return
        } else {
            for vertice in verticesPool {
                smoothed += vertice
            }
            smoothed /= Float(verticesPool.count)
            verticesPool.removeAll()
        }
        vertices.append(SCNVector3Make(smoothed.x, smoothed.y - lineWidth, smoothed.z))
        vertices.append(SCNVector3Make(smoothed.x, smoothed.y + lineWidth, smoothed.z))
        let count = vertices.count
        indices.append(Int32(count-2))
        indices.append(Int32(count-1))
        
        updateGeometryIfNeeded()
    }
    
    private func updateGeometryIfNeeded() {
        guard vertices.count >= 3 else {
            print("not enough vertices")
            return
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangleStrip)
        geometry = SCNGeometry(sources: [source], elements: [element])
        if let material = geometry?.firstMaterial {
            material.diffuse.contents = color
            material.isDoubleSided = true
        }
    }
    
    public func reset() {
        verticesPool.removeAll()
        vertices.removeAll()
        indices.removeAll()
        geometry = nil
    }
}

