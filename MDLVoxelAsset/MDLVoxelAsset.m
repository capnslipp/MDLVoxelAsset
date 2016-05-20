//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"



@implementation MDLVoxelAsset {
	MagicaVoxelVoxData *_data;
	MDLVoxelArray *_voxelArray;
}

- (instancetype)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [[MagicaVoxelVoxData alloc] initWithContentsOfURL:URL];
	
	MagicaVoxelVoxData_Voxel *voxVoxels = _data.voxels_array;
	int voxelCount = _data.voxels_count;
	
	MDLVoxelIndex *mdlVoxels = calloc(_data.voxels_count, sizeof(MDLVoxelIndex));
	for (int voxelI = voxelCount - 1; voxelI >= 0; --voxelI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &voxVoxels[voxelI];
		mdlVoxels[voxelI] = (MDLVoxelIndex){
			voxVoxel->x, voxVoxel->y, voxVoxel->z,
			0
		};
	}
	
	MagicaVoxelVoxData_XYZDimensions dimensions = _data.dimensions;
	_voxelArray = [[MDLVoxelArray alloc] initWithData: [[NSData alloc] initWithBytesNoCopy:mdlVoxels length:sizeof(voxVoxels)]
		boundingBox: (MDLAxisAlignedBoundingBox){
			.minBounds = { 0, 0, 0 },
			.maxBounds = { dimensions.x, dimensions.y, dimensions.z }
		}
		voxelExtent: 1.0f
	];
	
	return self;
}

@end
