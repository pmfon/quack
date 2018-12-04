//
//  QuackViewController.swift
//  Quack
//
//  Created by Pedro Fonseca on 06/11/2018.
//  Copyright © 2018 Pedro Fonseca. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class QuackViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSKView!
    @IBOutlet var toggleSession: UIButton!
    private var arDelegate: QuackARDelegate?
    private var duckTracker: DuckTracker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAndPresentScene()
    }
    
    private func configureAndPresentScene() {
        guard let scene = SKScene(fileNamed: "Scene") else { return }

        arDelegate = QuackARDelegate(with: sceneView) { dataSource, delegate in
            let duckTracker = DuckTracker(withModel: Duck().model, dataSource: dataSource, delegate: delegate)
            self.duckTracker = duckTracker
            return duckTracker
        }
        sceneView.presentScene(scene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        toggleSession.isSelected = true
    }
    
    private func stopSession() {
        sceneView.session.pause()
        arDelegate?.stopTracking()
        toggleSession.isSelected = false
    }

    @IBAction func didToggleSession(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            startSession()
        } else {
            stopSession()
        }
    }
}
