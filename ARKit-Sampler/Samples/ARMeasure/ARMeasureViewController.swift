//
//  ARMeasureViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ARMeasureViewController: UIViewController, ARSCNViewDelegate {
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Private
    
    private func reset() {
        startNode?.removeFromParentNode()
        startNode = nil
        endNode?.removeFromParentNode()
        endNode = nil
        statusLabel.isHidden = true
    }
    
    private func putSphere(at pos: SCNVector3, color: UIColor) -> SCNNode {
        let node = SCNNode.sphereNode(color: color)
        sceneView.scene.rootNode.addChildNode(node)
        node.position = pos
        return node
    }
    
    private func drawLine(from: SCNNode, to: SCNNode, length: Float) -> SCNNode {
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: UIColor.red)
        from.addChildNode(lineNode)
        lineNode.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to.position)
        return lineNode
    }
    
    private func hitTest(_ pos: CGPoint) {
        let results = sceneView.hitTest(pos, types: [.existingPlane])
        guard let result = results.first else {return}
        let hitPos = result.worldTransform.position()
        
        if let startNode = startNode {
            endNode = putSphere(at: hitPos, color: UIColor.green)
            guard let endNode = endNode else {fatalError()}
            
            let distance = (endNode.position - startNode.position).length()
            print("distance: \(distance) [m]")
            
            lineNode = drawLine(from: startNode, to: endNode, length: distance)
            
            statusLabel.text = String(format: "Distance: %.2f [m]", distance)
        } else {
            startNode = putSphere(at: hitPos, color: UIColor.blue)
            statusLabel.text = "Tap an end point"
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        DispatchQueue.main.async(execute: {
            self.statusLabel.isHidden = !(frame.anchors.count > 0)
            if self.startNode == nil {
                self.statusLabel.text = "Tap a start point"
            }
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.addPlaneNode(on: node, contents: UIColor.arBlue.withAlphaComponent(0.1))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }

    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let pos = touch.location(in: sceneView)
        
        if let endNode = endNode {
            endNode.removeFromParentNode()
            lineNode?.removeFromParentNode()
        }
        
        hitTest(pos)
    }

    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
}
