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



@implementation MDLVoxelAsset {
	MagicaVoxelVoxData *_mvvoxData;
	
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
	NSArray<NSArray<NSArray<NSNumber*>*>*> *_voxelPaletteIndices;
	NSArray<Color*> *_paletteColors;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors;


- (instancetype)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self == nil)
		return nil;
	
	
	_mvvoxData = [[MagicaVoxelVoxData alloc] initWithContentsOfURL:URL];
	
	NSUInteger voxelCount = _mvvoxData.voxels_count;
	MagicaVoxelVoxData_Voxel *mvvoxVoxels = _mvvoxData.voxels_array;
	
	MDLVoxelIndex *voxels = calloc(voxelCount, sizeof(MDLVoxelIndex));
	for (int vI = (int)voxelCount - 1; vI >= 0; --vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		voxels[vI] = (MDLVoxelIndex){
			voxVoxel->x, voxVoxel->y, voxVoxel->z,
			0
		};
	}
	_voxelsData = [[NSData alloc] initWithBytesNoCopy:voxels length:(voxelCount * sizeof(MDLVoxelIndex)) freeWhenDone:YES];
	
	
	MagicaVoxelVoxData_XYZDimensions dimensions = _mvvoxData.dimensions;
	MDLAxisAlignedBoundingBox dimensions_aabbox = {
		.minBounds = { 0, 0, 0 },
		.maxBounds = { dimensions.x, dimensions.y, dimensions.z },
	};
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:dimensions_aabbox voxelExtent:1.0f];	
	
	BOOL didAddShell;
	int currentShellLevel = 0;
	do {
		didAddShell = NO;
		
		for (int vI = (int)voxelCount - 1; vI >= 0; --vI) {
			MDLVoxelIndex voxel = voxels[vI];
			
			NSData *neighborVoxelsData = [_voxelArray voxelsWithinExtent:(MDLVoxelIndexExtent){
				.minimumExtent = voxel + (vector_int4){ -1, -1, -1, 0 },
				.maximumExtent = voxel + (vector_int4){ +1, +1, +1, 0 },
			}];
			size_t neighborVoxelCount = neighborVoxelsData.length / sizeof(MDLVoxelIndex);
			MDLVoxelIndex const *neighborVoxels = (MDLVoxelIndex const *)neighborVoxelsData.bytes;
			
			BOOL coveredXPos = NO, coveredXNeg = NO, coveredYPos = NO, coveredYNeg = NO, coveredZPos = NO, coveredZNeg = NO;
			for (int svI = (int)neighborVoxelCount - 1; svI >= 0; --svI) {
				MDLVoxelIndex neighborVoxel = neighborVoxels[svI];
				if (neighborVoxel.w != currentShellLevel)
					continue;
				
				if (neighborVoxel.y == voxel.y && neighborVoxel.z == voxel.z) {
					if (neighborVoxel.x == voxel.x + 1)
						coveredXPos = YES;
					else if (neighborVoxel.x == voxel.x - 1)
						coveredXNeg = YES;
				}
				else if (neighborVoxel.x == voxel.x && neighborVoxel.z == voxel.z) {
					if (neighborVoxel.y == voxel.y + 1)
						coveredYPos = YES;
					else if (neighborVoxel.y == voxel.y - 1)
						coveredYNeg = YES;
				}
				else if (neighborVoxel.x == voxel.x && neighborVoxel.y == voxel.y) {
					if (neighborVoxel.z == voxel.z + 1)
						coveredZPos = YES;
					else if (neighborVoxel.z == voxel.z - 1)
						coveredZNeg = YES;
				}
			}
			
			BOOL coveredOnAllSides = coveredXPos && coveredXNeg && coveredYPos && coveredYNeg && coveredZPos && coveredZNeg;
			if (coveredOnAllSides) {
				voxel += (vector_int4){ 0, 0, 0, -1 };
				voxels[vI] = voxel;
				
				didAddShell = YES;
			}
		}
		
		++currentShellLevel;
	} while (didAddShell);
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:dimensions_aabbox voxelExtent:1.0f];	
	
	NSNumber *zeroPaletteIndex = @(0);
	NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:(dimensions.x + 1)];
	for (int xI = 0; xI <= dimensions.x; ++xI) {
		[(voxelPaletteIndices[xI] = [[NSMutableArray alloc] initWithCapacity:(dimensions.y + 1)]) release];
		for (int yI = 0; yI <= dimensions.y; ++yI) {
			[(voxelPaletteIndices[xI][yI] = [[NSMutableArray alloc] initWithCapacity:(dimensions.z + 1)]) release];
			for (int zI = 0; zI <= dimensions.z; ++zI)
				voxelPaletteIndices[xI][yI][zI] = zeroPaletteIndex;
		}
	}
	//NSMutableArray<NSValue*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:voxelCount];
	for (int vI = 0; vI < voxelCount; ++vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		MDLVoxelIndex voxelIndex = voxels[vI];
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
	
	return self;
}

- (void)dealloc
{
	[_paletteColors release];
	_paletteColors = nil;
	[_voxelPaletteIndices release];
	_voxelPaletteIndices = nil;
	[_voxelArray release];
	_voxelArray = nil;
	
	[_voxelsData release];
	_voxelsData = nil;
	
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

@end
