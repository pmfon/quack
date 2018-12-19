//
//  DuckProcessor.swift
//  Quack
//
//  Created by Pedro Fonseca on 09/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import os
import UIKit
import ARKit
import Vision

class DuckProcessor : NSObject {

    private let sceneLog = OSLog(subsystem: "com.hecticant.quack.scene", category: "Scene")
    private weak var trackedView: UIView!
    private var boundingBoxes = [UUID: BoundingBoxView]()
    private var anchors = [UUID: [ARAnchor]]()
    private var reverseAnchors = [UUID: UUID]()
    private(set) var duckTracker: ObjectTracker!

    private var outputConverter: VisionOutputConverter
    

    init(with trackedView: UIView, outputConverter: VisionOutputConverter, duckTracker: DuckTracker) {
        self.trackedView = trackedView
        self.outputConverter = outputConverter
        self.duckTracker = duckTracker
        super.init()
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

    func updateTrackedObjects(for observations: [TrackedObject]) {
        guard duckTracker.tracking else { return }
        DispatchQueue.main.async {
            self.updateBoundingBoxes(for: observations)
        }
    }
    
    private func updateBoundingBoxes(for observations: [TrackedObject]) {
        for observation in observations {
            if let bbox = boundingBoxes[observation.trackingUUID] {
                bbox.observation = observation
            } else {
                let bbView = BoundingBoxView(with: observation, converter: outputConverter)
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
}
