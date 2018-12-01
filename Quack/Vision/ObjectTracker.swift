//
//  ObjectTracker.swift
//  Quack
//
//  Created by Pedro Fonseca on 10/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import CoreML

public enum ObjectTrackerResult {
    case error(Error)
    case success([TrackedObject])
}

public protocol ObjectTrackerDelegate: class {
    func didPredict(result: ObjectTrackerResult)
}

public protocol ObjectTrackerDataSource: class {
    var outputConverter: VisionOutputConverter { get }
    var nextFrame: CVPixelBuffer? { get }
}

protocol ObjectTracker {
    init(withModel model: MLModel, dataSource: ObjectTrackerDataSource, delegate: ObjectTrackerDelegate)
    var tracking: Bool { get }
    func start()
    func stop()
}