//
//  QuackViewController.swift
//  Quack
//
//  Created by Pedro Fonseca on 06/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import AVFoundation

class QuackViewController: UIViewController, ObjectTrackerDataSource, ObjectTrackerDelegate {
    
    #if DEBUG_
    private typealias ViewType = VideoPlaybackView
    #else
    private typealias ViewType = VideoCaptureView
    #endif
    
    @IBOutlet var previewViewContainer: UIView!
    @IBOutlet var toggleSession: UIButton!
    @IBOutlet var fpsLabel: UILabel!
    
    private var previewView: ViewType!
    private var duckProcessor: DuckProcessor!
    private var outputProvider: VideoOutputProvider!
    
    
    // MARK: ObjectTrackerDataSource
    
    var nextFrame: CVPixelBuffer? {
        return outputProvider.nextFrame()
    }

    var frameRateInSeconds: Float32 {
        return outputProvider.frameRateInSeconds
    }
    

    // MARK: ObjectTrackerDelegate
    
    func didPredict(result: ObjectTrackerResult) {
        switch result {
        case .success(let observations):
            duckProcessor.updateTrackedObjects(for: observations)
        case .error(_):
            break;
        }
    }
    
    func didStartTracking() {
        DispatchQueue.main.async {
            self.toggleSession.isSelected = true
        }
    }
    
    func didStopTracking(error: Error?) {
        DispatchQueue.main.async {
            self.toggleSession.isSelected = false
            if let error = error {
                self.presentError(error)
            }
        }
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

        let duckTracker = DuckTracker(withModel: Duck().model, dataSource: self, delegate: self)
        let outputConverter = VideoLayerViewportConverter(view: previewView, outputProvider: outputProvider)
        duckProcessor = DuckProcessor(with: previewView, outputConverter: outputConverter, duckTracker: duckTracker)
    }

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
        duckProcessor?.startTrackingIfNeeded()
    }
    
    private func stopSession() {
        duckProcessor?.stopTracking()
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .default, handler: { (action) in
             self.duckProcessor.startTrackingIfNeeded()
        }))
        
        present(alert, animated: true, completion: nil)
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
