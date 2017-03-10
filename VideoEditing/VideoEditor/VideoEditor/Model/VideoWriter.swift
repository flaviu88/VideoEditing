//
//  VideoWriter.swift
//  VideoEditing
//
//  Created by Dana Drimba on 20/02/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit


class VideoWriter {
    
    let renderSettings: RenderSettings
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var audioWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x:0, y:0, width:size.width, height:size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context?.draw(image.cgImage!, in: CGRect(x:x, y:y, width:newSize.width, height:newSize.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    
    func start() {
        
        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.height))
        ]
        
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size);
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        
        let audioSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
                             AVNumberOfChannelsKey: 2,
                             AVSampleRateKey: 44100,
                             AVEncoderBitRateKey: 128000,
                             AVChannelLayoutKey: NSData(bytes:&channelLayout, length:MemoryLayout<AudioChannelLayout>.size)]
                             as [String : Any]
        
        
        
        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL, avOutputSettings: avOutputSettings)
        
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: avOutputSettings)
        audioWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
        audioWriterInput.expectsMediaDataInRealTime = false
        
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("videoWriterInput canAdd returned false")
        }
        
        if videoWriter.canAdd(audioWriterInput) {
            videoWriter.add(audioWriterInput)
        }
        else {
            fatalError("audioWriterInput canAdd returned false")
        }

        
        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()
        
        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }
        
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }
    
    func render(appendPixelBuffers: @escaping (VideoWriter)->Bool, completion: @escaping ()->Void) {
        
        precondition(videoWriter != nil, "Call start() to initialze the writer")
        
        let queue = DispatchQueue(label: "mediaInputQueue", attributes: .concurrent, target: .main)
        let group = DispatchGroup()
        
        group.enter()
        queue.async (group: group) {
            self.audioWriterInput.requestMediaDataWhenReady(on: queue, using: { () -> Void in
                self.addAudio(audioWriterInput: self.audioWriterInput)
            })
            group.leave()
        }
        
        group.enter()
        queue.async (group: group) {
            self.videoWriterInput.requestMediaDataWhenReady(on: queue) {
                let isFinished = appendPixelBuffers(self)
                if isFinished {
                    self.videoWriterInput.markAsFinished()
                }
            }
             group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.videoWriter.finishWriting { }
        }
    }
    
    
    func createAssetWriter(outputURL: NSURL, avOutputSettings:[String: AnyObject]) -> AVAssetWriter
    {
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileTypeMPEG4) else {
            fatalError("AVAssetWriter() failed")
        }
        
        guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("canApplyOutputSettings() failed")
        }
        
        return assetWriter
    }
    
    
    func createPixelBufferAdaptor() {
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.height))
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                  sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
    }

    
    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    
    func addAudio(audioWriterInput:AVAssetWriterInput)
    {
        let audioUrl : NSURL =  Bundle.main.url(forResource: "Happy-electronic-music", withExtension: "mp3")! as NSURL
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
}
