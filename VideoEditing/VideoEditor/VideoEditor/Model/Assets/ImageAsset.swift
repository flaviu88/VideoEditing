//
//  ImageAsset.swift
//  VideoEditing
//
//  Created by Roland Huhn on 13/01/17.
//  Copyright © 2017 3PillarGlobal. All rights reserved.
//

import Foundation

class ImageAsset: Asset {
    var imageUrl : URL
    var descriptionTags = [String]()
    
    init(imageUrl: URL) {
        self.imageUrl = imageUrl;
    }
    
}
