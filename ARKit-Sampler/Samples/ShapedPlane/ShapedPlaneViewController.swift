//
//  ShapedPlaneViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/04/07.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class ShapedPlaneViewController: UIViewController, ARSCNViewDelegate {

    private var planeGeometry: ARSCNPlaneGeometry!

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()!
        planeGeometry = ARSCNPlaneGeometry(device: device)!
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, SCNDebugOptions.showWireframe]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function + ", anchor id: \(anchor.identifier)")
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeGeometry.update(from: planeAnchor.geometry)
        planeAnchor.addPlaneNode(on: node, geometry: planeGeometry, contents: UIColor.green.withAlphaComponent(0.3))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeGeometry.update(from: planeAnchor.geometry)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
}
