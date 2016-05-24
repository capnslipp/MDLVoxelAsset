//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"

#import <GLKit/GLKMathUtils.h>
#import <SceneKit/ModelIO.h>
#import <SceneKit/SceneKit_simd.h>
#import <SceneKit/SCNGeometry.h>
#import <SceneKit/SCNMaterial.h>
#import <SceneKit/SCNMaterialProperty.h>
#import <SceneKit/SCNNode.h>
#import <SceneKit/SCNParametricGeometry.h>

#if TARGET_OS_IPHONE
	#import <UIKit/UIColor.h>
	typedef UIColor Color;
#else
	#import <AppKit/NSColor.h>
	typedef NSColor Color;
#endif



NSString *const kMDLVoxelAssetOptionCalculateShellLevels = @"MDLVoxelAssetOptionCalculateShellLevels";
NSString *const kMDLVoxelAssetOptionSkipNonZeroShellMesh = @"MDLVoxelAssetOptionSkipNonZeroShellMesh";
NSString *const kMDLVoxelAssetOptionMeshGenerationMode = @"MDLVoxelAssetOptionMeshGenerationMode";
NSString *const kMDLVoxelAssetOptionMeshGenerationFlattening = @"MDLVoxelAssetOptionMeshGenerationFlattening";
NSString *const kMDLVoxelAssetOptionVoxelMesh = @"MDLVoxelAssetOptionVoxelMesh";


typedef struct _OptionsValues {
	BOOL calculateShellLevels : 1;
	BOOL skipNonZeroShellMesh : 1;
	BOOL meshGenerationFlattening : 1;
	
	MDLVoxelAssetMeshGenerationMode meshGenerationMode;
	id voxelMesh;
} OptionsValues;



@interface MDLVoxelAsset ()

@property(nonatomic, readwrite, retain) NSURL *URL;

@end


@implementation MDLVoxelAsset {
	OptionsValues _options;
	
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


- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString*,id> *)options_dict
{
	self = [super init];
	if (self == nil)
		return nil;
	
	[self parseOptions:options_dict];
	
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
	
	[self generateMeshWithSceneKit];
	
	return self;
}

- (void)parseOptions:(NSDictionary<NSString*,id> *)options_dict
{
	BOOL (^parseBool)(NSString *, BOOL) = ^BOOL(NSString *optionKey, BOOL defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && [dictValue isKindOfClass:NSNumber.class];
		return isNonNilAndOfCorrectType ?
			((NSNumber *)dictValue).boolValue :
			defaultValue;
	};
	NSUInteger (^parseNSUIntegerEnum)(NSString *, NSUInteger) = ^(NSString *optionKey, NSUInteger defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && [dictValue isKindOfClass:NSNumber.class];
		return isNonNilAndOfCorrectType ?
			((NSNumber *)dictValue).unsignedIntegerValue :
			defaultValue;
	};
	id (^parseSCNGeometryOrMDLMesh)(NSString *, id) = ^(NSString *optionKey, id defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && ([dictValue isKindOfClass:SCNGeometry.class] || [dictValue isKindOfClass:MDLMesh.class]);
		return isNonNilAndOfCorrectType ?
			dictValue :
			defaultValue;
	};
	
	_options.calculateShellLevels = parseBool(kMDLVoxelAssetOptionCalculateShellLevels, NO);
	
	if (_options.calculateShellLevels)
		_options.skipNonZeroShellMesh = parseBool(kMDLVoxelAssetOptionSkipNonZeroShellMesh, NO);
	else
		_options.skipNonZeroShellMesh = NO;
	
	_options.meshGenerationMode = parseNSUIntegerEnum(kMDLVoxelAssetOptionMeshGenerationMode, MDLVoxelAssetMeshGenerationModeSceneKit);
	
	if (_options.meshGenerationMode != MDLVoxelAssetMeshGenerationModeSkip) {
		_options.meshGenerationFlattening = parseBool(kMDLVoxelAssetOptionMeshGenerationFlattening, YES);
		
		_options.voxelMesh = [parseSCNGeometryOrMDLMesh(kMDLVoxelAssetOptionVoxelMesh, 
			[SCNBox boxWithWidth:1 height:1 length:1 chamferRadius:0.0]
		) retain];
	}
	else {
		_options.meshGenerationFlattening = NO;
		_options.voxelMesh = nil;
	}
}

- (void)generateMeshWithSceneKit
{
	if (_options.meshGenerationMode == MDLVoxelAssetMeshGenerationModeSceneKit)
	{
		if (_options.calculateShellLevels)
			[self calculateShellLevels];
		
		// @fixme: Currently overallocates (256, instead of the number of colors used), but it's not a gross overallocation and better than underallocating.
		NSMutableDictionary<Color*,SCNGeometry*> *coloredBoxes = [[NSMutableDictionary alloc] initWithCapacity:_paletteColors.count];
		
		// Create voxel parent node
		SCNNode *baseNode = [SCNNode new];
		baseNode.eulerAngles = (SCNVector3){ GLKMathDegreesToRadians(-90), 0, 0 }; // Z+ is up in .vox; rotate to Y+:up
		
		// Create the voxel node geometry
		SCNGeometry *voxelGeo;
		if ([_options.voxelMesh isKindOfClass:SCNGeometry.class])
			voxelGeo = _options.voxelMesh;
		else if ([_options.voxelMesh isKindOfClass:MDLMesh.class])
			voxelGeo = [SCNGeometry geometryWithMDLMesh:_options.voxelMesh];
		else
			@throw [NSException exceptionWithName: NSInvalidArgumentException
					reason: [NSString stringWithFormat:@"Unexpected _options.voxelMesh type %@.", [_options.voxelMesh class]]
					userInfo: nil
				];
		
		// Traverse the NSData voxel array and for each ijk index, create a voxel node positioned at its spatial location
		NSUInteger voxelCount = self.voxelCount;
		for (int vI = 0; vI < voxelCount; ++vI) {
			MDLVoxelIndex voxelIndex = _voxelsRawData[vI];
			
			if (_options.skipNonZeroShellMesh) {
				if (voxelIndex.w != 0)
					continue;
			}
			
			int colorIndex = _voxelPaletteIndices[voxelIndex.x][voxelIndex.y][voxelIndex.z].intValue;
			Color *color = _paletteColors[colorIndex];
			
			// Create the voxel node and set its properties, reusing same-colored particle geometry
			
			SCNGeometry *coloredBox = coloredBoxes[color];
			if (coloredBox == nil) {
				coloredBox = [voxelGeo copy];
				
				SCNMaterial *material = [SCNMaterial new];
				material.diffuse.contents = color;
				[(coloredBox.firstMaterial = material) release];
				
				[(coloredBoxes[color] = coloredBox) release];
			}
			
			SCNNode *voxelNode = [SCNNode nodeWithGeometry:coloredBox];
			vector_float3 position = [_voxelArray spatialLocationOfIndex:voxelIndex];
			voxelNode.position = SCNVector3FromFloat3(position);
			
			// Add voxel node to the scene
			[baseNode addChildNode:voxelNode];
		}
		
		MDLAxisAlignedBoundingBox bbox = _voxelArray.boundingBox;
		SCNVector3 centerpoint = SCNVector3FromFloat3(bbox.minBounds + (bbox.maxBounds - bbox.minBounds) * 0.5);
		baseNode.pivot = SCNMatrix4MakeTranslation(centerpoint.x, centerpoint.y, 0.0);
		
		if (_options.meshGenerationFlattening) {
			baseNode = [baseNode flattenedClone];
			// @TODO: Pre-empt geomertySources/geomertyElements population?
		}
		
		MDLMesh *mesh = [MDLMesh meshWithSCNGeometry:baseNode.geometry];
		
		[baseNode release];
		
		_mesh = mesh;
		[self addObject:mesh];
	}
}

- (void)dealloc
{
	[_mesh release];
	_mesh = nil;
	
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
	
	[_options.voxelMesh release];
	_options.voxelMesh = nil;
	
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

- (MDLObject *)objectAtIndex:(NSUInteger)index {
	return self.objects[index];
}
- (MDLObject *)objectAtIndexedSubscript:(NSUInteger)index {
	return self.objects[index];
}

- (NSUInteger)count {
	return self.objects.count;
}


@end
