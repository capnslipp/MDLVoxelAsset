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



class GameViewController : ViewController
{
	@IBOutlet weak var gameView:SCNView!
	
	var _voxelFilenames:Array<String>?
	var _meshFilenames:Array<String>?
	private func loadFilenames()
	{
		let voxelFilepaths:Array<URL> = Bundle.main.urls(forResourcesWithExtension: "vox", subdirectory: nil) ?? []
		_voxelFilenames = voxelFilepaths.map { $0.lastPathComponent }
		
		let fetchResourceURLsWithExtension = {(ext:String) -> [URL] in
			Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
		}
		var meshFilepaths:Array<URL> = fetchResourceURLsWithExtension("abc")
		meshFilepaths += fetchResourceURLsWithExtension("dae")
		meshFilepaths += fetchResourceURLsWithExtension("fbx")
		meshFilepaths += fetchResourceURLsWithExtension("obj")
		meshFilepaths += fetchResourceURLsWithExtension("ply")
		meshFilepaths += fetchResourceURLsWithExtension("stl")
		_meshFilenames = meshFilepaths.map { $0.lastPathComponent }.sorted()
	}
	
	@IBOutlet weak var filenameButton:Button!
	
	#if os(iOS)
		@objc var fileSelectorPopoverSequeID:String!
		@objc var fileSelectorPopoverTableCellReuseID:String!
		var isFileSelectorPopoverActive:Bool {
			return _fileSelectorSegue != nil
		}
		
 		var _fileSelectorTable:UITableView?
		var _fileSelectorSegue:StoryboardSegue?
	#endif
	
	
	let lightOffset = SCNVector3(0, 10, 10)
	
	
	var _currentFilename:String?
	
	var _scene:SCNScene?
	var _cameraNode:SCNNode?
	var _lightNode:SCNNode?
	var _modelNode:SCNNode?
	var _modelVoxelAsset:MDLVoxelAsset?
	var _modelMeshAsset:MDLAsset?
	
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		loadFilenames()
		#if os(macOS)
			setupFilenamePopUpButton()
		#endif
		
		#if os(iOS)
			_ = {(b:UIButton, xSpacing:CGFloat) in
				let xInsetAmount = xSpacing * 0.5
				b.imageEdgeInsets = UIEdgeInsets(
					top: b.imageEdgeInsets.top,
					left: b.imageEdgeInsets.left + -xInsetAmount,
					bottom: b.imageEdgeInsets.bottom,
					right: b.imageEdgeInsets.right + xInsetAmount
				)
				b.titleEdgeInsets = UIEdgeInsets(
					top: b.titleEdgeInsets.top,
					left: b.titleEdgeInsets.left + xInsetAmount,
					bottom: b.titleEdgeInsets.bottom,
					right: b.titleEdgeInsets.right + -xInsetAmount
				)
				b.contentEdgeInsets = UIEdgeInsets(
					top: b.contentEdgeInsets.top,
					left: b.contentEdgeInsets.left + xInsetAmount,
					bottom: b.contentEdgeInsets.bottom,
					right: b.contentEdgeInsets.right + xInsetAmount
				)
			}(self.filenameButton, 6.0)
		#endif
		
		setupScene()
	}
	
	#if os(macOS)
		override func awakeFromNib() {
			self.viewDidLoad()
			
			super.awakeFromNib()
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
			l.type = .spot
			l.color = Color(hue: 60.0 / 360.0, saturation: 0.05, brightness: 1.0, alpha: 1.0)
			if #available(iOS 10.0, tvOS 10.0, macOS 10.12, *) {
				l.intensity = 1500
			}
			l.spotOuterAngle = 135
			l.spotInnerAngle = l.spotOuterAngle * 0.9
			l.castsShadow = true
			l.shadowMapSize = CGSize(width: 4096, height: 4096)
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
			l.type = .ambient
			l.color = Color(hue: 210.0 / 360.0, saturation: 0.4, brightness: 0.4, alpha: 1.0)
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
			coloredSphereNode(SCNVector3(0.0, 0.0, 0.0), .white),
			coloredSphereNode(SCNVector3(+1.0, 0.0, 0.0), .red),
			coloredSphereNode(SCNVector3(0.0, +1.0, 0.0), .green),
			coloredSphereNode(SCNVector3(0.0, 0.0, +1.0), .blue),
		]
		for node in axisSphereNodes {
			scene.rootNode.addChildNode(node)
		}
		
		
		// create and add the .vox node
		
		//try! loadVoxelModelFile(named: "ship_1")
		try! loadMeshModelFile(named: "ship_1_design")
		
		//// animate the 3d object
		//modelNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
		
		// retrieve the SCNView
		let gameView = self.gameView!
		
		// set the scene to the view
		gameView.scene = scene
		
		// allows the user to manipulate the camera
		gameView.allowsCameraControl = true
		
		// show statistics such as fps and timing information
		gameView.showsStatistics = true
		
		// configure the view
		gameView.backgroundColor = .black
		
		#if os(iOS)
			// add a tap gesture recognizer
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			gameView.addGestureRecognizer(tapGesture)
		#endif
	}
	
	func loadVoxelModelFile(named filename:String) throws
	{
		enum Error : Swift.Error {
			case assetIsEmpty
			
			func trap() { try! { throw self }() }
		}
		
		removeExistingModel()
		
		let filenameWithSuffix = filename.hasSuffix(".vox") ? filename : "\(filename).vox"
		
		let modelAsset:MDLVoxelAsset = try fetchVoxelAsset(named: filenameWithSuffix)
		
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
		
		let modelNode:SCNNode = try! {
			if (modelAsset.count == 1) {
				return SCNNode(mdlObject: modelAsset.object(at: 0))
			}
			else if (modelAsset.count > 1) {
				let baseNode = SCNNode()
				for assetSubObject:MDLObject in modelAsset.objects {
					baseNode.addChildNode(SCNNode(mdlObject: assetSubObject))
				}
				return baseNode
			}
			else {
				throw Error.assetIsEmpty
			}
		}()
		
		let glkPivot = GLKMatrix4MakeTranslation(Float(modelCenterpoint.x), 0, Float(modelCenterpoint.z))
		modelNode.pivot = SCNMatrix4(float4x4([
			float4(glkPivot.m00, glkPivot.m01, glkPivot.m02, glkPivot.m03),
			float4(glkPivot.m10, glkPivot.m11, glkPivot.m12, glkPivot.m13),
			float4(glkPivot.m20, glkPivot.m21, glkPivot.m22, glkPivot.m23),
			float4(glkPivot.m30, glkPivot.m31, glkPivot.m32, glkPivot.m33),
		]))
		
		switch filenameWithSuffix {
			case "ship_1.1.vox",
				"ship_1.2.vox":
				modelNode.eulerAngles = SCNVector3(0, GLKMathDegreesToRadians(-45), 0);
				
			default: ()
		}
		
		_modelVoxelAsset = modelAsset
		_modelNode = modelNode
		_scene!.rootNode.addChildNode(modelNode)
		
		repositionCameraBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
		repositionLightBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
		
		_currentFilename = filenameWithSuffix
		#if os(iOS)
			self.filenameButton.setTitle(filenameWithSuffix, for: [])
		#else
			let index = _voxelFilenames!.firstIndex(of: filenameWithSuffix)!
			let tag = (0 << 16) | (index & 0x0000ffff)
			(self.filenameButton as! NSPopUpButton).selectItem(withTag: tag)
		#endif
	}
	
	func loadMeshModelFile(named filename:String) throws
	{
		removeExistingModel()
		
		guard let (path, filenameWithSuffix) = {() -> (URL, String)? in
			var p:URL?
			p = Bundle.main.url(forResource: filename, withExtension: "")
			
			if p == nil {
				for fileExtension in ["abc", "dae", "fbx", "obj", "ply", "stl"] {
					if MDLAsset.canImportFileExtension(fileExtension) {
						p = Bundle.main.url(forResource: filename, withExtension: fileExtension)
					}
					if p != nil { break }
				}
			}
			
			if p == nil {
				return nil
			}
			
			return (p!, p!.lastPathComponent)
		}() else {
			throw CocoaError(.fileReadNoSuchFile)
		}
		
		let asset = MDLAsset(url: path)
		let node:SCNNode = {
			if (asset.count == 1) {
				return SCNNode(mdlObject: asset[0]!)
			}
			else if (asset.count > 1) {
				let baseNode = SCNNode()
				for assetSubObjectI in 0..<asset.count {
					baseNode.addChildNode(SCNNode(mdlObject: asset[assetSubObjectI]!))
				}
				return baseNode
			}
			else {
				return SCNNode()
				// @todo: throw
			}
		}()
		
		let centerpoint:SCNVector3 = {
			let bbox = asset.boundingBox
			return SCNVector3(bbox.minBounds + (bbox.maxBounds - bbox.minBounds) * 0.5)
		}()
		node.position = SCNVector3(-centerpoint.x, 0, -centerpoint.z);
		
		var boundingBox = asset.boundingBox
		let extents = boundingBox.maxBounds - boundingBox.minBounds
		boundingBox = {
			let centerpoint = vector_float3(centerpoint)
			let halfMaxXZExtent = max(extents.x, extents.z) * 0.5
			let halfExtents = vector_float3(halfMaxXZExtent, (extents.y * 0.5), halfMaxXZExtent)
			return MDLAxisAlignedBoundingBox(maxBounds: (centerpoint + halfExtents), minBounds: (centerpoint - halfExtents))
		}()
		
		_modelMeshAsset = asset
		_modelNode = node
		_scene!.rootNode.addChildNode(node)
		
		repositionCameraBasedOnModel(centerpoint: centerpoint, boundingBox: boundingBox)
		repositionLightBasedOnModel(centerpoint: centerpoint, boundingBox: boundingBox)
		
		_currentFilename = filenameWithSuffix
		#if os(iOS)
			self.filenameButton.setTitle(filenameWithSuffix, for: [])
		#else
			let index = _meshFilenames!.firstIndex(of: filenameWithSuffix)!
			let tag = (1 << 16) | (index & 0x0000ffff)
			(self.filenameButton as! NSPopUpButton).selectItem(withTag: tag)
		#endif
	}
	
	func removeExistingModel()
	{
		if _modelNode != nil {
			_modelNode!.removeFromParentNode()
			_modelNode = nil
		}
		if _modelVoxelAsset != nil {
			_modelVoxelAsset = nil
		}
		if _modelMeshAsset != nil {
			_modelMeshAsset = nil
		}
		
		(self.gameView!.layer as CALayer?)?.setNeedsDisplay()
		(self.gameView!.layer as CALayer?)?.displayIfNeeded()
	}
	
	func repositionCameraBasedOnModel(centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
	{
		_cameraNode!.position = SCNVector3(
			0.0,
			Float(centerpoint.y),
			bbox.maxBounds.z + (bbox.maxBounds.z - bbox.minBounds.z) * 0.5 + 15
		)
	}
	
	func repositionLightBasedOnModel(centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
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
			var p = Bundle.main.path(forResource: name, ofType: "")
			if p == nil {
				p = Bundle.main.path(forResource: name, ofType: "vox")
			}
			return p
		}() else {
			throw CocoaError(.fileReadNoSuchFile)
		}
		
		let asset = MDLVoxelAsset(url: URL(fileURLWithPath: path), options:[
			kMDLVoxelAssetOptionCalculateShellLevels: false,
			kMDLVoxelAssetOptionSkipNonZeroShellMesh: false,
			kMDLVoxelAssetOptionConvertZUpToYUp: true,
			kMDLVoxelAssetOptionMeshGenerationMode: MDLVoxelAssetMeshGenerationMode.greedyQuad.rawValue,
			kMDLVoxelAssetOptionSkipMeshFaceDirections: ([ .xNeg, .yNeg, .zNeg ] as MDLVoxelAssetSkipMeshFaceDirections).rawValue,
		])
		return asset
	}
	
	#if os(iOS)
		@IBAction func handleTap(_ gestureRecognize:UIGestureRecognizer) {
			// retrieve the SCNView
			let scnView = self.gameView!
			
			// check what nodes are tapped
			let p = gestureRecognize.location(in: scnView)
			let hitResults = scnView.hitTest(p, options: nil)
			// check that we clicked on at least one object
			if hitResults.count > 0 {
				// retrieved the first clicked object
				let result: AnyObject! = hitResults[0]
				
				// get its material
				if let material = result.node!.geometry!.firstMaterial {
					// highlight it
					SCNTransaction.begin()
					SCNTransaction.animationDuration = 0.5
					
					// on completion - unhighlight
					SCNTransaction.completionBlock = {
						SCNTransaction.begin()
						SCNTransaction.animationDuration = 0.5
						
						material.emission.contents = Color.black
						
						SCNTransaction.commit()
					}
					
					material.emission.contents = Color.red
					
					SCNTransaction.commit()
				}
			}
		}
		
		override var shouldAutorotate:Bool {
			return true
		}
		
		override var prefersStatusBarHidden:Bool {
			return true
		}
		
		override var supportedInterfaceOrientations:UIInterfaceOrientationMask {
			if UIDevice.current.userInterfaceIdiom == .phone {
				return .allButUpsideDown
			} else {
				return .all
			}
		}
		
		override func didReceiveMemoryWarning() {
			super.didReceiveMemoryWarning()
			// Release any cached data, images, etc that aren't in use.
		}
		
		@IBAction func openFileSelector(_ sender:Button)
		{
			let canPerformSeque = self.shouldPerformSegue(withIdentifier: self.fileSelectorPopoverSequeID, sender: self)
			guard canPerformSeque else { return }
			
			self.performSegue(withIdentifier: self.fileSelectorPopoverSequeID, sender: self)
		}
		
		override func shouldPerformSegue(withIdentifier identifier:String, sender:Any?) -> Bool
		{
			switch identifier {
				case self.fileSelectorPopoverSequeID:
					return true
					
				default:
					return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
			}
		}
		
		override func prepare(for segue:StoryboardSegue, sender:Any?)
		{
			guard let identifier = segue.identifier else { return }
			switch identifier {
				case self.fileSelectorPopoverSequeID:
					let tableController = segue.destination as! UITableViewController
					
					let tableView:UITableView = tableController.tableView
					tableView.dataSource = self
					tableView.delegate = self
					_fileSelectorTable = tableView
					
					let popoverController = segue.destination.popoverPresentationController!
					
					popoverController.sourceRect = popoverController.sourceView!.frame
					_fileSelectorSegue = segue
				
				default:
					return
			}
		}
	#endif
	
	#if os(macOS)
		private func setupFilenamePopUpButton()
		{
			let popUpButton = self.filenameButton as! NSPopUpButton
			
			popUpButton.removeAllItems()
			popUpButton.autoenablesItems = false
			
			popUpButton.addItem(withTitle: "Voxel Models")
			popUpButton.lastItem!.isEnabled = false
			popUpButton.lastItem!.tag = -1
			
			_voxelFilenames!.enumerated().forEach{ index, filename in
				popUpButton.addItem(withTitle: filename)
				popUpButton.lastItem!.tag = (0 << 16) | (index & 0x0000ffff)
			}
			
			popUpButton.addItem(withTitle: "Mesh Models")
			popUpButton.lastItem!.isEnabled = false
			popUpButton.lastItem!.tag = -1
			
			_meshFilenames!.enumerated().forEach{ index, filename in
				popUpButton.addItem(withTitle: filename)
				popUpButton.lastItem!.tag = (1 << 16) | (index & 0x0000ffff)
			}
		}
		
		@IBAction func selectFilename(_ sender:NSPopUpButton)
		{
			let tag = sender.selectedItem!.tag
			let section = (tag & 0xffff0000) >> 16
			let index = (tag & 0x0000ffff)
			
			let filename:String? = {
				switch section {
					case 0: return _voxelFilenames![index]
					case 1: return _meshFilenames![index]
					
					default: return nil
				}
			}()
			
			switch section {
				case 0: try! self.loadVoxelModelFile(named: filename!)
				case 1: try! self.loadMeshModelFile(named: filename!)
				
				default: ()
			}
		}
	#endif
}


#if os(iOS)
	extension GameViewController : UITableViewDataSource, UITableViewDelegate
	{
		func numberOfSections(in tableView:UITableView) -> Int
		{
			if tableView == _fileSelectorTable! {
				return 2
			}
			else {
				return 0
			}
		}
		
		func tableView(_ tableView:UITableView, titleForHeaderInSection section:Int) -> String?
		{
			if tableView == _fileSelectorTable! {
				switch section {
					case 0:
						return "Voxel Models"
					case 1:
						return "Mesh Models"
					
					default:
						return nil
				}
			}
			else {
				return nil
			}
		}
		
		func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int
		{
			if tableView == _fileSelectorTable! {
				switch section {
					case 0:
						return _voxelFilenames!.count
					case 1:
						return _meshFilenames!.count
					
					default:
						return 0
				}
			}
			else {
				return 0
			}
		}
		
		func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell
		{
			if tableView == _fileSelectorTable! {
				let filename:String = {
					switch indexPath.section {
						case 0:
							return _voxelFilenames![indexPath.item]
						case 1:
							return _meshFilenames![indexPath.item]
						
						default:
							return ""
					}
				}()
				
				let tableCell = tableView.dequeueReusableCell(withIdentifier: self.fileSelectorPopoverTableCellReuseID)!
				tableCell.textLabel!.text = filename
				
				return tableCell
			}
			else {
				return UITableViewCell()
				// @todo: Throw an error, somehow (`@objc` disallows `throws`).
			}
		}
		
		func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath)
		{
			if tableView == _fileSelectorTable! {
				let filename:String = {
					switch indexPath.section {
						case 0:
							return _voxelFilenames![indexPath.item]
						case 1:
							return _meshFilenames![indexPath.item]
						
						default:
							return ""
					}
				}()
				
				_fileSelectorSegue!.destination.dismiss(animated: true, completion: nil)
				
				_fileSelectorSegue = nil
				_fileSelectorTable = nil
				
				switch indexPath.section {
					case 0:
						try! self.loadVoxelModelFile(named: filename)
					case 1:
						try! self.loadMeshModelFile(named: filename)
					
					default: ()
				}
			}
		}
	}
#endif
