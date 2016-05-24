//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"

#if TARGET_OS_IPHONE
	#import <UIKit/UIColor.h>
	typedef UIColor Color;
#else
	#import <AppKit/NSColor.h>
	typedef NSColor Color;
#endif



@interface MDLVoxelAsset ()

@property(nonatomic, readwrite, retain) NSURL *URL;

@end


@implementation MDLVoxelAsset {
	MagicaVoxelVoxData *_mvvoxData;
	
	MDLVoxelIndex *_voxelsRawData;
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
	NSArray<NSArray<NSArray<NSNumber*>*>*> *_voxelPaletteIndices;
	NSArray<Color*> *_paletteColors;
	
	MDLMesh *_mesh;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors;

- (NSUInteger)voxelCount {
	return _mvvoxData.voxels_count;
}

- (MDLAxisAlignedBoundingBox)boundingBox {
	MagicaVoxelVoxData_XYZDimensions mvvoxDimensions = _mvvoxData.dimensions;
	return (MDLAxisAlignedBoundingBox){
		.minBounds = { 0, 0, 0 },
		.maxBounds = { mvvoxDimensions.x, mvvoxDimensions.y, mvvoxDimensions.z },
	};
}


- (instancetype)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self == nil)
		return nil;
	
	self.URL = URL;
	
	_mvvoxData = [[MagicaVoxelVoxData alloc] initWithContentsOfURL:URL];
	MagicaVoxelVoxData_Voxel *mvvoxVoxels = _mvvoxData.voxels_array;
	MagicaVoxelVoxData_XYZDimensions mvvoxDimensions = _mvvoxData.dimensions;
	NSUInteger voxelCount = self.voxelCount;
	
	_voxelsRawData = calloc(voxelCount, sizeof(MDLVoxelIndex));
	for (int vI = (int)voxelCount - 1; vI >= 0; --vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		_voxelsRawData[vI] = (MDLVoxelIndex){ voxVoxel->x, voxVoxel->y, voxVoxel->z, 0 };
	}
	_voxelsData = [[NSData alloc] initWithBytesNoCopy:_voxelsRawData length:(voxelCount * sizeof(MDLVoxelIndex)) freeWhenDone:NO];
	
	
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
	
	NSNumber *zeroPaletteIndex = @(0);
	NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:(mvvoxDimensions.x + 1)];
	for (int xI = 0; xI <= mvvoxDimensions.x; ++xI) {
		[(voxelPaletteIndices[xI] = [[NSMutableArray alloc] initWithCapacity:(mvvoxDimensions.y + 1)]) release];
		for (int yI = 0; yI <= mvvoxDimensions.y; ++yI) {
			[(voxelPaletteIndices[xI][yI] = [[NSMutableArray alloc] initWithCapacity:(mvvoxDimensions.z + 1)]) release];
			for (int zI = 0; zI <= mvvoxDimensions.z; ++zI)
				voxelPaletteIndices[xI][yI][zI] = zeroPaletteIndex;
		}
	}
	//NSMutableArray<NSValue*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:voxelCount];
	for (int vI = 0; vI < voxelCount; ++vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		MDLVoxelIndex voxelIndex = _voxelsRawData[vI];
		voxelPaletteIndices[voxelIndex.x][voxelIndex.y][voxelIndex.z] = @(voxVoxel->colorIndex);
		//voxelPaletteIndices[vI] = @(voxVoxel->colorIndex);
	}
	_voxelPaletteIndices = voxelPaletteIndices;
	
	
	NSUInteger paletteColorCount = _mvvoxData.paletteColors_count;
	MagicaVoxelVoxData_PaletteColor *mvvoxPaletteColors = _mvvoxData.paletteColors_array;
	
	NSMutableArray<Color*> *paletteColors = [[NSMutableArray alloc] initWithCapacity:(paletteColorCount + 1)];
	paletteColors[0] = [Color clearColor];
	for (int pI = 1; pI <= paletteColorCount; ++pI) {
		MagicaVoxelVoxData_PaletteColor *voxColor = &mvvoxPaletteColors[pI - 1];
		paletteColors[pI] = [Color
			colorWithRed: voxColor->r / 255.f
			green: voxColor->g / 255.f
			blue: voxColor->b / 255.f
			alpha: voxColor->a / 255.f
		];
	}
	
	_paletteColors = paletteColors;
	
	{
		[self calculateShellLevels]
		let voxelPaletteIndices = asset.voxelPaletteIndices as Array<Array<Array<NSNumber>>>
		let paletteColors = asset.paletteColors as [Color]
		
		var coloredBoxes = Dictionary<Color, SCNGeometry>()
		
		// Create voxel grid from MDLAsset
		let grid:MDLVoxelArray = asset.voxelArray
		let voxelData = grid.voxelIndices()!;   // retrieve voxel data
		
		// Create voxel parent node
		let baseNode = SCNNode();
		baseNode.eulerAngles = SCNVector3(GLKMathDegreesToRadians(-90), 0, 0) // Z+ is up in .vox; rotate to Y+:up
		
		// Create the voxel node geometry
		let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0);
		
		// Traverse the NSData voxel array and for each ijk index, create a voxel node positioned at its spatial location
		let voxelsIndices = UnsafeBufferPointer<MDLVoxelIndex>(start: UnsafePointer<MDLVoxelIndex>(voxelData.bytes), count: grid.count)
		for voxelIndex in voxelsIndices {
			if (voxelIndex.w != 0) { continue }
			
			let position:vector_float3 = grid.spatialLocationOfIndex(voxelIndex);
			
			let colorIndex = voxelPaletteIndices[Int(voxelIndex.x)][Int(voxelIndex.y)][Int(voxelIndex.z)].integerValue
			let color = paletteColors[colorIndex]
			
			// Create the voxel node and set its properties, reusing same-colored particle geometry
			
			var coloredBox:SCNGeometry? = coloredBoxes[color]
			if (coloredBox == nil) {
				coloredBox = (box.copy() as! SCNGeometry)
				
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
		
		let boundingBox = grid.boundingBox
		let centerpoint = SCNVector3(boundingBox.minBounds + (boundingBox.maxBounds - boundingBox.minBounds) * 0.5)
		baseNode.pivot = SCNMatrix4MakeTranslation(centerpoint.x, centerpoint.y, 0.0)
		
		return (baseNode.flattenedClone(), boundingBox)
		
		_mesh = mesh;
		[self addObject:mesh];
	}
	
	return self;
}

- (void)dealloc
{
	free(_voxelsRawData);
	_voxelsRawData = NULL;
	[_voxelsData release];
	_voxelsData = nil;
	
	[_paletteColors release];
	_paletteColors = nil;
	[_voxelPaletteIndices release];
	_voxelPaletteIndices = nil;
	[_voxelArray release];
	_voxelArray = nil;
	
	[_mvvoxData release];
	_mvvoxData = nil;
	
	[super dealloc];
}


+ (BOOL)canImportFileExtension:(NSString *)extension
{
	if ([extension isEqualToString:@"vox"])
		return YES;
	
	return NO;
}


- (void)calculateShellLevels
{
	MDLVoxelIndex *voxelIndices = (MDLVoxelIndex *)_voxelsData.bytes;
	NSUInteger voxelCount = self.voxelCount;
	
	BOOL didAddShell;
	int currentShellLevel = 0;
	do {
		didAddShell = NO;
		
		for (int vI = (int)voxelCount - 1; vI >= 0; --vI) {
			MDLVoxelIndex voxel = voxelIndices[vI];
			
			// @fixme: Dangerously expensive!
			NSData *neighborVoxelsData = [_voxelArray voxelsWithinExtent:(MDLVoxelIndexExtent){
				.minimumExtent = voxel + (vector_int4){ -1, -1, -1, 0 },
				.maximumExtent = voxel + (vector_int4){ +1, +1, +1, 0 },
			}];
			
			NSUInteger neighborVoxelCount = neighborVoxelsData.length / sizeof(MDLVoxelIndex);
			MDLVoxelIndex const *neighborIndices = (MDLVoxelIndex const *)neighborVoxelsData.bytes;
			
			BOOL coveredXPos = NO, coveredXNeg = NO, coveredYPos = NO, coveredYNeg = NO, coveredZPos = NO, coveredZNeg = NO;
			for (int svI = (int)neighborVoxelCount - 1; svI >= 0; --svI)
			{
				MDLVoxelIndex neighbor = neighborIndices[svI];
				if (neighbor.w != currentShellLevel)
					continue;
				
				if (neighbor.y == voxel.y && neighbor.z == voxel.z) {
					if (neighbor.x == voxel.x + 1)
						coveredXPos = YES;
					else if (neighbor.x == voxel.x - 1)
						coveredXNeg = YES;
				}
				else if (neighbor.x == voxel.x && neighbor.z == voxel.z) {
					if (neighbor.y == voxel.y + 1)
						coveredYPos = YES;
					else if (neighbor.y == voxel.y - 1)
						coveredYNeg = YES;
				}
				else if (neighbor.x == voxel.x && neighbor.y == voxel.y) {
					if (neighbor.z == voxel.z + 1)
						coveredZPos = YES;
					else if (neighbor.z == voxel.z - 1)
						coveredZNeg = YES;
				}
			}
			
			BOOL coveredOnAllSides = coveredXPos && coveredXNeg && coveredYPos && coveredYNeg && coveredZPos && coveredZNeg;
			if (coveredOnAllSides) {
				voxel += (vector_int4){ 0, 0, 0, -1 };
				voxelIndices[vI] = voxel;
				
				didAddShell = YES;
			}
		}
		
		++currentShellLevel;
	} while (didAddShell);
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
}


@end
