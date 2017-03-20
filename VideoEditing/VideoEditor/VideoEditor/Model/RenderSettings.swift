//
//  RenderSettings.swift
//  VideoEditing
//
//  Created by Dana Drimba on 10/03/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation
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
