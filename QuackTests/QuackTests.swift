//
//  QuackTests.swift
//  QuackTests
//
//  Created by Pedro Fonseca on 10/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import XCTest
import Vision
import ARKit
import Quack


class TestDelegate: ObjectTrackerDelegate {
    
    var expectation: XCTestExpectation
    var objectDetectionResult: [TrackedObject]?
    
    init(with expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func didPredict(result: ObjectTrackerResult) {
        switch result {
        case .success(let observations):
            objectDetectionResult = observations
        default:
            break
        }
        expectation.fulfill()
    }
}

class TestDataSource: ObjectTrackerDataSource {

    var nextFrame: CVPixelBuffer?
    
    init() {
        nextFrame = self.loadImageToPixelBuffer()
    }
    
    private func loadImageToPixelBuffer() -> CVPixelBuffer {
        let image = UIImage(named: "duck.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)
        return image!.pixelBuffer()!
    }
}


class QuackTests: XCTestCase {

    override func setUp() {}
    override func tearDown() {}

    func testPredictDuckWithSuccess() {
        let callbackExpectation = expectation(description: "The ObjectDetectorDelegate is called with the result of a detection request")
        let testDelegate = TestDelegate(with: callbackExpectation)
        let testDataSource = TestDataSource()
        let objectTracker = DuckTracker(withModel: Duck().model, dataSource:testDataSource, delegate: testDelegate)
        
        objectTracker.start()
        waitForExpectations(timeout: 2.0) { error in
            objectTracker.stop()
            
            if let error = error {
                XCTFail("ObjectDetectorDelegate expectation error: \(error)")
                return
            }
            
            guard let predictions = testDelegate.objectDetectionResult else {
                XCTFail("Predict did not return any result")
                return
            }

            if let prediction = predictions.first?.observation {
                let label = prediction.labels.first?.identifier
                XCTAssert(label == "duck", "Expected 'duck', but predicted \(String(describing: label))")
                XCTAssert(prediction.boundingBox != .zero, "The prediction must return a bounding box")
            }
        }
    }

    func testConvertVisionToViewportCoordinates() {
        let view = ARSKView(frame: CGRect(x:0, y:0, width:100, height:200))
        let converter = AugmentedSceneViewportConverter(view: view)
        
        // Vision coordinates are normalized, with lower-left origin. The Vision request input is centerCropped.
        let boundingBox1 = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        let viewportRect1 = converter.convertRect(from: boundingBox1)
        let expected1 = CGRect(x: 50, y: 50, width: 50, height: 50)
        XCTAssert(viewportRect1 == expected1, "Failed conversion from \(String(describing:boundingBox1))")
       
        let boundingBox2 = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        let viewportRect2 = converter.convertRect(from: boundingBox2)
        let expected2 = CGRect(x: 0, y: 100, width: 50, height: 50)
        XCTAssert(viewportRect2 == expected2, "Failed conversion from \(String(describing:boundingBox2))")
        
        let boundingBox3 = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        let viewportRect3 = converter.convertRect(from: boundingBox3)
        let expected3 = CGRect(x: 0, y: 50, width: 100, height: 100)
        XCTAssert(viewportRect3 == expected3, "Failed conversion from \(String(describing:boundingBox3))")
    }
    
    func testArrayHelpers() {
        var matrix: [[Float]] = [[0.9, 0.2, 0.3], [0.9, 0.5, 0.8], [0.7, 0.4, 0.1]]
        let min0 = matrix.removeMinRow()!
        XCTAssert(min0 == (2, 2, 0.1))
        XCTAssert(matrix.flatMap { $0 }.min()! > 0.1 )
        
        let min1 = matrix.removeMinRow()!
        XCTAssert(min1 == (0, 1, 0.2))
        XCTAssert(matrix.count == 1)
        
        let _ = matrix.removeMinRow()!
        XCTAssert(matrix.count == 0)
        XCTAssert(matrix.removeMinRow() == nil)
    }
}
