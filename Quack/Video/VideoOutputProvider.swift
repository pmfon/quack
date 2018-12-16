//
//  VideoOutputProvider.swift
//  Quack
//
//  Created by Pedro Fonseca on 08/12/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import AVFoundation
import UIKit

struct VideoOutputProviderOptions {
    let asset: AVAsset?
}

public protocol VideoOutputProvider {
    func nextFrame() -> CVPixelBuffer?
    func outputSize() -> CGSize
    var frameRateInSeconds: Float32 { get }
}

func BuildVideoOutputProvider(view: UIView, options: VideoOutputProviderOptions) -> VideoOutputProvider? {
    switch view {
    case let outputView as VideoCaptureView:
        return VideoCapture(layer: outputView.videoLayer)
    case let outputView as VideoPlaybackView:
        return VideoReader(layer: outputView.videoLayer, videoAsset: options.asset!)
    default:
        break
    }
    
    return nil
}
