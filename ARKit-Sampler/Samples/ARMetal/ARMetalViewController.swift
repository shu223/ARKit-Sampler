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
    
    private let device = MTLCreateSystemDefaultDevice()!
    private let commandQueue: MTLCommandQueue
    private let textureLoader: MTKTextureLoader

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var resetBtn: UIButton!

    @IBOutlet weak var metalView: MetalImageView!
    
    private var planeNode: SCNNode?

    required init?(coder aDecoder: NSCoder) {
        commandQueue = device.makeCommandQueue()!
        textureLoader = MTKTextureLoader(device: device)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        metalView.applyShaders(library: library, vertexFunctionName: "textureRendererVertex", fragmentFunctionName: "myFragment1")
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        label.text = "Wait..."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Private
    
    private func startRunning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
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
            guard let cgImage = context.createCGImage(image, from: image.extent) else {return}
            guard let textureCamera = try? self.textureLoader.newTexture(cgImage: cgImage) else {return}
            self.metalView.secondTexture = textureCamera

            self.metalView.time = Float(time)

            guard let snapshotImage = self.sceneView.snapshot().cgImage else {return}

            guard let textureSnapshot = try? self.textureLoader.newTexture(cgImage: snapshotImage) else {return}
            self.metalView.texture = textureSnapshot
            self.isRendering = false
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        
        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        geometry.materials.first?.diffuse.contents = UIColor.black

        DispatchQueue.main.async(execute: {
            if let planeNode = self.planeNode {
                planeNode.removeFromParentNode()
            }
            
            self.planeNode = SCNNode(geometry: geometry)
            guard let planeNode = self.planeNode else {fatalError()}
            
            // add the plane on the root node at the same position with the anchor node.
            self.sceneView.scene.rootNode.addChildNode(planeNode)
            planeNode.position = node.position
        })
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async(execute: {
            guard let planeNode = self.planeNode else {fatalError()}
            planeNode.position = node.position
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("\(self.classForCoder)/\(#function), error: " + error.localizedDescription)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        label.text = camera.trackingState.description
    }

    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
        startRunning()
    }
}
