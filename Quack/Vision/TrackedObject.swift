//
//  TrackedObject.swift
//  Quack
//
//  Created by Pedro Fonseca on 28/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import Vision

public struct TrackedObject {
    var age: UInt = 0
    var staleness: UInt = 0
    let trackingUUID: UUID
    
    private let initialObservation: VNRecognizedObjectObservation
    public private(set) var observation: VNRecognizedObjectObservation
    public private(set) var weightedBoundingBox: CGRect
    
    mutating func update(_ observation: VNRecognizedObjectObservation) {
        self.observation = observation

        let w1: CGFloat = CGFloat(1.0 - pow(0.8, Double(staleness + 1)))
        let w0: CGFloat = 1 - w1
        weightedBoundingBox = weightedBoundingBox * w0 + observation.boundingBox * w1
    }
    
    init(observation: VNRecognizedObjectObservation) {
        self.trackingUUID = observation.uuid
        self.initialObservation = observation
        self.observation = observation
        self.weightedBoundingBox = observation.boundingBox
    }
}


private extension CGRect {
    
    static func * (rect: CGRect, right: CGFloat) -> CGRect {
        return CGRect(origin: rect.origin * right, size: rect.size * right)
    }
    
    static func + (left: CGRect, right: CGRect) -> CGRect {
        return CGRect(origin: left.origin + right.origin, size: left.size + right.size)
    }
}

private extension CGSize {
    
    static func * (size: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: size.width * right, height: size.height * right)
    }
    
    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }
}

private extension CGPoint {
    
    static func * (point: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * right, y: point.y * right)
    }
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}
