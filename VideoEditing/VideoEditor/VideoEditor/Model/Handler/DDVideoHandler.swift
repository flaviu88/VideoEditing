//
//  DDVideoHandler.swift
//  VideoEditing
//
//  Created by Flaviu Silaghi on 10/03/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation


class DDVideoHandler : VideoBuilderInteface {
    
    func applyEffect(asset: Asset) -> AVAsset? {
        return nil
    }
    
    func createVideo(assets: [AVAsset]) -> String? {
        let settings = RenderSettings()
                let imageAnimator = ImageAnimator(renderSettings: settings)
                imageAnimator.images = assets
                return imageAnimator.render()
    }
}
