//
//  VideoOutputView.swift
//  Quack
//
//  Created by Pedro Fonseca on 09/12/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import AVFoundation
import UIKit

public protocol VideoOutputView: class {
    associatedtype LayerType: CALayer
    var videoLayer: LayerType { get }
}

public class OutputView<T:CALayer>: UIView, VideoOutputView {
    public typealias LayerType = T
    
    override public class var layerClass: AnyClass {
        return LayerType.self
    }

    public var videoLayer: LayerType {
        return layer as! LayerType
    }
}

class VideoCaptureView: OutputView<AVCaptureVideoPreviewLayer> {}

class VideoPlaybackView: OutputView<AVSampleBufferDisplayLayer> {}
