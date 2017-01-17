//
//  ViewController.swift
//  VideoEditing
//
//  Created by Flaviu Silaghi on 25/11/16.
//  Copyright © 2016 3PillarGlobal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var assets = [Asset]()
        
        for index in 1..<11 {
            assets.append(ImageAsset.init(imageUrl: URL.init(string: Bundle.main.path(forResource: "frame\(index)", ofType: "JPG")!)!))
        }
        
        
        let videoBuilder = VideoBuilder()
        videoBuilder.createVideo(fromAssets: assets)
    }
}

