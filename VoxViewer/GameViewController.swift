//	GameViewController.swift
//	VoxViewer
//
//	Created by Cap'n Slipp on 5/20/16.
//	Copyright (c) 2016 Cap'n Slipp. All rights reserved.

import QuartzCore
import SceneKit
import SceneKit.ModelIO
import simd
import MDLVoxelAsset


#if os(iOS)
	import UIKit
	typealias Color = UIColor
	typealias ViewController = UIViewController
#else
	import AppKit
	typealias Color = NSColor
	typealias ViewController = NSViewController
#endif



class GameViewController: ViewController
{
	@IBOutlet weak var gameView:SCNView!
	
	
	#if os(iOS)
		override func viewDidLoad() {
			super.awakeFromNib()
			
			setupScene()
		}
	#else
		override func awakeFromNib() {
			super.viewDidLoad()
			
			setupScene()
		}
	#endif
	
	func setupScene()
	{
		// create a new scene
		let scene = SCNScene()
		
		
		// create and add a camera to the scene
		
		let cameraNode = SCNNode()
		cameraNode.camera = {
			let c = SCNCamera()
			c.automaticallyAdjustsZRange = true
			return c
		}()
		scene.rootNode.addChildNode(cameraNode)
		
		
		// floor
		
		let floorNode = SCNNode(geometry: {
			let f = SCNFloor()
			f.reflectivity = 0
			return f
		}())
		scene.rootNode.addChildNode(floorNode)
		
		
		// create and add the .vox node
		
		let modelAsset:MDLVoxelAsset = fetchVoxelAsset(named: "chr_sword")
		let modelCenterpoint:SCNVector3 = {
			let bbox = modelAsset.boundingBox
			return SCNVector3(bbox.minBounds + (bbox.maxBounds - bbox.minBounds) * 0.5)
		}()
		
		let modelNode:SCNNode = {
			if (modelAsset.count == 1) {
				return SCNNode(MDLObject: modelAsset[0]!)
			}
			else if (modelAsset.count > 1) {
				let baseNode = SCNNode()
				for assetSubObject:MDLObject in modelAsset.objects {
					baseNode.addChildNode(SCNNode(MDLObject: assetSubObject))
				}
				return baseNode
			}
			else {
				return SCNNode()
				// @todo: throw
			}
		}()
		
		scene.rootNode.addChildNode(modelNode)
		
		
		// place the camera
		
		cameraNode.eulerAngles = SCNVector3(0, 0, 0)
		cameraNode.position = SCNVector3(
			0.0,
			Float(modelCenterpoint.y),
			{
				let bbox = modelAsset.boundingBox
				return bbox.maxBounds.z + (bbox.maxBounds.z - bbox.minBounds.z) * 0.5 + 15
			}()
		)
		
		
		// create and add a light to the scene
		
		let lightNode = SCNNode()
		lightNode.light = {
			let l = SCNLight()
			l.type = SCNLightTypeSpot
			l.color = Color(hue: 60.0 / 360.0, saturation: 0.2, brightness: 1.0, alpha: 1.0)
			l.spotOuterAngle = 135
			l.spotInnerAngle = l.spotOuterAngle * 0.9
			l.castsShadow = true
			l.zNear = 1
			l.zFar = {
				let bbox = modelAsset.boundingBox
				let extents = (bbox.maxBounds - bbox.minBounds)
				return sqrt(
					pow(CGFloat(extents.x), 2) +
					pow(CGFloat(extents.y), 2) +
					pow(CGFloat(extents.z), 2)
				)
			}() * 2
			return l
		}()
		lightNode.position = {
			let bbox = modelAsset.boundingBox
			return SCNVector3(bbox.maxBounds.x, bbox.maxBounds.y, bbox.maxBounds.z)
		}()
		scene.rootNode.addChildNode(lightNode)
		
		if lightNode.constraints == nil {
			lightNode.constraints = [SCNConstraint]()
		}
		lightNode.constraints!.append(SCNLookAtConstraint(target: modelNode))
		
		
		// create and add an ambient light to the scene
		
		let ambientLightNode = SCNNode()
		ambientLightNode.light = {
			let l = SCNLight()
			l.type = SCNLightTypeAmbient
			l.color = Color(hue: 240.0 / 360.0, saturation: 1.0, brightness: 0.1, alpha: 1.0)
			return l
		}()
		scene.rootNode.addChildNode(ambientLightNode)
		
		
		// axis widget
		
		let axisSphere = SCNSphere(radius: 0.25)
		let coloredSphereNode = {(position:SCNVector3, color:Color) -> SCNNode in
			let s = (axisSphere.copy() as! SCNSphere)
			s.firstMaterial = {
				let material = SCNMaterial()
				material.diffuse.contents = color
				return material
			}()
			let n = SCNNode(geometry: s)
			n.position = position
			return n
		}
		let axisSphereNodes = [
			coloredSphereNode(SCNVector3(0.0, 0.0, 0.0), Color.whiteColor()),
			coloredSphereNode(SCNVector3(+1.0, 0.0, 0.0), Color.redColor()),
			coloredSphereNode(SCNVector3(0.0, +1.0, 0.0), Color.greenColor()),
			coloredSphereNode(SCNVector3(0.0, 0.0, +1.0), Color.blueColor()),
		]
		for node in axisSphereNodes {
			scene.rootNode.addChildNode(node)
		}
		
		//// animate the 3d object
		//modelNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
		
		// retrieve the SCNView
		let gameView = self.gameView
		
		// set the scene to the view
		gameView.scene = scene
		
		// allows the user to manipulate the camera
		gameView.allowsCameraControl = true
		
		// show statistics such as fps and timing information
		gameView.showsStatistics = true
		
		// configure the view
		gameView.backgroundColor = Color.blackColor()
		
		#if os(iOS)
			// add a tap gesture recognizer
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			gameView.addGestureRecognizer(tapGesture)
		#endif
	}
	
	func fetchVoxelAsset(named name:String) -> MDLVoxelAsset
	{
		var path = NSBundle.mainBundle().pathForResource(name, ofType:"")
		if (path == nil) {
			path = NSBundle.mainBundle().pathForResource(name, ofType:"vox")
		}
		
		let asset = MDLVoxelAsset(URL: NSURL(fileURLWithPath: path!), options:[
			kMDLVoxelAssetOptionCalculateShellLevels: false,
			kMDLVoxelAssetOptionSkipNonZeroShellMesh: false,
		])
		return asset
	}
	
	#if os(iOS)
		func handleTap(gestureRecognize: UIGestureRecognizer) {
			// retrieve the SCNView
			let scnView = self.view as! SCNView
			
			// check what nodes are tapped
			let p = gestureRecognize.locationInView(scnView)
			let hitResults = scnView.hitTest(p, options: nil)
			// check that we clicked on at least one object
			if hitResults.count > 0 {
				// retrieved the first clicked object
				let result: AnyObject! = hitResults[0]
				
				// get its material
				let material = result.node!.geometry!.firstMaterial!
				
				// highlight it
				SCNTransaction.begin()
				SCNTransaction.setAnimationDuration(0.5)
				
				// on completion - unhighlight
				SCNTransaction.setCompletionBlock {
					SCNTransaction.begin()
					SCNTransaction.setAnimationDuration(0.5)
					
					material.emission.contents = Color.blackColor()
					
					SCNTransaction.commit()
				}
				
				material.emission.contents = Color.redColor()
				
				SCNTransaction.commit()
			}
		}
		
		override func shouldAutorotate() -> Bool {
			return true
		}
		
		override func prefersStatusBarHidden() -> Bool {
			return true
		}
		
		override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
			if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
				return .AllButUpsideDown
			} else {
				return .All
			}
		}
		
		override func didReceiveMemoryWarning() {
			super.didReceiveMemoryWarning()
			// Release any cached data, images, etc that aren't in use.
		}
	#endif
	
}
