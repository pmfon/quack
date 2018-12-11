//
//  BoundingBoxView.swift
//  Quack
//
//  Created by Pedro Fonseca on 17/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import Vision

class BoundingBoxView: UIView {
    
    private weak var confidenceLabel: UILabel?
    private let converter: VisionOutputConverter
    let strokeColor: UIColor

    var observation: VNDetectedObjectObservation {
        didSet {
            update(with: observation)
        }
    }
    
    private func update(with observation: VNDetectedObjectObservation) {
        frame = converter.convertRect(from: observation.boundingBox)
        confidenceLabel?.text = String(format: "%.2f", observation.confidence)
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    init(with observation: VNDetectedObjectObservation, converter: VisionOutputConverter) {
        self.observation = observation
        self.converter = converter
        self.strokeColor = BoundingBoxView.nextColor()
        
        let frame = converter.convertRect(from: observation.boundingBox)
        super.init(frame: frame)
        self.isOpaque = false
        
        setupConfidenceLabel()
    }
    
    private func setupConfidenceLabel() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.backgroundColor = strokeColor.withAlphaComponent(0.5)
        label.textColor = .white
        label.textAlignment = .center
        
        addSubview(label)
        confidenceLabel = label
    }
    

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(rect: self.bounds)
        path.lineWidth = 3.0
        
        if observation.confidence < 0.5 {
            let  dashes: [CGFloat] = [4.0, 4.0]
            path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        }

        strokeColor.setStroke()
        path.stroke()
    }
    

    private static var nextColor: (() -> (UIColor)) = {
        let palette = [#colorLiteral(red: 0.3019607843, green: 0.2392156863, blue: 0.9411764706, alpha: 1), #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1), #colorLiteral(red: 0, green: 0.5411764706, blue: 1, alpha: 1), #colorLiteral(red: 0, green: 0.6078431373, blue: 0.9607843137, alpha: 1), #colorLiteral(red: 0, green: 0.6549019608, blue: 0.7568627451, alpha: 1), #colorLiteral(red: 0, green: 0.6941176471, blue: 0.5215686275, alpha: 1)]
        var index = 0
        return { index = index + 1; return palette[index % palette.count ] }
    }()
}

