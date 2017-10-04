//
//  ARObjectDetectionViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//
//  Thanks: https://github.com/hanleyweng/CoreML-in-ARKit

import UIKit
import ARKit
import CoreML
import Vision

class ARObjectDetectionViewController: UIViewController, ARSCNViewDelegate {

    private var model: VNCoreMLModel!
    private var screenCenter: CGPoint?

    private let serialQueue = DispatchQueue(label: "com.shu223.arkit.objectdetection")
    private var isPerformingCoreML = false

    private var latestResult: VNClassificationObservation?
    private var tags: [TagNode] = []
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var mlStateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = try! VNCoreMLModel(for: Inceptionv3().model)
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run()
        
        mlStateLabel.text = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
    }
    
    // MARK: - Private
    
    private func coreMLRequest() -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            guard let best = request.results?.first as? VNClassificationObservation  else {
                self.isPerformingCoreML = false
                return
            }
//            print("best: ")
            DispatchQueue.main.async(execute: {
                self.mlStateLabel.text = "\(best.identifier) \(best.confidence * 100)"
            })

            // don't tag when the result is enough confident
            if best.confidence < 0.3 {
                self.isPerformingCoreML = false
                return
            }

            if self.isFirstOrBestResult(result: best) {
                self.latestResult = best
                self.hitTest()
            }
            
            self.isPerformingCoreML = false
        })
        request.preferBackgroundProcessing = true

        request.imageCropAndScaleOption = .centerCrop
        
        return request
    }
    
    private func performCoreML() {

        serialQueue.async {
            guard !self.isPerformingCoreML else {return}
            guard let imageBuffer = self.sceneView.session.currentFrame?.capturedImage else {return}
            self.isPerformingCoreML = true
            
            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
            let request = self.coreMLRequest()
            do {
                try handler.perform([request])
            } catch {
                print(error)
                self.isPerformingCoreML = false
            }
        }
    }
    
    private func isFirstOrBestResult(result: VNClassificationObservation) -> Bool {
        for tag in tags {
            guard let prevRes = tag.classificationObservation else {continue}
            if prevRes.identifier == result.identifier {
                // when the result is more confident, remove the older one
                if prevRes.confidence < result.confidence {
                    if let index = tags.index(of: tag) {
                        tags.remove(at: index)
                    }
                    tag.removeFromParentNode()
                    return true
                }
                // older one is better
                return false
            }
        }
        // first result
        return true
    }
    
    private func hitTest() {
        guard let frame = sceneView.session.currentFrame else {return}
        let state = frame.camera.trackingState
        switch state {
        case .normal:
            guard let pos = screenCenter else {return}
            DispatchQueue.main.async(execute: {
                self.hitTest(pos)
            })
        default:
            break
        }
    }
    
    private func hitTest(_ pos: CGPoint) {
        let nodeResults = sceneView.hitTest(pos, options: [SCNHitTestOption.boundingBoxOnly: true])
        for nodeResult in nodeResults {
            if let overlappingTag = nodeResult.node.parent as? TagNode {
                // The tags seem overlapping, so let's replace with new one
                removeTag(tag: overlappingTag)
            }
        }
        
        let results1 = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        if let result = results1.first {
            addTag(for: result)
            return
        }
        
        let results2 = sceneView.hitTest(pos, types: .featurePoint)
        if let result = results2.first {
            addTag(for: result)
        }
    }

    private func addTag(for hitTestResult: ARHitTestResult) {
        let tagNode = TagNode()
        tagNode.transform = SCNMatrix4(hitTestResult.worldTransform)
        tags.append(tagNode)
        tagNode.classificationObservation = latestResult
        sceneView.scene.rootNode.addChildNode(tagNode)
    }

    private func removeTag(tag: TagNode) {
        tag.removeFromParentNode()
        guard let index = tags.index(of: tag) else {return}
        tags.remove(at: index)
    }
    
    private func reset() {
        for child in sceneView.scene.rootNode.childNodes {
            if child is TagNode {
                guard let tag = child as? TagNode else {fatalError()}
                removeTag(tag: tag)
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        performCoreML()
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    // MARK: - Actions
    
    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
}

