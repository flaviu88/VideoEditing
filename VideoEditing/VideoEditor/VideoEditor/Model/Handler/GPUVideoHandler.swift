//
//  GPUVideoHandler.swift
//  VideoEditing
//
//  Created by Flaviu Silaghi on 10/03/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation
import GPUImage

class GPUVideoHandler : VideoBuilderInteface {

    func applyEffect(asset: Asset) -> Asset? {
        //just for testing GPUImage integration
        let image = UIImage.init()
        let motionBlurFilter = MotionBlur()
        let filteredImage = image.filterWithOperation(motionBlurFilter)
        return nil
    }
    
    func createVideo(assets: [Asset]) -> String? {
        return nil
    }
    
}
