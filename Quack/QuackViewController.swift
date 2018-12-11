//
//  QuackViewController.swift
//  Quack
//
//  Created by Pedro Fonseca on 06/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import AVFoundation

class QuackViewController: UIViewController, ObjectTrackerDataSource {
    #if DEBUG
    private typealias ViewType = VideoPlaybackView
    #else
    private typealias ViewType = VideoCaptureView
    #endif
    
    @IBOutlet var previewViewContainer: UIView!
    @IBOutlet var toggleSession: UIButton!
    
    private var previewView: ViewType!
    private var arDelegate: QuackARDelegate?
    private var outputProvider: VideoOutputProvider!
    

    var nextFrame: CVPixelBuffer? {
        return outputProvider.nextFrame()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPreviewView()
        configureAndPresentScene()
    }
    
    private func addPreviewView() {
        previewView = ViewType()
        previewViewContainer.addSubview(previewView)
        previewView.fitToSuperview()
    }
    
    private func configureAndPresentScene() {
        
        let asset = AVAsset(url: Bundle.main.url(forResource: "IMG_0299", withExtension: "mov")!)
        outputProvider = BuildVideoOutputProvider(view: previewView, options: VideoOutputProviderOptions(asset: asset))

        let outputConverter = VideoLayerViewportConverter(view: previewView, outputProvider: outputProvider)
        arDelegate = QuackARDelegate(with: previewView, outputConverter: outputConverter) { delegate in
            let duckTracker = DuckTracker(withModel: Duck().model, dataSource: self, delegate: delegate)
            return duckTracker
        }
    }

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func startSession() {
        arDelegate?.startTrackingIfNeeded()
        toggleSession.isSelected = true
    }
    
    private func stopSession() {
        arDelegate?.stopTracking()
        toggleSession.isSelected = false
    }

    @IBAction func didToggleSession(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            startSession()
        } else {
            stopSession()
        }
    }
}

extension UIView {
    
    fileprivate func fitToSuperview() {
        guard let superview = superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
    }
}
