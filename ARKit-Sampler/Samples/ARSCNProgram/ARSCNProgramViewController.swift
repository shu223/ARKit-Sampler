//
//  ARSCNProgramViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/01/30.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class ARSCNProgramViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    private func updateTime(_ time: TimeInterval, for material: SCNMaterial) {
        var floatTime = Float(time)
        let timeData = Data(bytes: &floatTime, count: MemoryLayout<Float>.size)
        material.setValue(timeData, forKey: "time")
    }
    
    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let currentFrame = sceneView.session.currentFrame else {return}
        for anchor in currentFrame.anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else {continue}
            guard let node = sceneView.node(for: planeAnchor) else {continue}

            DispatchQueue.main.async(execute: {
                let planeNode = planeAnchor.findPlaneNode(on: node)
                guard let material = planeNode?.geometry?.firstMaterial else {return}
                self.updateTime(time, for: material)
            })
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        
        // Shaders for the material
        let program = SCNProgram()
        program.vertexFunctionName = "scnVertexShader"
        program.fragmentFunctionName = "scnFragmentShader"

        planeAnchor.addPlaneNode(on: node, contents: program)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
}

