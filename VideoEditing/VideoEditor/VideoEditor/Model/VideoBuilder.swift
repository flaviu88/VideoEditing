//
//  VideoBuilder.swift
//  VideoEditing
//
//  Created by Roland Huhn on 13/01/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

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

class VideoBuilder{
    
    var videoOutputURL : NSURL!
    let audioUrl : NSURL =  Bundle.main.url(forResource: "Happy-electronic-music", withExtension: "mp3")! as NSURL
    
    func createVideo(fromAssets assets: [Asset], configuration: VideoBuilderConfiguration){
        
        let settings = RenderSettings()
        let imageAnimator = ImageAnimator(renderSettings: settings)
        imageAnimator.images = assets 
        imageAnimator.render() {
            print("yes")
        }
    }
}
