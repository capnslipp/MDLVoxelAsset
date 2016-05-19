//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>



typedef uint8_t XYZCoordsDataArray[3];
typedef struct _VoxelChunkContentsHandle_Voxel {
	XYZCoordsDataArray const xyzCoords;
	uint8_t const colorIndex;
} VoxelChunkContentsHandle_Voxel;


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface VoxelChunkContentsHandle : NSObject  {
}

@property (nonatomic, assign, nullable) uint32_t const *numVoxels;
@property (nonatomic, assign, nullable) VoxelChunkContentsHandle_Voxel *voxels_array;

@end
