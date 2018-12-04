//
//  VisionOutputConverter.swift
//  Quack
//
//  Created by Pedro Fonseca on 22/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import ARKit

public protocol VisionOutputConverter {
    func convertRect(from visionOutputRect: CGRect) -> CGRect
}

public class AugmentedSceneViewportConverter: VisionOutputConverter {
    
    private weak var view: ARSKView!
    private var cachedSize: CGSize
    private var observation: NSKeyValueObservation?
    
    public init(view: ARSKView) {
        self.view = view
        cachedSize = view.bounds.size
        
        observation = view.observe(\.bounds, options: [.new]) { object, change in
            if let size = change.newValue?.size {
                self.cachedSize = size
            }
        }
    }
    
    public func convertRect(from visionOutputRect: CGRect) -> CGRect {
        let size = cachedSize
        
        let transform = CGAffineTransform.identity
            .translatedBy(x: 0, y: size.width)
            .scaledBy(x: size.width, y: -size.width)
        
        let centerCrop = visionOutputRect.applying(transform).offsetBy(dx: 0, dy: (size.height - size.width) * 0.5)
        return centerCrop
    }
}
