//
//  VideoBuilder.swift
//  VideoEditing
//
//  Created by Roland Huhn on 13/01/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation
import AVFoundation

class VideoBuilder{
    
    var handler: VideoBuilderInteface?
    
    func createVideo(fromAssets assets: [Asset], configuration: VideoBuilderConfiguration) -> String? {
        var avassetArray: [AVAsset] = []
        for asset in assets {
            if let avasset = handler?.applyEffect(asset: asset) {
                avassetArray.append(avasset)
            }
        }
        
        let videoURL = handler?.createVideo(assets: avassetArray)
        return videoURL
    }
}
