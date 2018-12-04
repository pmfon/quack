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

class QuackARDelegate : NSObject, ARSessionDelegate, ARSKViewDelegate, ObjectTrackerDataSource, ObjectTrackerDelegate {

    typealias TrackerInit = (ObjectTrackerDataSource, ObjectTrackerDelegate) -> (ObjectTracker)
    private let sceneLog = OSLog(subsystem: "com.hecticant.quack.scene", category: "Scene")
    private weak var sceneView: ARSKView!
    private var boundingBoxes = [UUID: BoundingBoxView]()
    private var anchors = [UUID: [ARAnchor]]()
    private var reverseAnchors = [UUID: UUID]()
    private var duckTracker: ObjectTracker!

    private var outputConverter: VisionOutputConverter
    private(set) var nextFrame: CVPixelBuffer? = nil
    

    init(with sceneView: ARSKView, tracker: TrackerInit) {
        self.sceneView = sceneView
        self.outputConverter = AugmentedSceneViewportConverter(view: sceneView)
        super.init()

        sceneView.delegate = self
        sceneView.session.delegate = self
        duckTracker = tracker(self, self)
    }

    private func startTrackingIfNeeded() {
        if !duckTracker.tracking {
            duckTracker.start()
        }
    }
    
    func stopTracking() {
        duckTracker.stop()
        removeBoundingBoxesNotTracked(by: [TrackedObject]())
    }
    

    func didPredict(result: ObjectTrackerResult) {
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
            self.updateAnchors(for: observations)
        }
    }
    
    private func updateBoundingBoxes(for observations: [TrackedObject]) {
        for observation in observations {
            if let bbox = boundingBoxes[observation.trackingUUID] {
                bbox.observation = observation.observation
            } else {
                let bbView = BoundingBoxView(with: observation.observation, converter: outputConverter)
                boundingBoxes[observation.trackingUUID] = bbView
                sceneView.addSubview(bbView)
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
    
    private func updateAnchors(for observations: [TrackedObject]) {
        removeStaleAnchors(for: observations)
        addNewAnchors(for: observations)
    }

    private func removeStaleAnchors(for observations: [TrackedObject]) {
        let toRemove = anchors.filter { key,_ in
            !observations.contains(where: { $0.trackingUUID == key})
        }

        toRemove.values.flatMap { $0 } .forEach {
            sceneView.session.remove(anchor: $0)
            reverseAnchors.removeValue(forKey: $0.identifier)
        }
        toRemove.keys.forEach {
            anchors.removeValue(forKey: $0 )
        }
    }
    
    private func addNewAnchors(for observations: [TrackedObject]) {
        for trackedObject in observations {
            guard let anchor = anchor(for: trackedObject.observation) else { continue }
            
            let uuid = trackedObject.trackingUUID
            if var anchorList = anchors[uuid],
                let prev = anchorList.last,
                simd_almost_equal_elements(anchor.transform, prev.transform, 0.1) {
                anchorList.append(anchor)
                anchors[uuid] = anchorList
            } else {
                anchors[uuid] = [anchor]
            }
            
            if anchors[uuid]?.last == anchor {
                reverseAnchors[anchor.identifier] = trackedObject.trackingUUID
                sceneView.session.add(anchor: anchor)
            }
        }
    }
    
    private func anchor(for observation: VNRecognizedObjectObservation) -> ARAnchor? {
        let viewRect = outputConverter.convertRect(from: observation.boundingBox)
        
        var hitTestResult: ARHitTestResult? = nil
        for y in stride(from: viewRect.maxY, to: viewRect.midY, by: -1.0) {
            let hit = CGPoint(x: viewRect.midX, y: y)
            hitTestResult = sceneView.hitTest(hit, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).last
            if hitTestResult != nil { break }
        }

        if let transform = hitTestResult?.worldTransform {
            return ARAnchor(name:"Waypoint", transform: transform)
        }
        return nil
    }
    
    private func stopTrackingAndPresentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart", style: .default, handler: { (action) in
            self.startTrackingIfNeeded()
        }))
        
        if let viewController = self.sceneView.next as? UIViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard case .normal = frame.camera.trackingState else { return }
        nextFrame = frame.capturedImage
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            startTrackingIfNeeded()
        default:
            break
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        stopTracking()
        
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        if let viewController = self.sceneView.next as? UIViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        stopTracking()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        startTrackingIfNeeded()
    }
    

    // MARK: ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // TODO: draw waypoints.
        return nil
        /*
        guard anchor.name == "Waypoint" else { return nil }
        
        let node = SKShapeNode(circleOfRadius: 1.0)
        if let objectId = reverseAnchors[anchor.identifier],
            let boundingBox = boundingBoxes[objectId] {
            node.strokeColor = boundingBox.strokeColor
        }

        return node
        */
    }
}
