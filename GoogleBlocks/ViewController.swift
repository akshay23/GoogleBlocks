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
    
    var shouldUseCamp = true
    var tavernModel: SCNNode!
    var campModel: SCNNode!
    var recorder: RecordAR?
    
    private var originalRotation: SCNVector3?
    private var selectedNode: SCNNode?
    
    let farmScene = SCNScene(named: "camp.dae")!
    let tavernScene = SCNScene(named: "tavern.dae")!
    
    var randomEmoji: String {
        let emojis = ["🤓", "🔥", "😜", "😇", "🤣", "🤗", "🧐", "🐰", "🚀", "👻"]
        return emojis[Int(arc4random_uniform(UInt32(emojis.count)))]
    }
    
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
        sceneView.scene = scene
        sceneView.antialiasingMode = .multisampling4X
        
        // Enable lighting
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // Init models
        campModel = farmScene.rootNode.childNode(withName: "camp", recursively: true)
        tavernModel = tavernScene.rootNode.childNode(withName: "tavern", recursively: true)
        
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
        
        // Single tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGesture)
        
        // Long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGesture.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(longPressGesture)
        tapGesture.require(toFail: longPressGesture)
        
        // Double tap gesture
        let doubleTapGesuture = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGesuture.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(doubleTapGesuture)
        tapGesture.require(toFail: doubleTapGesuture)
        
        // Triple tap gesture
        let tripleTapGesuture = UITapGestureRecognizer(target: self, action: #selector(tripleTap))
        tripleTapGesuture.numberOfTapsRequired = 3
        sceneView.addGestureRecognizer(tripleTapGesuture)
        tapGesture.require(toFail: tripleTapGesuture)
        doubleTapGesuture.require(toFail: tripleTapGesuture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        sceneView.addGestureRecognizer(pinchGesture)
        
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned))
        sceneView.addGestureRecognizer(panGesture)
        tapGesture.require(toFail: panGesture)
        
        // Rotate gesutre
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
        sceneView.addGestureRecognizer(rotateGesture)
        tapGesture.require(toFail: doubleTapGesuture)
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

    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == "camp" || node.name == "tavern" || node.name == "emoji" || node.name == "timmy" {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        shouldUseCamp = true

        let hitResults: [SCNHitTestResult] = sceneView.hitTest(location, options: hitTestOptions)
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }

        let planeHitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if !planeHitTest.isEmpty,
            let result = planeHitTest.first,
            let farmNode = farmScene.rootNode.childNode(withName: "camp", recursively: true) {
            farmNode.position = SCNVector3(result.worldTransform.columns.3.x,
                                            result.worldTransform.columns.3.y,
                                            result.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(farmNode)
        } else {
            let hitResultsFeaturePoints: [ARHitTestResult] = sceneView.hitTest(location, types: .featurePoint)
            if let hit = hitResultsFeaturePoints.first {
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        }
    }
    
    @objc func longPress(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .ended {
            guard let currentFrame = sceneView.session.currentFrame else { return }
            
            let videoNode = SKVideoNode(fileNamed: "TimmyTop10.mp4")
            videoNode.play()
            
            let skScene = SKScene(size: CGSize(width: 640, height: 480))
            skScene.addChild(videoNode)
            
            videoNode.position = CGPoint(x: skScene.size.width/2, y: skScene.size.height/2)
            videoNode.size = skScene.size
            
            let tvPlane = SCNPlane(width: 1.0, height: 0.75)
            tvPlane.firstMaterial?.diffuse.contents = skScene
            tvPlane.firstMaterial?.isDoubleSided = true
            
            let tvPlaneNode = SCNNode(geometry: tvPlane)
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -1.0
            
            tvPlaneNode.name = "timmy"
            tvPlaneNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
            tvPlaneNode.eulerAngles = SCNVector3(Double.pi, 0, 0)
            
            sceneView.scene.rootNode.addChildNode(tvPlaneNode)
        }
    }
    
    @objc func doubleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        shouldUseCamp = false
        
        let hitResults: [SCNHitTestResult] = sceneView.hitTest(location, options: hitTestOptions)
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        
        let planeHitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if !planeHitTest.isEmpty,
            let result = planeHitTest.first,
            let tavernNode = tavernScene.rootNode.childNode(withName: "tavern", recursively: true) {
            tavernNode.position = SCNVector3(result.worldTransform.columns.3.x,
                                             result.worldTransform.columns.3.y,
                                             result.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(tavernNode)
        } else {
            let hitResultsFeaturePoints: [ARHitTestResult] = sceneView.hitTest(location, types: .featurePoint)
            if let hit = hitResultsFeaturePoints.first {
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        }
    }
    
    @objc func tripleTap(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        let emojiNode = SKLabelNode(text: randomEmoji)
        emojiNode.horizontalAlignmentMode = .center
        emojiNode.verticalAlignmentMode = .center
        
        // Animate node
        emojiNode.run(.sequence([
            .repeatForever(.sequence([
                // A group of actions get performed simultaneously
                .group([
                    .sequence([
                        .scale(to: 1.5, duration: 0.3),
                        .scale(to: 1, duration: 0.3)
                        ]),
                    // Rotate by 360 degrees (pi * 2 in radians)
                    .rotate(byAngle: .pi * 2, duration: 0.6)
                    ]),
                .wait(forDuration: 2)
                ]))
        ]))
        
        let skScene = SKScene(size: CGSize(width: 60, height: 60))
        skScene.addChild(emojiNode)
        emojiNode.position = CGPoint(x: skScene.size.width/2, y: skScene.size.height/2)
        
        let emojiPlane = SCNPlane(width: 0.5, height: 0.5)
        emojiPlane.firstMaterial?.diffuse.contents = skScene
        emojiPlane.firstMaterial?.isDoubleSided = true
        
        let emojiPlaneNode = SCNNode(geometry: emojiPlane)
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.0
        
        emojiPlaneNode.name = "emoji"
        emojiPlaneNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        emojiPlaneNode.eulerAngles = SCNVector3(Double.pi, 0, 0)
        
        sceneView.scene.rootNode.addChildNode(emojiPlaneNode)
    }
    
    @objc func pinched(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            guard let sceneView = recognizer.view as? ARSCNView else { return }
            
            let location = recognizer.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: nil)
            
            if let result = hitResults.first, let node = result.node.parent {
                let pinchScaleX = Float(recognizer.scale) * node.scale.x
                let pinchScaleY = Float(recognizer.scale) * node.scale.y
                let pinchScaleZ = Float(recognizer.scale) * node.scale.z
                
                node.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
                recognizer.scale = 1
            }
        }
    }
    
    @objc func rotate(recognizer: UIRotationGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        guard let result = hitResults.first, let node = result.node.parent else { return }
        
        if recognizer.state == .began {
            originalRotation = node.eulerAngles
        } else if recognizer.state == .changed {
            guard var originalRotation = originalRotation else { return }
            originalRotation.y -= Float(recognizer.rotation)
            node.eulerAngles = originalRotation
        } else {
            originalRotation = nil
        }
    }
    
    @objc func panned(recognizer: UIPanGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        guard let result = hitResults.first else { return }
        
        if recognizer.state == .began {
            selectedNode = result.node.parent
        } else if recognizer.state == .changed {
            guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
            let transform = result.worldTransform
            let newPosition = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
        } else {
            selectedNode = nil
        }
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
    
    // Add node to anchor point
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                let modelClone = strongSelf.shouldUseCamp ? strongSelf.campModel.clone() : strongSelf.tavernModel.clone()
                modelClone.position = SCNVector3Zero
                node.addChildNode(modelClone)
            }
        }
    }
}



