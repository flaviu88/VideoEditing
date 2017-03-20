//
//  VideoBuilderConfiguration.swift
//  VideoEditing
//
//  Created by Roland Huhn on 26/01/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit

struct Resolution{
    var width: Int
    var height : Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

enum VideoSize {
    case HD
    case FullHD
    case UHD4K
    
    func size() -> Resolution {
        switch self {
        case .HD:
            return Resolution(width: 1280, height: 720)
        case .FullHD:
            return Resolution(width: 1920,height: 1080)
        case .UHD4K:
            return Resolution(width: 3840,height: 2160)
        }
    }
}

class VideoBuilderConfiguration {

    var defaultAssetDisplayTime: Float = 3
    var defaultTransitionTime: Float = 1
    var videoOutputSize : VideoSize = .FullHD
}
