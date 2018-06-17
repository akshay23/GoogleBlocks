//
//  ViewController.swift
//  Hello-AR
//
//  Created by Mohammad Azam on 6/18/17.
//  Copyright © 2017 Mohammad Azam. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARVideoKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var nodeModel: SCNNode!
    var recorder: RecordAR?
    
    var recorderButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Record", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 110, height: 60)
        button.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height*0.90)
        button.layer.cornerRadius = button.bounds.height/2
        button.tag = 0
        return button
    }()
    
    var pauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pause", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        button.center = CGPoint(x: UIScreen.main.bounds.width*0.15, y: UIScreen.main.bounds.height*0.90)
        button.layer.cornerRadius = button.bounds.height/2
        button.alpha = 0.3
        button.isEnabled = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        let scene = SCNScene()
        sceneView.showsStatistics = true
        sceneView.scene = scene
        sceneView.antialiasingMode = .multisampling4X
        
        // Enable lighting
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        let farmScene = SCNScene(named: "camp.dae")!
        nodeModel = farmScene.rootNode.childNode(withName: "camp", recursively: true)
        
        // Add buttons
        view.addSubview(recorderButton)
        view.addSubview(pauseButton)
        
        // Connect button actions
        recorderButton.addTarget(self, action: #selector(recorderAction(sender:)), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseAction(sender:)), for: .touchUpInside)
        
        // Initialize with SpriteKit
        recorder = RecordAR(ARSceneKit: sceneView)
        
        // Specificy supported orientations
        recorder?.inputViewOrientations = [.portrait, .landscapeLeft, .landscapeRight]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        // Prep recorder
        recorder?.prepare()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        // End recorder session
        recorder?.rest()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult] = sceneView.hitTest(location, options: hitTestOptions)
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        
        let planeHitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if !planeHitTest.isEmpty, let result = planeHitTest.first {
            let farmScene = SCNScene(named: "camp.dae")!
            let farmNode = farmScene.rootNode.childNode(withName: "camp", recursively: true)
            farmNode!.position = SCNVector3(result.worldTransform.columns.3.x,
                                            result.worldTransform.columns.3.y,
                                            result.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(farmNode!)
        } else {
            let hitResultsFeaturePoints: [ARHitTestResult] = sceneView.hitTest(location, types: .featurePoint)
            if let hit = hitResultsFeaturePoints.first {
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        }
    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == "camp" {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
    // Record and stop method
    @objc func recorderAction(sender: UIButton) {
        if recorder?.status == .readyToRecord {
            recorder?.record()
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            pauseButton.alpha = 1.0
            pauseButton.isEnabled = true
        } else if recorder?.status == .recording || recorder?.status == .paused {
            recorder?.stopAndExport()
            sender.setTitle("Record", for: .normal)
            sender.setTitleColor(.black, for: .normal)
            pauseButton.alpha = 0.3
            pauseButton.isEnabled = false
        }
    }
    
    // Pause and resume method
    @objc func pauseAction(sender: UIButton) {
        if recorder?.status == .recording {
            recorder?.pause()
            sender.setTitle("Resume", for: .normal)
            sender.setTitleColor(.blue, for: .normal)
        } else if recorder?.status == .paused {
            recorder?.record()
            sender.setTitle("Pause", for: .normal)
            sender.setTitleColor(.black, for: .normal)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                
                // Add model as a child of the node
                node.addChildNode(modelClone)
            }
        }
    }
}



