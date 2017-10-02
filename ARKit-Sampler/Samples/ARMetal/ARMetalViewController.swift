//
//  ARMetalViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit
import Metal
import MetalKit

class ARMetalViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var resetBtn: UIButton!

    @IBOutlet weak var metalView: ARMetalImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        label.text = "Wait..."
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
    }

    // MARK: - ARSCNViewDelegate
    
    var isRendering = false
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        let pixelBuffer = frame.capturedImage

        if isRendering {
            return
        }
        isRendering = true
        
        DispatchQueue.main.async(execute: {
            let orientation = UIApplication.shared.statusBarOrientation
            let viewportSize = self.sceneView.bounds.size
            
            var image = CIImage(cvPixelBuffer: pixelBuffer)
            
            let transform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
            image = image.transformed(by: transform)
            
            let context = CIContext(options:nil)
            guard let cameraImage = context.createCGImage(image, from: image.extent) else {return}
            guard let snapshotImage = self.sceneView.snapshot().cgImage else {return}
            self.metalView.registerTexturesFor(cameraImage: cameraImage, snapshotImage: snapshotImage)
            self.metalView.time = Float(time)

            self.isRendering = false
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
//        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        
        let virtualNode = VirtualObjectNode()

        for child in virtualNode.childNodes {
            if let material = child.geometry?.firstMaterial {
                material.diffuse.contents = UIColor.black
            }
        }
        virtualNode.scale = SCNVector3Make(2, 2, 2)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(virtualNode)
        })
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        label.text = camera.trackingState.description
    }

    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
        sceneView.session.run()
    }
}
