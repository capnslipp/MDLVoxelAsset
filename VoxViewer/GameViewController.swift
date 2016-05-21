//	GameViewController.swift
//	VoxViewer
//
//	Created by Cap'n Slipp on 5/20/16.
//	Copyright (c) 2016 Cap'n Slipp. All rights reserved.

import UIKit
import QuartzCore
import SceneKit
import MDLVoxelAsset



class GameViewController: UIViewController
{
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// create a new scene
		let scene = SCNScene()
		
		// create and add a camera to the scene
		let cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		scene.rootNode.addChildNode(cameraNode)
		
		// place the camera
		cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
		
		// create and add a light to the scene
		let lightNode = SCNNode()
		lightNode.light = SCNLight()
		lightNode.light!.type = SCNLightTypeOmni
		lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
		scene.rootNode.addChildNode(lightNode)
		
		// create and add an ambient light to the scene
		let ambientLightNode = SCNNode()
		ambientLightNode.light = SCNLight()
		ambientLightNode.light!.type = SCNLightTypeAmbient
		ambientLightNode.light!.color = UIColor.darkGrayColor()
		scene.rootNode.addChildNode(ambientLightNode)
		
		// create and add the .vox node
		let ship = createVoxelModel(named: "chr_sword")
		scene.rootNode.addChildNode(ship)
		
		//// animate the 3d object
		//ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
		
		// retrieve the SCNView
		let scnView = self.view as! SCNView
		
		// set the scene to the view
		scnView.scene = scene
		
		// allows the user to manipulate the camera
		scnView.allowsCameraControl = true
		
		// show statistics such as fps and timing information
		scnView.showsStatistics = true
		
		// configure the view
		scnView.backgroundColor = UIColor.blackColor()
		
		// add a tap gesture recognizer
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
		scnView.addGestureRecognizer(tapGesture)
	}
	
	func createVoxelModel(named name:String) -> SCNNode
	{
		var path = NSBundle.mainBundle().pathForResource(name, ofType:"")
		if (path == nil) {
			path = NSBundle.mainBundle().pathForResource(name, ofType:"vox")
		}
		
		let asset = MDLVoxelAsset(URL: NSURL(fileURLWithPath: path!))
		let voxelPaletteIndices = asset.voxelPaletteIndices as Array<Array<Array<NSNumber>>>
		let paletteColors = asset.paletteColors as [UIColor]
		
		var coloredBoxes = Dictionary<UIColor, SCNBox>()
		
		// Create voxel grid from MDLAsset
		let grid:MDLVoxelArray = asset.voxelArray
		let voxelData = grid.voxelIndices()!;   // retrieve voxel data
		
		// Create voxel parent node
		let baseNode = SCNNode();
		
		// Create the voxel node geometry
		let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0);
		
		// Traverse the NSData voxel array and for each ijk index, create a voxel node positioned at its spatial location
		let count = grid.count
		let voxelsIndices = UnsafePointer<MDLVoxelIndex>(voxelData.bytes)
		for i in 0..<count
		{
			let voxelIndex = voxelsIndices[i];
			
			let position:vector_float3 = grid.spatialLocationOfIndex(voxelIndex);
			
			let colorIndex = voxelPaletteIndices[Int(voxelIndex.x)][Int(voxelIndex.y)][Int(voxelIndex.z)].integerValue
			let color = paletteColors[colorIndex]
			
			// Create the voxel node and set its properties, reusing same-colored particle geometry
			
			var coloredBox:SCNBox? = coloredBoxes[color]
			if (coloredBox == nil) {
				coloredBox = (box.copy() as! SCNBox)
				
				let material = SCNMaterial()
				material.diffuse.contents = color
				coloredBox!.firstMaterial = material
				
				coloredBoxes[color] = coloredBox
			}
			
			let voxelNode = SCNNode(geometry: coloredBox)
			voxelNode.position = SCNVector3(position)
			
			// Add voxel node to the scene
			baseNode.addChildNode(voxelNode);
		}
		
		return baseNode
	}
	
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
				
				material.emission.contents = UIColor.blackColor()
				
				SCNTransaction.commit()
			}
			
			material.emission.contents = UIColor.redColor()
			
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
	
}
