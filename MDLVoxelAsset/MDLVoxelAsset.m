//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"
#import <UIKit/UIColor.h>



@implementation MDLVoxelAsset {
	MagicaVoxelVoxData *_mvvoxData;
	
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
	NSArray<NSValue*> *_voxelPaletteIndices;
	NSArray<UIColor*> *_paletteColors;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors;


- (instancetype)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self == nil)
		return nil;
	
	
	_mvvoxData = [[MagicaVoxelVoxData alloc] initWithContentsOfURL:URL];
	
	int voxelCount = _mvvoxData.voxels_count;
	MagicaVoxelVoxData_Voxel *mvvoxVoxels = _mvvoxData.voxels_array;
	
	MDLVoxelIndex *voxels = calloc(voxelCount, sizeof(MDLVoxelIndex));
	for (int vI = voxelCount - 1; vI >= 0; --vI) {
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
	
	
	NSMutableArray<NSValue*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:voxelCount];
	for (int vI = 0; vI < voxelCount; ++vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		voxelPaletteIndices[vI] = @(voxVoxel->colorIndex);
	}
	_voxelPaletteIndices = voxelPaletteIndices;
	
	
	int paletteColorCount = _mvvoxData.paletteColors_count;
	MagicaVoxelVoxData_PaletteColor *mvvoxPaletteColors = _mvvoxData.paletteColors_array;
	
	NSMutableArray<UIColor*> *paletteColors = [[NSMutableArray alloc] initWithCapacity:(paletteColorCount + 1)];
	paletteColors[0] = UIColor.clearColor;
	for (int pI = 0; pI < paletteColorCount; ++pI) {
		MagicaVoxelVoxData_PaletteColor *voxColor = &mvvoxPaletteColors[pI];
		UIColor *color = [[UIColor alloc]
			initWithRed: voxColor->r / 255.f
			green: voxColor->g / 255.f
			blue: voxColor->b / 255.f
			alpha: voxColor->a / 255.f
		];
		[(paletteColors[pI + 1] = color) release];
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
