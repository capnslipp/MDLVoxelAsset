// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

import QuartzCore
import MDLVoxelAsset
import SceneKit
import SceneKit.ModelIO


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



class GameViewController : NSViewController
{
	@IBOutlet weak var gameView:SCNView!
	
	var _sceneFilename:String = "example_char_simple.scn"
	
	
	let lightOffset = SCNVector3(0, -10, 10)
	
	
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
		
		setupScene()
	}
	
	func setupScene()
	{
		// create a new scene
		let scene = SCNScene()
		scene.setAttribute(SCNVector3(0, 0, 1), forKey: SCNScene.Attribute.upAxis.rawValue)
		_scene = scene
		
		
		// create and add a camera to the scene
		
		let cameraNode = SCNNode()
		cameraNode.camera = {
			let c = SCNCamera()
			c.automaticallyAdjustsZRange = true
			return c
		}()
		cameraNode.eulerAngles = SCNVector3(GLKMathDegreesToRadians(90), 0, 0)
		cameraNode.name = "\(Self.self) Camera"
		scene.rootNode.addChildNode(cameraNode)
		_cameraNode = cameraNode
		
		
		// floor
		
		let floorNode = SCNNode(geometry: {
			let f = SCNFloor()
			f.reflectivity = 0
			return f
		}())
		floorNode.name = "\(Self.self) Floor"
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
		lightNode.name = "\(Self.self) Spot Light"
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
		ambientLightNode.name = "\(Self.self) Ambient Light"
		scene.rootNode.addChildNode(ambientLightNode)
		
		
		// axis widget
		
		let axisSphere = SCNSphere(radius: 0.25)
		let coloredSphereNode = {(position:SCNVector3, color:Color, shortName:String) -> SCNNode in
			let s = (axisSphere.copy() as! SCNSphere)
			s.firstMaterial = {
				let material = SCNMaterial()
				material.diffuse.contents = color
				return material
			}()
			let n = SCNNode(geometry: s)
			n.name = "\(Self.self) Axis \(shortName)"
			n.position = position
			return n
		}
		let axisSphereNodes = [
			coloredSphereNode(SCNVector3(0.0, 0.0, 0.0), .white, "Origin"),
			coloredSphereNode(SCNVector3(+1.0, 0.0, 0.0), .red, "X+"),
			coloredSphereNode(SCNVector3(0.0, +1.0, 0.0), .green, "Y+"),
			coloredSphereNode(SCNVector3(0.0, 0.0, +1.0), .blue, "Z+"),
		]
		for node in axisSphereNodes {
			scene.rootNode.addChildNode(node)
		}
		
		
		// create and add the .vox node
		
		try! loadSceneFile(named: _sceneFilename)
		
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
		
		gameView.debugOptions.insert(.showWireframe)
		gameView.debugOptions.insert(.showBoundingBoxes)
		
		#if os(iOS)
			// add a tap gesture recognizer
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			gameView.addGestureRecognizer(tapGesture)
		#endif
	}
	
	
	func loadSceneFile(named filename:String) throws
	{
		enum Error : Swift.Error {
			case assetIsEmpty
			
			func trap() { try! { throw self }() }
		}
		
		_currentFilename = filename
		
		let scnScene = SCNScene(named: filename)!
		
		let modelScene = SCNScene()
		modelScene.rootNode.addChildNode(scnScene.rootNode.childNode(withName: "model", recursively: true)!)
		let voxelizedAsset = MDLVoxelAsset(
			scnScene: modelScene,
			voxelizationParams: [
				kMDLVoxelAssetVoxelizationParamsModelMappings : [
					"noses",
					"head",
					"jaws",
					"ears",
					"brows",
				],
			],
			options: [
				kMDLVoxelAssetOptionCalculateShellLevels: false,
				kMDLVoxelAssetOptionSkipNonZeroShellMesh: false,
				kMDLVoxelAssetOptionConvertZUpToYUp: false,
				kMDLVoxelAssetOptionMeshGenerationMode: MDLVoxelAssetMeshGenerationMode.greedyQuad.rawValue,
				//kMDLVoxelAssetOptionSkipMeshFaceDirections: ([ .xNeg, .yNeg, .zNeg ] as MDLVoxelAssetSkipMeshFaceDirections).rawValue,
			],
			dimensions: MDLVoxelAsset_VoxelDimensions(x: 14, y: 19, z: 13),
			palette: [ NSColor.red, NSColor.green, NSColor.blue, NSColor.black, NSColor.white ]
		)
		
		let modelCenterpoint:SCNVector3 = {
			let bbox = voxelizedAsset.boundingBox
			return SCNVector3(bbox.minBounds + (bbox.maxBounds - bbox.minBounds) * 0.5)
		}()
		
		var modelBoundingBox = voxelizedAsset.boundingBox
		let modelExtents = modelBoundingBox.maxBounds - modelBoundingBox.minBounds
		modelBoundingBox = {
			let centerpoint = vector_float3(modelCenterpoint)
			let halfMaxXZExtent = max(modelExtents.x, modelExtents.z) * 0.5
			let halfExtents = vector_float3(halfMaxXZExtent, (modelExtents.y * 0.5), halfMaxXZExtent)
			return MDLAxisAlignedBoundingBox(maxBounds: (centerpoint + halfExtents), minBounds: (centerpoint - halfExtents))
		}()
		
		let modelNode:SCNNode = try! {
			if (voxelizedAsset.count == 1) {
				let node = SCNNode(mdlObject: voxelizedAsset.object(at: 0))
				node.name = "MDLVoxelAsset"
				return node
			}
			else if (voxelizedAsset.count > 1) {
				let baseNode = SCNNode()
				baseNode.name = "MDLVoxelAsset"
				for assetSubObject:MDLObject in voxelizedAsset.objects {
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
			simd_float4(glkPivot.m00, glkPivot.m01, glkPivot.m02, glkPivot.m03),
			simd_float4(glkPivot.m10, glkPivot.m11, glkPivot.m12, glkPivot.m13),
			simd_float4(glkPivot.m20, glkPivot.m21, glkPivot.m22, glkPivot.m23),
			simd_float4(glkPivot.m30, glkPivot.m31, glkPivot.m32, glkPivot.m33),
		]))
		
		_modelVoxelAsset = voxelizedAsset
		_modelNode = modelNode
		_scene!.rootNode.addChildNode(modelNode)
		
		repositionCameraBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
		repositionLightBasedOnModel(centerpoint: modelCenterpoint, boundingBox: modelBoundingBox)
	}
	
	func repositionCameraBasedOnModel(centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
	{
		let cameraNode = _cameraNode!
		
		cameraNode.position = SCNVector3(
			0.0,
			bbox.maxBounds.y + (bbox.maxBounds.y - bbox.minBounds.y) * 0.5 - 40,
			Float(centerpoint.z) + 20
		)
		
		cameraNode.constraints = [ SCNLookAtConstraint(target: _modelNode!) ]
	}
	
	func repositionLightBasedOnModel(centerpoint:SCNVector3, boundingBox bbox:MDLAxisAlignedBoundingBox)
	{
		let extents = (bbox.maxBounds - bbox.minBounds)
		
		let lightNode = _lightNode!
		
		lightNode.position = {
			return SCNVector3(
				Float(bbox.maxBounds.x) + Float(lightOffset.x),
				Float(bbox.minBounds.y) + Float(lightOffset.y),
				Float(bbox.maxBounds.z) + Float(lightOffset.z)
			)
		}()
		
		lightNode.constraints = [ SCNLookAtConstraint(target: _modelNode!) ]
		
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
}

