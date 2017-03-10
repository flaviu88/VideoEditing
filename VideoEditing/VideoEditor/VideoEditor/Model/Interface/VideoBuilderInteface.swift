//
//  VideoBuilderInteface.swift
//  VideoEditing
//
//  Created by Flaviu Silaghi on 10/03/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoBuilderInteface {

    func applyEffect(asset: Asset) -> AVAsset?
    func createVideo(assets: [AVAsset]) -> String?
    
}
