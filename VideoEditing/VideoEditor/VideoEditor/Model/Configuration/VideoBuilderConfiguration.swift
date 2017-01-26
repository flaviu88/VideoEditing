//
//  VideoBuilderConfiguration.swift
//  VideoEditing
//
//  Created by Roland Huhn on 26/01/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit

class Resolution{
    var width: Int
    var height : Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

enum VideoSize{
    case HD
    case FullHD
    case UHD4K
    
    func values() -> (widht: Int, height: Int) {
        switch self {
        case .HD:
            return (1280, 720)
        case .FullHD:
            return (1920,1080)
        case .UHD4K:
            return (3840,2160)
        }
        
        
    }
}

class VideoBuilderConfiguration: NSObject {

    var defaultAssetDisplayTime: NSNumber = 3
    var defaultTransitionTime: NSNumber = 1
    var videoOutputSize : VideoSize = .FullHD
}
