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
    
    static private let veryLongTimeInterval: CFTimeInterval = (256.0 * 365.0 * 24.0 * 60.0 * 60.0)
    private var _nextFrame: CVPixelBuffer?
    private let videoReaderQueue = DispatchQueue(label: "com.hecticant.quack.videoReader", qos: .userInteractive)
    
    var lastTime: CMTime!
    let clock = CMClockGetHostTimeClock()
    var frameRateInSeconds: Float32 = 0

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
        
        lastTime = CMClockGetTime(clock)
        guard self.restartReading() else { return nil }
    }
    
    func restartReading() -> Bool {
        do {
            self.assetReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return false
        }
        
        self.videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        
        if self.assetReader.canAdd(videoAssetReaderOutput) {
            self.assetReader.add(videoAssetReaderOutput)
        } else {
            return false
        }
        
        if let timebase = controlTimebase() {
            videoLayer.controlTimebase = timebase
            startRequestingMediaData()
            return true
        }
        
        return false
    }
    
    private func controlTimebase() -> CMTimebase? {
        var timebase: CMTimebase?
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: clock, timebaseOut: &timebase)
        
        if let timebase = timebase {
            assetReader.timeRange = CMTimeRangeMake(start: CMTimebaseGetTime(timebase), duration: videoAsset.duration)
            if self.assetReader.startReading() {
                let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer()!
                var timingInfo = CMSampleTimingInfo()
                CMSampleBufferGetSampleTimingInfo(sampleBuffer, at: 0, timingInfoOut: &timingInfo)
                CMTimebaseSetTime(timebase, time:timingInfo.presentationTimeStamp);
                CMTimebaseSetRate(timebase, rate: 1.0);
            }
        }
        
        return timebase
    }
    
    private func startRequestingMediaData() {
        videoLayer.requestMediaDataWhenReady(on: videoReaderQueue) {
            guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
                self._nextFrame = nil
                return
            }
            self.videoLayer.enqueue(sampleBuffer)
            self._nextFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
        }
    }
    
    func nextFrame() -> CVPixelBuffer? {
        let currentTime = CMClockGetTime(clock)
        let difference = CMTimeSubtract(currentTime, lastTime)
        let seconds = CMTimeGetSeconds(difference)
        frameRateInSeconds = Float32(1.0 / seconds)
        lastTime = currentTime

        return _nextFrame
    }
    
    func outputSize() -> CGSize {
        return videoTrack.naturalSize
    }
}
