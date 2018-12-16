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

public class VideoLayerViewportConverter<T:CALayer>: VisionOutputConverter {
    
    private weak var view: OutputView<T>!
    private var cachedSize: CGSize
    private var outputProvider: VideoOutputProvider
    private var observation: NSKeyValueObservation?
    
    public init(view: OutputView<T>, outputProvider: VideoOutputProvider) {
        self.view = view
        self.outputProvider = outputProvider
        self.cachedSize = view.bounds.size
        
        observation = view.observe(\.bounds, options: [.new]) { object, change in
            if let size = change.newValue?.size {
                self.cachedSize = size
            }
        }
    }
    
    public func convertRect(from visionOutputRect: CGRect) -> CGRect {
        let size = cachedSize

        // Convert to viewport coordinates. Assumes the Vision request was not cropped.
        let transform = CGAffineTransform.identity
            .translatedBy(x: 0, y: size.height)
            .scaledBy(x: size.width, y: -size.height)
        
        let outputRect = visionOutputRect.applying(transform)
        return outputRect
    }
}
