//
//  CaptureSource.swift
//  Quack
//
//  Created by Pedro Fonseca on 08/12/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, VideoOutputProvider {
    
    private var _nextFrame: CVPixelBuffer?
    let captureSession: AVCaptureSession
    private let videoCaptureQueue = DispatchQueue(label: "com.hecticant.quack.videoCapture", qos: .userInteractive)
    
    var lastTime: CMTime!
    let clock = CMClockGetHostTimeClock()
    var frameRateInSeconds: Float32 = 0
    
    init(layer: AVCaptureVideoPreviewLayer) {
        captureSession = AVCaptureSession()
        super.init()
        
        if let output = configureAVSession(captureSession) {
            output.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        }
        layer.session = captureSession
        
        lastTime = CMClockGetTime(clock)
        captureSession.startRunning()
    }
    
    private func configureAVSession(_ captureSession: AVCaptureSession) -> AVCaptureVideoDataOutput? {
        
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
      
        guard configureAVInput(captureSession: captureSession) != nil else { return nil }
        guard let output = configureAVOutput(captureSession: captureSession) else { return nil }
        configureOutputOrientation(output)

        return output
    }
    
    private func configureAVInput(captureSession: AVCaptureSession) -> AVCaptureDeviceInput? {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: videoDevice), captureSession.canAddInput(input) else {
            return nil
        }
        captureSession.addInput(input)
        return input
    }
    
    private func configureAVOutput(captureSession: AVCaptureSession) -> AVCaptureVideoDataOutput? {
        let output = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(output) else { return nil }
        
        captureSession.sessionPreset = .hd1920x1080
        captureSession.addOutput(output)
        return output
    }
    
    private func configureOutputOrientation(_ output: AVCaptureOutput) {
        if let connection = output.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        _nextFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
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
        return CGSize(width: 1080, height: 1920)
    }
}
