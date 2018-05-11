//
//  ARFaceSimpleViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/12/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class ARFaceSimpleViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    
    private var faceNode: ARFaceNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARFaceTrackingConfiguration.isSupported, let device = sceneView.device else {
            print("ARFaceTrackingConfiguration is not supported on this device!")
            navigationController?.popViewController(animated: true)
            return;
        }
        faceNode = ARFaceNode(device: device)
        
        sceneView.session.run(ARFaceTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
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
        guard let currentFrame = sceneView.session.currentFrame else { return }
        for anchor in currentFrame.anchors {
            // update time for ARFaceNode object
            guard let faceAnchor = anchor as? ARFaceAnchor else { continue }
            guard let node = sceneView.node(for: faceAnchor) else { continue }
            guard let faceNode = node.findFaceNode() else { continue }
            guard let material = faceNode.geometry?.firstMaterial else { return }
            self.updateTime(time, for: material)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let faceAnchor = anchor as? ARFaceAnchor else {fatalError()}

        faceNode.removeFromParentNode()
        node.addChildNode(faceNode)
        
        faceNode.update(with: faceAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {fatalError()}
        
        faceNode.update(with: faceAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        
        faceNode.removeFromParentNode()
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
}
