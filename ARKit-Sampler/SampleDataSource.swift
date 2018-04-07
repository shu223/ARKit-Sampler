//
//  SampleDataSource.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit

struct Sample {
    let title: String
    let detail: String
    let classPrefix: String
    
    func controller() -> UIViewController {
        let storyboard = UIStoryboard(name: classPrefix, bundle: nil)
        guard let controller = storyboard.instantiateInitialViewController() else {fatalError()}
        controller.title = title
        return controller
    }
}

struct SampleDataSource {
    let samples = [
        Sample(
            title: "3 lines AR",
            detail: "A simple AR with 3 lines code.",
            classPrefix: "Simple"
        ),
        Sample(
            title: "Plane Detection",
            detail: "A sample to show how simply ARKit can detect planes",
            classPrefix: "PlaneDetection"
        ),
        Sample(
            title: "Virtual Object",
            detail: "A sample to show how to add a virtual object to a detected plane.",
            classPrefix: "VirtualObject"
        ),
        Sample(
            title: "AR Interaction",
            detail: "Interact with virtual objects or detected plane anchors.",
            classPrefix: "ARInteraction"
        ),
        Sample(
            title: "AR Measure",
            detail: "Measure a length between 2 points in the real space.",
            classPrefix: "ARMeasure"
        ),
        Sample(
            title: "AR Drawing",
            detail: "Drawing in the real space.",
            classPrefix: "ARDrawing"
        ),
        Sample(
            title: "Core ML + ARKit",
            detail: "AR Tagging to detected objects using Core ML.",
            classPrefix: "ARObjectDetection"
        ),
        Sample(
            title: "Metal + ARKit",
            detail: "Rendering with Metal",
            classPrefix: "ARMetal"
        ),
        Sample(
            title: "Metal + ARKit (SCNProgram)",
            detail: "Rendering the virtual node's material with Metal shader using SCNProgram.",
            classPrefix: "ARSCNProgram"
        ),
        Sample(
            title: "Simple Face Tracking",
            detail: "Simplest Face-Based AR implementation.",
            classPrefix: "ARFaceSimple"
        ),
        Sample(
            title: "Vertical Plane Detection",
            detail: "A sample to show how to detect vertical planes with ARKit 1.5",
            classPrefix: "VerticalPlanes"
        ),
        Sample(
            title: "Irregularly-Shaped Plane Detection",
            detail: "A sample to show how to detect irregularly shaped surfaces with ARKit 1.5",
            classPrefix: "ShapedPlane"
        ),
        ]
}
