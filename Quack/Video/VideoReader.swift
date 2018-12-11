/*
 This is based on Apple VideoReader sample:
 
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import AVFoundation
import Darwin

class VideoReader: VideoOutputProvider {
    static private let millisecondsInSecond: Float32 = 1000.0
    
    var frameRateInMilliseconds: Float32 {
        return self.videoTrack.nominalFrameRate
    }
    
    var frameRateInSeconds: Float32 {
        return self.frameRateInMilliseconds * VideoReader.millisecondsInSecond
    }
    
    var affineTransform: CGAffineTransform {
        return self.videoTrack.preferredTransform.inverted()
    }
    

    private var videoAsset: AVAsset!
    private var videoTrack: AVAssetTrack!
    private var assetReader: AVAssetReader!
    private var videoAssetReaderOutput: AVAssetReaderTrackOutput!
    private weak var videoLayer: AVSampleBufferDisplayLayer!
    
    init?(layer: AVSampleBufferDisplayLayer, videoAsset: AVAsset) {
        self.videoAsset = videoAsset
        let array = self.videoAsset.tracks(withMediaType: AVMediaType.video)
        self.videoTrack = array[0]
        self.videoLayer = layer
        
        guard self.restartReading() else {
            return nil
        }
    }
    
    func restartReading() -> Bool {
        do {
            self.assetReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return false
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        guard self.videoAssetReaderOutput != nil else {
            return false
        }
        
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        
        guard self.assetReader.canAdd(videoAssetReaderOutput) else {
            return false
        }
        
        self.assetReader.add(videoAssetReaderOutput)
        
        return self.assetReader.startReading()
    }
    
    func nextFrame() -> CVPixelBuffer? {
        guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        
        if self.videoLayer.isReadyForMoreMediaData {
            self.videoLayer.enqueue(sampleBuffer)
        }
        
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    func outputSize() -> CGSize {
        return videoTrack.naturalSize
    }
    
    func preferredTransform() -> CGAffineTransform {
        return videoTrack.preferredTransform.inverted()
    }
}
