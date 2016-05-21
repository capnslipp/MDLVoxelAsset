//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"



@implementation MDLVoxelAsset {
	MagicaVoxelVoxData *_mvvoxData;
	
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
}

@synthesize voxelArray=_voxelArray;


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
	_voxelsData = [[NSData alloc] initWithBytesNoCopy:voxels length:(voxelCount * sizeof(MDLVoxelIndex))];
	
	MagicaVoxelVoxData_XYZDimensions dimensions = _mvvoxData.dimensions;
	MDLAxisAlignedBoundingBox dimensions_aabbox = {
		.minBounds = { 0, 0, 0 },
		.maxBounds = { dimensions.x, dimensions.y, dimensions.z },
	};
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:dimensions_aabbox voxelExtent:1.0f];
	
	return self;
}

- (void)dealloc
{
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
