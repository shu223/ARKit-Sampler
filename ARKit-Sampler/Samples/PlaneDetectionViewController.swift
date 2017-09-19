//
//  PlaneDetectionViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class PlaneDetectionViewController: UIViewController, ARSCNViewDelegate {

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
        configuration.isLightEstimationEnabled = true

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }
    
    private func loadModel() -> SCNNode {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        let modelNode = SCNNode()
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child)
        }
        return modelNode
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.addPlaneNode(on: node, color: UIColor.bookYellow)

        let virtualObjectNode = loadModel()
        DispatchQueue.main.async(execute: {
            node.addChildNode(virtualObjectNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
}

