//
//  DuckTracker.swift
//  Quack
//
//  Created by Pedro Fonseca on 25/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import os
import UIKit
import Vision

public class DuckTracker: ObjectTracker, VisionHelper {
    
    private let visionLog = OSLog(subsystem: "com.hecticant.quack.vision.tracker", category: "Vision")
    private let duckTrackingQueue = DispatchQueue(label: "com.hecticant.quack.duckTracker", qos: .userInteractive)
    
    private let model: MLModel
    private weak var delegate: ObjectTrackerDelegate!
    private weak var dataSource: ObjectTrackerDataSource!
    
    private var trackedObjects = [TrackedObject]()
    private(set) var tracking = false {
        didSet {
            if tracking {
                delegate.didStartTracking()
            } else {
                delegate.didStopTracking(error: nil)
            }
        }
    }
    private let minConfidence = Float(0.40)
    private let maxAge = 24

    required public init(withModel model: MLModel, dataSource: ObjectTrackerDataSource, delegate: ObjectTrackerDelegate) {
        self.model = model
        self.delegate = delegate
        self.dataSource = dataSource
    }
    
    
    public func stop() {
        tracking = false
    }
    
    public func start() {
        guard tracking == false else { return }
        tracking = true
        
        duckTrackingQueue.async {
            let requestHandler = VNSequenceRequestHandler()
            while self.tracking,
                let input = self.dataSource.nextFrame {
                    do {
                        try requestHandler.perform([self.featureValueRequest], on: input, orientation: self.imageOrientation)
                        if let results = self.featureValueRequest.results as? [VNRecognizedObjectObservation] {
                            self.handleFeatureResults(results)
                        }
                    } catch {
                        self.handleFeatureError(error)
                    }
            }
            
            self.tracking = false
        }
    }
    
    private lazy var featureValueRequest: VNCoreMLRequest = {
        do {
            os_log("CoreML model input:\n%{public}@", log:visionLog, type: .info, model.modelDescription.inputDescriptionsByName.map { $0.value })
            os_log("CoreML model output:\n%{public}@", log:visionLog, type: .info, model.modelDescription.outputDescriptionsByName.map { $0.value })
            
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            os_log("Failed to load Vision ML model: %{public}@", log:visionLog, type: .error, error.localizedDescription)
            fatalError()
        }
    }()
    
    private func handleFeatureError(_ error: Error) {
        os_log("Vision request failed with error: %{public}@", log:self.visionLog, type: .error, error.localizedDescription)
        delegate?.didPredict(result: .error(error))
    }
    
    private func handleFeatureResults(_ results: [VNRecognizedObjectObservation]) {
        os_log("Predicted %d features", log:visionLog, type: .debug, results.count)
        results.forEach { logObservation($0) }
 
        updateTracked(results)
        delegate?.didPredict(result: .success(trackedObjects))
    }
    
    private func updateTracked(_ observations: [VNRecognizedObjectObservation]) {
        // One frame older...
        for index in trackedObjects.indices {
            trackedObjects[index].age += 1
            trackedObjects[index].staleness += 1
        }
        
        // Ignore observations below the defined confidence threshold.
        var unprocessedObservations = observations.filter { $0.confidence > minConfidence }
        
        // The naïve version: calculate the distance between centroids to find the observations
        // that track existing objects.
        var distances = unprocessedObservations.map { observation in
            trackedObjects.map { $0.observation.boundingBox.distance(to: observation.boundingBox) }
        }
        while distances.count > 0 {
            let (minRow, minCol, min) = distances.removeMinRow()!
            let observation = unprocessedObservations.remove(at: minRow)
            if min < 1.0 {
                trackedObjects[minCol].observation = observation
                trackedObjects[minCol].staleness = 0
            } else {
                unprocessedObservations.append(observation)
            }
        }
            
        // Start tracking observations that do not intersect with existing objects.
        unprocessedObservations.forEach {
            let trackedObservation = TrackedObject(observation: $0)
            trackedObjects.append(trackedObservation)
        }
        
        // Remove objects which were not detected in the last `maxAge` frames.
        let filtered = trackedObjects.filter { $0.staleness < maxAge }
        trackedObjects = filtered
    }
    
    private func logObservation(_ observation: VNRecognizedObjectObservation, prefix: String = "") {
        os_log("%@ %{public}@: %{public}@, %f, (%.2f, %.2f, %.2f, %.2f)", log:visionLog, type: .debug,
               prefix,
               observation.uuid.uuidString,
               observation.labels.first?.identifier ?? "n/a",
               observation.confidence,
               observation.boundingBox.origin.x,
               observation.boundingBox.origin.y,
               observation.boundingBox.size.width,
               observation.boundingBox.size.height)
    }
}

extension CGRect {
    func distance(to rect: CGRect) -> Float {
        return Float(hypot(rect.midX - midX, rect.midY - midY))
    }
}

public extension Array where Element == [Float] {
    mutating func removeMinRow() -> (Int,Int,Float)? {
        guard count > 0 else { return nil }
        
        var min = Float(1.0)
        var minCol = 0
        var minRow = 0

        for i in 0..<count {
            for j in 0..<self[i].count {
                if self[i][j] < min {
                    min = self[i][j]
                    minCol = j
                    minRow = i
                }
            }
        }
        
        self.remove(at: minRow)
        return (minRow, minCol, min)
    }
}
