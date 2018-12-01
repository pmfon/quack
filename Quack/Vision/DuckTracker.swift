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
    private weak var delegate: ObjectTrackerDelegate?
    private weak var dataSource: ObjectTrackerDataSource?
    
    private var trackedObjects = [TrackedObject]()
    private(set) var tracking = false
    private let maxAge = 100

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
                let input = self.dataSource?.nextFrame {
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
    
    private func handleFeatureResults(_ results:  [VNRecognizedObjectObservation]) {
        os_log("Predicted %d features", log:visionLog, type: .debug, results.count)
        results.forEach { logObservation($0) }

        updateTracked(results)
        delegate?.didPredict(result: .success(trackedObjects))
    }
    
    private func updateTracked(_ observations: [VNRecognizedObjectObservation]) {
        var unprocessedObservations = observations.sorted { $0.confidence > $1.confidence }

        // Check for objects that intersect existing objects. An object with an
        // IoU > 0.5 with previous prediction is considered the "same object".
        for index in trackedObjects.indices {
            trackedObjects[index].age += 1
            trackedObjects[index].staleness += 1
            
            let max = findMax(in: unprocessedObservations, tracking: trackedObjects[index])
            if max.iou > self.iouThreshold {
                trackedObjects[index].observation = unprocessedObservations.remove(at: max.index)
                trackedObjects[index].staleness = 0
            }
            
            logObservation(trackedObjects[index].observation, prefix: "Updating")
            os_log("Max IoU is %f", log:self.visionLog, type: .debug, max.iou)
        }
        
        // Add objects that do not intersect with existing objects.
        unprocessedObservations.forEach {
            let trackedObservation = TrackedObject(observation: $0)
            trackedObjects.append(trackedObservation)
        }
        
        // Remove objects which were not detected in the last `maxAge` frames.
        let filtered = trackedObjects.filter { $0.staleness < maxAge }
        trackedObjects = filtered
    }
    
    private func findMax(in observations: [VNRecognizedObjectObservation], tracking: TrackedObject) -> (iou: Float, index: Int) {
        let referenceBoundingBox = tracking.observation.boundingBox
        var index = -1
        
        let max = observations.reduce(into: (iou: Float(-1), index: -1)) { result, object in
            index += 1
            let iou = DuckTracker.intersectionOverUnion(object.boundingBox, referenceBoundingBox, converter: dataSource?.outputConverter)
            if iou > result.iou {
                result.iou = iou
                result.index = index
            }
        }

        return max
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

extension ObjectTracker {
    var iouThreshold: Float {
        set {
            let clampedValue = min(max(newValue, 0.1), 0.9)
            UserDefaults.standard.set(clampedValue, forKey: "com.hecticant.quack.iouThreshold")
        }
        get {
            let value = UserDefaults.standard.float(forKey: "com.hecticant.quack.iouThreshold")
            return value == 0 ? 0.5 : value
        }
    }
}
