//
//  ARInteractionViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ARInteractionViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        sceneView.updateLightingEnvironment(for: frame)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.addPlaneNode(on: node, contents: UIColor.arBlue.withAlphaComponent(0.3))
        
        let virtualNode = VirtualObjectNode()
        DispatchQueue.main.async(execute: {
            node.addChildNode(virtualNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }

    private func planeHitTest(_ pos: CGPoint) {
        let results = sceneView.hitTest(pos, types: .existingPlaneUsingExtent)

        // closest hit anchor
        guard let anchor = results.first?.anchor else {return}
        
        // corresponding node
        guard let node = sceneView.node(for: anchor) else {return}
        
        // Search a child node which has a plane geometry
        for child in node.childNodes {
            guard let plane = child.geometry as? SCNPlane else {continue}
            
            // react
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.completionBlock = {
                SCNTransaction.animationDuration = 0.4
                plane.firstMaterial?.diffuse.contents = UIColor.arBlue.withAlphaComponent(0.3)
            }
            plane.firstMaterial?.diffuse.contents = UIColor.arBlue
            SCNTransaction.commit()
            
            break
        }
    }
    
    private func virtualNodeHitTest(_ pos: CGPoint) -> Bool {
        guard let anchors = sceneView.session.currentFrame?.anchors else {return false}

        let hitTestOptions = [SCNHitTestOption: Any]()
        let results: [SCNHitTestResult] = sceneView.hitTest(pos, options: hitTestOptions)

        for anchor in anchors {
            // a node corresponding to the anchor
            guard let node = sceneView.node(for: anchor) else {continue}
            
            // Search a virtual object node which has a hit node
            guard let hitVirtualNode = searchHitVirtualObjectNode(under: node, results: results) else {continue}
            hitVirtualNode.react()
            
            return true
        }
        return false
    }
    
    private func searchHitVirtualObjectNode(under node: SCNNode, results: [SCNHitTestResult]) -> VirtualObjectNode? {
        for child in node.childNodes {
            guard let virtualNode = child as? VirtualObjectNode else {continue}
            for result in results {
                for virtualChild in virtualNode.childNodes {
                    guard virtualChild == result.node else {continue}
                    return virtualNode
                }
            }
        }
        return nil
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

        let isHit = virtualNodeHitTest(pos)

        if !isHit {
            planeHitTest(pos)
        }
    }
}

