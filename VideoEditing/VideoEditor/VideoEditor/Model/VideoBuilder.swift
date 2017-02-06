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
    
    var videoOutputURL : NSURL!
    let audioUrl : NSURL =  Bundle.main.url(forResource: "Happy-electronic-music", withExtension: "mp3")! as NSURL
    
    
    func createVideo(fromAssets assets: [Asset], configuration: VideoBuilderConfiguration){
        buildVideo(outputSize: configuration.videoOutputSize.size(), assets: assets)
    }
    
    func buildVideo(outputSize: Resolution, assets:[Asset])
    {
        videoOutputURL = createVideoPath(pathName: "OutputVideo.mp4")
        
        guard let audioVideoWriter = try? AVAssetWriter(outputURL: videoOutputURL! as URL, fileType: AVFileTypeMPEG4) else {
            fatalError("AVAssetWriter error")
        }
        
        let videoWriterInput = configureVideoInput(outputSize: outputSize)
        let audioWriterInput = configureAudioInput()
        
        if audioVideoWriter.canAdd(videoWriterInput) {
            audioVideoWriter.add(videoWriterInput)
        }
        
        if audioVideoWriter.canAdd(audioWriterInput) {
            audioVideoWriter.add(audioWriterInput)
        }
        
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if audioVideoWriter.startWriting() {
            
            audioVideoWriter.startSession(atSourceTime: kCMTimeZero)
            
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let media_queue = DispatchQueue(label: "mediaInputQueue", attributes: .concurrent, target: .main)
            let group = DispatchGroup()
            
            group.enter()
            media_queue.async (group: group) {
                audioWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                    self.addAudio(audioWriterInput: audioWriterInput)
                })
                group.leave()
            }
            
            group.enter()
            media_queue.async (group: group) {
                videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                    self.addPixelBufferVideo(videoWriterInput: videoWriterInput, pixelBufferAdaptor:pixelBufferAdaptor, outputSize: outputSize, fromAssets: assets)
                })
                group.leave()
            }
            group.notify(queue: DispatchQueue.main) {
                audioVideoWriter.finishWriting { }
            }

            
        }
    }
    
    func configureVideoInput(outputSize: Resolution) -> AVAssetWriterInput
    {
        let outputSettings = [AVVideoCodecKey : AVVideoCodecH264,
                              AVVideoWidthKey : NSNumber(value: Float(outputSize.width)),
                              AVVideoHeightKey : NSNumber(value: Float(outputSize.height))]
            as [String : Any]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        videoWriterInput.expectsMediaDataInRealTime = true
        
        return videoWriterInput
    }
    
    func configureAudioInput() -> AVAssetWriterInput
    {
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size);
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        let audioSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
                             AVNumberOfChannelsKey: 2,
                             AVSampleRateKey: 44100,
                             AVEncoderBitRateKey: 128000,
                             AVChannelLayoutKey: NSData(bytes:&channelLayout, length:MemoryLayout<AudioChannelLayout>.size)]
            as [String : Any]
        
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
        audioWriterInput.expectsMediaDataInRealTime = false
        
        return audioWriterInput
    }
    
    
    func addAudio(audioWriterInput:AVAssetWriterInput)
    {
        let audioAsset = AVURLAsset(url: audioUrl as URL)
        guard let audioReader = try? AVAssetReader(asset: audioAsset) else {
            fatalError("AVAssetReader error")
        }
        let audioTrack:AVAssetTrack = audioAsset.tracks.first!
        
        let decompressionAudioSettings:[String : AnyObject] = [
            AVFormatIDKey:Int(kAudioFormatLinearPCM) as AnyObject
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: decompressionAudioSettings)
        
        if audioReader.canAdd(readerOutput) {
            audioReader.add(readerOutput)
        }
        audioReader.startReading()
        
        while (audioWriterInput.isReadyForMoreMediaData) {
            
            let sampleBuffer2 = readerOutput.copyNextSampleBuffer()
            if audioReader.status == .reading && sampleBuffer2 != nil {
                audioWriterInput.append(sampleBuffer2!)
            }else {
                audioWriterInput.markAsFinished()
            }
        }
    }
    
    func addPixelBufferVideo(videoWriterInput: AVAssetWriterInput, pixelBufferAdaptor:AVAssetWriterInputPixelBufferAdaptor, outputSize:Resolution, fromAssets:inout [Asset])
    {
        let fps: Int32 = 1
        let frameDuration = CMTimeMake(1, fps)
        
        var frameCount: Int64 = 0
        var appendSucceeded = true
        
        while (!fromAssets.isEmpty) {
            if (videoWriterInput.isReadyForMoreMediaData) {
                let nextPhoto = fromAssets.remove(at: 0)
                let lastFrameTime = CMTimeMake(frameCount, fps)
                let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                
                var pixelBuffer: CVPixelBuffer? = nil
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                
                if let pixelBuffer = pixelBuffer, status == 0 {
                    let managedPixelBuffer = pixelBuffer
                    
                    CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    
                    let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                    let context = CGContext(data: data, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                    
                    context!.clear(CGRect(x: 0, y: 0, width: CGFloat(outputSize.width), height: CGFloat(outputSize.height)))
                    
                    let horizontalRatio = CGFloat(outputSize.width) / nextPhoto.size.width
                    let verticalRatio = CGFloat(outputSize.height) / nextPhoto.size.height
                    let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                    
                    let newSize:Resolution = Resolution(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                    
                    let x = newSize.width < outputSize.width ? (outputSize.width - newSize.width) / 2 : 0
                    let y = newSize.height < outputSize.height ? (outputSize.height - newSize.height) / 2 : 0
                    
                    context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                    
                    CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    
                    appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                } else {
                    print("Failed to allocate pixel buffer")
                    appendSucceeded = false
                }
            }
            if !appendSucceeded {
                break
            }
            frameCount += 1
        }
        
        videoWriterInput.markAsFinished()
    }
    
    func createVideoPath(pathName:String) -> NSURL!
    {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory: NSURL = urls.first as NSURL? else {
            fatalError("documentDir Error")
        }
        let savePathUrl = documentDirectory.appendingPathComponent(pathName) as NSURL!
        
        if FileManager.default.fileExists(atPath: savePathUrl!.path!) {
            do {
                try FileManager.default.removeItem(atPath: savePathUrl!.path!)
            } catch {
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
        return savePathUrl!
    }
    
}
