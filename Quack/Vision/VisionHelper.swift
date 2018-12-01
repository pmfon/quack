//
//  VisionHelper.swift
//  Quack
//
//  Created by Pedro Fonseca on 17/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit

protocol VisionHelper {
    var imageOrientation: CGImagePropertyOrientation { get }
    static func intersectionOverUnion(_ r1: CGRect, _ r2: CGRect, converter: VisionOutputConverter?) -> Float
}

extension VisionHelper {

    var imageOrientation: CGImagePropertyOrientation {
        return .up
    }
    
    static func intersectionOverUnion(_ r1: CGRect, _ r2: CGRect, converter: VisionOutputConverter?) -> Float {
        let rect1 = converter?.convertRect(from: r1) ?? r1
        let rect2 = converter?.convertRect(from: r2) ?? r2
        
        let intersection = rect1.intersection(rect2)
        guard !intersection.isNull else {
            return 0.0
        }
        
        let union = rect1.union(rect2)
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
}
