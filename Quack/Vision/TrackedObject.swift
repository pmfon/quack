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
    public internal(set) var observation: VNRecognizedObjectObservation
    
    init(observation: VNRecognizedObjectObservation) {
        self.trackingUUID = observation.uuid
        self.initialObservation = observation
        self.observation = observation
    }
}
