//
//  ImageAnimator.swift
//  VideoEditing
//
//  Created by Dana Drimba on 20/02/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Photos


class ImageAnimator {
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images: [AVAsset]!
    
    var frameNum = 0
    
    func saveToLibrary(videoURL: NSURL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL as URL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:")
                }
            }
        }
    }
    
    func removeFileAtURL(fileURL: NSURL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path!)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }
    
    init(renderSettings: RenderSettings) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
    }
    
    func render() -> String {
        
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        self.removeFileAtURL(fileURL: settings.outputURL)
        
        guard settings.outputURL.absoluteString != nil else {
            return ""
        }
        
        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            self.saveToLibrary(videoURL: self.settings.outputURL)
        }
        
        print("\nVideo path \(settings.outputURL.absoluteString!)\n")
        return settings.outputURL.absoluteString!
    }

    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: VideoWriter) -> Bool {
        
        let frameDuration = CMTimeMake(Int64(ImageAnimator.kTimescale / settings.fps), ImageAnimator.kTimescale)
        
        while !images.isEmpty {
            
            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }
            
            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, Int32(frameNum))
            if let photoAsset = image as? ImageAsset {
                
                if let nextPhoto = UIImage(contentsOfFile: photoAsset.imageUrl.absoluteString) {
                    let success = videoWriter.addImage(image: nextPhoto, withPresentationTime: presentationTime)
                    if success == false {
                        fatalError("addImage() failed")
                    }
                    
                    frameNum += 1
                }
            }
        }
        
        // Inform writer all buffers have been written.
        return true
    }
    
}
