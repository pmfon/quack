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
    
    init(layer: AVCaptureVideoPreviewLayer) {
        captureSession = AVCaptureSession()
        super.init()
        
        if let output = configureAVSession(captureSession) {
            output.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        }
        layer.session = captureSession
    }
    
    private func configureAVSession(_ captureSession: AVCaptureSession) -> AVCaptureVideoDataOutput? {
        
        captureSession.beginConfiguration()

        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let input = try? AVCaptureDeviceInput(device: videoDevice!), captureSession.canAddInput(input) else { return nil }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(output) else { return nil }
        captureSession.sessionPreset = .hd1920x1080
        captureSession.addOutput(output)
        captureSession.commitConfiguration()
        
        return output
    }
    
    private func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        _nextFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    func nextFrame() -> CVPixelBuffer? {
        return _nextFrame
    }
    
    func outputSize() -> CGSize {
        return CGSize(width: 1080, height: 1920)
    }
    
    func preferredTransform() -> CGAffineTransform {
        return CGAffineTransform.identity
    }
}
