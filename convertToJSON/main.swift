// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

import Cocoa
import MDLVoxelAsset



if CommandLine.arguments.count < 2 {
	exit(0)
}

let filepath:URL = URL(fileURLWithPath: (CommandLine.arguments[1] as NSString).standardizingPath, isDirectory: false)

let voxelAsset:MDLVoxelAsset = MDLVoxelAsset(url: filepath, options: [
	kMDLVoxelAssetOptionCalculateShellLevels: false,
	kMDLVoxelAssetOptionSkipNonZeroShellMesh: false,
	kMDLVoxelAssetOptionConvertZUpToYUp: true,
])

func htmlHexCodeFromColor(_ color:NSColor) -> UInt32 {
	let rgbColor = color.usingColorSpace(NSColorSpace.sRGB)!
	let hexChannels = (
		r: UInt8(rgbColor.redComponent * 255.0),
		g: UInt8(rgbColor.greenComponent * 255.0),
		b: UInt8(rgbColor.blueComponent * 255.0)
	)
	return (UInt32(hexChannels.r) << 16) |
		(UInt32(hexChannels.g) << 8) |
		(UInt32(hexChannels.b) << 0)
}
let paletteColors:[NSColor] = voxelAsset.paletteColors
let paletteHexCodes:[UInt32] = paletteColors.map{ htmlHexCodeFromColor($0) }


func voxelModelToJsonDictEntry(voxelModel:MDLVoxelAssetModel) -> [String:Any]
{
	let voxelPaletteIndices:[[[UInt8]]] = voxelModel.voxelPaletteIndices.map{ yzArray in
		yzArray.map{ zArray in
			zArray.map { $0.uint8Value }
		}
	}
	
	let voxelHexCodes:[[[UInt32]]] = voxelPaletteIndices.map{ yzArray in
		yzArray.map{ zArray in
			zArray.map { paletteIndex in
				if paletteIndex == 0 {
					return 0
				} else {
					var hexCode = paletteHexCodes[Array<UInt32>.Index(paletteIndex)]
					if hexCode == 0x000000 { hexCode = 0x010101 }
					return hexCode
				}
			}
		}
	}
	
	let dimensions:(x:Int,y:Int,z:Int) = {
		let voxelDimensions = voxelModel.voxelDimensions
		return ( x: Int(voxelDimensions.x), y: Int(voxelDimensions.y), z: Int(voxelDimensions.z) )
	}()
	
	let voxelHexCodesFlat:[UInt32] = {
		var flat = [UInt32](repeating: 0x000000, count: Int(dimensions.x * dimensions.y * dimensions.z))
		var flatI = 0
		(0..<dimensions.z).forEach{ z in
			(0..<dimensions.y).forEach{ y in
				(0..<dimensions.x).forEach{ x in
					flat[flatI] = voxelHexCodes[x][y][z]
					flatI += 1
				}
			}
		}
		return flat
	}()
	
	return [
		"voxels": voxelHexCodesFlat,
		"dims": [ dimensions.x, dimensions.y, dimensions.z ]
	]
}


var jsonDict:[String:Any] = [
	"models": voxelAsset.models.map(voxelModelToJsonDictEntry)
]

let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])

FileHandle.standardOutput.write(jsonData)
