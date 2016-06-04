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
	typealias Button = UIButton
	typealias StoryboardSegue = UIStoryboardSegue
#else
	import AppKit
	typealias Color = NSColor
	typealias ViewController = NSViewController
	typealias Button = NSButton
	typealias StoryboardSegue = NSStoryboardSegue
#endif



class GameViewController : ViewController, UITableViewDataSource, UITableViewDelegate
{
	@IBOutlet weak var gameView:SCNView!
	
	var _filenames:Array<String>?
	@IBOutlet weak var filenameButton:UIButton!
	
	var fileSelectorPopoverSequeID:String?
	var fileSelectorPopoverTableCellReuseID:String?
	var isFileSelectorPopoverActive:Bool {
		return _fileSelectorSegue != nil
	}
	
	var _fileSelectorTable:UITableView?
	var _fileSelectorSegue:StoryboardSegue?
	
	
	let lightOffset = SCNVector3(0, 10, 10)
	
	
	var _currentFilename:String?
	
	var _scene:SCNScene?
	var _cameraNode:SCNNode?
	var _lightNode:SCNNode?
	var _modelNode:SCNNode?
	var _modelAsset:MDLVoxelAsset?
	
	
	#if os(iOS)
		override func viewDidLoad() {
			super.awakeFromNib()
			
			setupScene()
			
			_ = {(b:UIButton, xSpacing:CGFloat) in
				let xInsetAmount = xSpacing * 0.5
				b.imageEdgeInsets = UIEdgeInsets(top: b.imageEdgeInsets.top, left: -xInsetAmount, bottom: b.imageEdgeInsets.bottom, right: xInsetAmount)
				b.titleEdgeInsets = UIEdgeInsets(top: b.titleEdgeInsets.top, left: xInsetAmount, bottom: b.titleEdgeInsets.bottom, right: -xInsetAmount)
				b.contentEdgeInsets = UIEdgeInsets(top: b.contentEdgeInsets.top, left: xInsetAmount, bottom: b.contentEdgeInsets.bottom, right: xInsetAmount)
			}(self.filenameButton, 6.0)
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
		_scene = scene
		
		
		// create and add a camera to the scene
		
		let cameraNode = SCNNode()
		cameraNode.camera = {
			let c = SCNCamera()
			c.automaticallyAdjustsZRange = true
			return c
		}()
		cameraNode.eulerAngles = SCNVector3(0, 0, 0)
		scene.rootNode.addChildNode(cameraNode)
		_cameraNode = cameraNode
		
		
		// floor
		
		let floorNode = SCNNode(geometry: {
			let f = SCNFloor()
			f.reflectivity = 0
			return f
		}())
		scene.rootNode.addChildNode(floorNode)
		
		
		// create and add a light to the scene
		
		let lightNode = SCNNode()
		lightNode.light = {
			let l = SCNLight()
			l.type = SCNLightTypeSpot
			l.color = Color(hue: 60.0 / 360.0, saturation: 0.2, brightness: 1.0, alpha: 1.0)
			l.spotOuterAngle = 135
			l.spotInnerAngle = l.spotOuterAngle * 0.9
			l.castsShadow = true
			return l
		}()
		if lightNode.constraints == nil {
			lightNode.constraints = [SCNConstraint]()
		}
		scene.rootNode.addChildNode(lightNode)
		_lightNode = lightNode
		
		
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
		
		
		// create and add the .vox node
		
		loadModelFile(named: "ship_1.2")
		
		
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
	
	func loadModelFile(named filename:String)
	{
		let filenameWithSuffix = filename.hasSuffix(".vox") ? filename : "\(filename).vox"
		
		if _modelNode != nil {
			_modelNode!.removeFromParentNode()
			_modelNode = nil
		}
		if _modelAsset != nil {
			_modelAsset = nil
		}
		
		self.gameView!.layer.setNeedsDisplay()
		self.gameView!.layer.displayIfNeeded()
		
		let modelAsset:MDLVoxelAsset = try! fetchVoxelAsset(named: filenameWithSuffix)
		
		let modelCenterpoint:SCNVector3 = {
			let bbox = modelAsset.boundingBox
			return SCNVector3(bbox.minBounds + (bbox.maxBounds - bbox.minBounds) * 0.5)
		}()
		
		var modelBoundingBox = modelAsset.boundingBox
		let modelExtents = modelBoundingBox.maxBounds - modelBoundingBox.minBounds
		modelBoundingBox = {
			let centerpoint = vector_float3(modelCenterpoint)
			let halfMaxXZExtent = max(modelExtents.x, modelExtents.z) * 0.5
			let halfExtents = vector_float3(halfMaxXZExtent, (modelExtents.y * 0.5), halfMaxXZExtent)
			return MDLAxisAlignedBoundingBox(maxBounds: (centerpoint + halfExtents), minBounds: (centerpoint - halfExtents))
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
		modelNode.position = SCNVector3(-modelCenterpoint.x, 0, -modelCenterpoint.z);
		
		_modelAsset = modelAsset
		_modelNode = modelNode
		_scene!.rootNode.addChildNode(modelNode)
		
		repositionCameraBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
		repositionLightBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
		
		_currentFilename = filenameWithSuffix
		
		self.filenameButton.setTitle(filenameWithSuffix, forState: .Normal)
	}
	
	func repositionCameraBasedOnModel(centerpoint centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
	{
		_cameraNode!.position = SCNVector3(
			0.0,
			Float(centerpoint.y),
			bbox.maxBounds.z + (bbox.maxBounds.z - bbox.minBounds.z) * 0.5 + 15
		)
	}
	
	func repositionLightBasedOnModel(centerpoint centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
	{
		let extents = (bbox.maxBounds - bbox.minBounds)
		
		let lightNode = _lightNode!
		
		lightNode.position = {
			return SCNVector3(
				Float(bbox.maxBounds.x) + Float(lightOffset.x),
				Float(bbox.maxBounds.y) + Float(lightOffset.y),
				Float(bbox.maxBounds.z) + Float(lightOffset.z)
			)
		}()
		
		lightNode.constraints!.append(SCNLookAtConstraint(target: _modelNode!))
		
		let light:SCNLight = lightNode.light!
		light.zNear = sqrt(
			pow(CGFloat(lightOffset.x), 2.0) +
			pow(CGFloat(lightOffset.y), 2.0) +
			pow(CGFloat(lightOffset.z), 2.0)
		) * 2
		light.zFar = sqrt(
			pow(CGFloat(extents.x) + CGFloat(lightOffset.x), 2.0) +
			pow(CGFloat(extents.y) + CGFloat(lightOffset.y), 2.0) +
			pow(CGFloat(extents.z) + CGFloat(lightOffset.z), 2.0)
		) * 2
	}
	
	func fetchVoxelAsset(named name:String) throws -> MDLVoxelAsset
	{
		guard let path:String = {
			var p = NSBundle.mainBundle().pathForResource(name, ofType:"")
			if p == nil {
				p = NSBundle.mainBundle().pathForResource(name, ofType:"vox")
			}
			return p
		}()
		else {
			throw NSCocoaError.FileReadNoSuchFileError
		}
		
		let asset = MDLVoxelAsset(URL: NSURL(fileURLWithPath: path), options:[
			kMDLVoxelAssetOptionCalculateShellLevels: false,
			kMDLVoxelAssetOptionSkipNonZeroShellMesh: false,
			kMDLVoxelAssetOptionConvertZUpToYUp: true,
		])
		return asset
	}
	
	#if os(iOS)
		func handleTap(gestureRecognize: UIGestureRecognizer) {
			// retrieve the SCNView
			let scnView = self.gameView
			
			// check what nodes are tapped
			let p = gestureRecognize.locationInView(scnView)
			let hitResults = scnView.hitTest(p, options: nil)
			// check that we clicked on at least one object
			if hitResults.count > 0 {
				// retrieved the first clicked object
				let result: AnyObject! = hitResults[0]
				
				// get its material
				if let material = result.node!.geometry!.firstMaterial {
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
	
	
	@IBAction func openFileSelector(sender:Button)
	{
		let filepaths:Array<String> = NSBundle.mainBundle().pathsForResourcesOfType("vox", inDirectory: nil)
		_filenames = filepaths.map { NSURL(string: $0)!.lastPathComponent! }
		
		let canPerformSeque = self.shouldPerformSegueWithIdentifier(self.fileSelectorPopoverSequeID!, sender: self)
		guard canPerformSeque else { return }
		
		self.performSegueWithIdentifier(self.fileSelectorPopoverSequeID!, sender: self)
	}
	
	override func shouldPerformSegueWithIdentifier(identifier:String, sender:AnyObject?) -> Bool
	{
		switch identifier {
			case self.fileSelectorPopoverSequeID!:
				return true
				
			default:
				return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
		}
	}
	
	override func prepareForSegue(segue:StoryboardSegue, sender:AnyObject?)
	{
		guard let identifier = segue.identifier else { return }
		switch identifier {
			case self.fileSelectorPopoverSequeID!:
				let tableController = segue.destinationViewController as! UITableViewController
				
				let tableView:UITableView = tableController.tableView
				tableView.dataSource = self
				tableView.delegate = self
				_fileSelectorTable = tableView
				
				let popoverController = segue.destinationViewController.popoverPresentationController!
				
				popoverController.sourceRect = popoverController.sourceView!.frame
				_fileSelectorSegue = segue
			
			default:
				return
		}
	}
	
	func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int
	{
		if tableView == _fileSelectorTable! {
			switch section {
				case 0:
					return _filenames!.count
				
				default:
					return 0
			}
		}
		else {
			return 0
		}
	}
	
	func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell
	{
		if tableView == _fileSelectorTable! {
			let filename = _filenames![indexPath.item]
			
			let tableCell = tableView.dequeueReusableCellWithIdentifier(self.fileSelectorPopoverTableCellReuseID!)!
			tableCell.textLabel!.text = filename
			
			return tableCell
		}
		else {
			return UITableViewCell()
			// @todo: Throw an error, somehow (`@objc` disallows `throws`).
		}
	}
	
	func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath)
	{
		if tableView == _fileSelectorTable! {
			let filename = _filenames![indexPath.item]
			
			_fileSelectorSegue!.destinationViewController.dismissViewControllerAnimated(true, completion: nil)
			
			_fileSelectorSegue = nil
			_fileSelectorTable = nil
			
			self.loadModelFile(named: filename)
		}
	}
	
	
}
