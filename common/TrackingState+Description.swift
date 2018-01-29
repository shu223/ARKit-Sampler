//
//  TrackingState+Description.swift
//
//  Created by Shuichi Tsutsumi on 2017/08/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

extension ARCamera.TrackingState {
    public var description: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "TRACKING LIMITED\nToo much camera movement"
            case .insufficientFeatures:
                return "TRACKING LIMITED\nNot enough surface detail"
            case .initializing:
                return "TRACKING LIMITED\nInitialization in progress."
            case .relocalizing:
                return "TRACKING LIMITED\nRelocalization in progress."
            }
        }
    }
}
