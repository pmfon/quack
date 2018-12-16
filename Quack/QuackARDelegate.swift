//
//  QuackARDelegate.swift
//  Quack
//
//  Created by Pedro Fonseca on 09/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import os
import UIKit
import ARKit
import Vision

class QuackARDelegate : NSObject, ObjectTrackerDelegate {

    typealias TrackerInit = (ObjectTrackerDelegate) -> (ObjectTracker)
    private let sceneLog = OSLog(subsystem: "com.hecticant.quack.scene", category: "Scene")
    private weak var trackedView: UIView!
    private var boundingBoxes = [UUID: BoundingBoxView]()
    private var anchors = [UUID: [ARAnchor]]()
    private var reverseAnchors = [UUID: UUID]()
    private var duckTracker: ObjectTracker!

    private var outputConverter: VisionOutputConverter
    

    init(with trackedView: UIView, outputConverter: VisionOutputConverter, tracker: TrackerInit) {
        self.trackedView = trackedView
        self.outputConverter = outputConverter
        super.init()
        duckTracker = tracker(self)
    }

    func startTrackingIfNeeded() {
        if !duckTracker.tracking {
            duckTracker.start()
        }
    }
    
    func stopTracking() {
        duckTracker.stop()
        removeBoundingBoxesNotTracked(by: [TrackedObject]())
    }
    

    func didPredict(result: ObjectTrackerResult) {
        if !duckTracker.tracking { return }
        
        switch result {
        case .success(let observations):
            updateTrackedObjects(for: observations)
        case .error(_):
            break;
        }
    }

    private func updateTrackedObjects(for observations: [TrackedObject]) {
        DispatchQueue.main.async {
            self.updateBoundingBoxes(for: observations)
        }
    }
    
    private func updateBoundingBoxes(for observations: [TrackedObject]) {
        for observation in observations {
            if let bbox = boundingBoxes[observation.trackingUUID] {
                bbox.observation = observation.observation
            } else {
                let bbView = BoundingBoxView(with: observation.observation, converter: outputConverter)
                boundingBoxes[observation.trackingUUID] = bbView
                trackedView.addSubview(bbView)
            }
        }

        removeBoundingBoxesNotTracked(by: observations)
    }
    
    private func removeBoundingBoxesNotTracked(by observations: [TrackedObject]) {
        let deadBoxes = boundingBoxes.filter { box in
            !observations.contains { $0.trackingUUID == box.key }
        }

        deadBoxes.forEach {
            boundingBoxes.removeValue(forKey: $0.0)
            $0.1.removeFromSuperview()
        }
    }
   
    private func stopTrackingAndPresentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .default, handler: { (action) in
            self.startTrackingIfNeeded()
        }))
        
        if let viewController = self.trackedView.next as? UIViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
