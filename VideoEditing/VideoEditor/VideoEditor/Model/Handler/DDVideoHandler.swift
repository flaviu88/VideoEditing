//
//  DDVideoHandler.swift
//  VideoEditing
//
//  Created by Flaviu Silaghi on 10/03/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation

struct RenderSettings {

    var width: CGFloat = 1280
    var height: CGFloat = 720
    var fps: Int32 = 3
    var avCodecKey = AVVideoCodecH264
    var videoFilename = "OutputVideo"
    var videoFilenameExt = "mp4"

    var size: CGSize {
        return CGSize(width: width, height: height)
    }

    var outputURL: NSURL {
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt) as NSURL
        }
        fatalError("URLForDirectory() failed")
    }
}

class DDVideoHandler : VideoBuilderInteface {
    
    var videoOutputURL : NSURL!
    let audioUrl : NSURL =  Bundle.main.url(forResource: "Happy-electronic-music", withExtension: "mp3")! as NSURL

    func applyEffect(asset: Asset) -> AVAsset? {
        return nil
    }
    
    func createVideo(assets: [AVAsset]) -> String? {
        let settings = RenderSettings()
                let imageAnimator = ImageAnimator(renderSettings: settings)
                imageAnimator.images = assets
                imageAnimator.render() {
                    print("yes")
        }

    }
    
}
