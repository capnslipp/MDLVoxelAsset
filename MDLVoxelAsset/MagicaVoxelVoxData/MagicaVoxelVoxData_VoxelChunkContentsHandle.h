//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef uint8_t XYZCoordsDataArray[3];
typedef struct _VoxelChunkContentsHandle_Voxel {
	XYZCoordsDataArray const xyzCoords;
	uint8_t const colorIndex;
} VoxelChunkContentsHandle_Voxel;

static const ptrdiff_t kVoxelChunkNumVoxels_Offset = 0;
static const size_t kVoxelChunkNumVoxels_Size = 4;
static const ptrdiff_t kVoxelChunkVoxels_Offset = kVoxelChunkNumVoxels_Offset + kVoxelChunkNumVoxels_Size;
static const size_t kVoxelChunk_VoxelSize = 4;



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface VoxelChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t numVoxels_offset;
@property (nonatomic, assign, readonly) uint32_t const *numVoxels_ptr;
@property (nonatomic, assign, readonly) uint32_t numVoxels;

@property (nonatomic, assign, readonly) size_t voxelsSize;

@property (nonatomic, assign, readonly) ptrdiff_t voxels_offset;
@property (nonatomic, assign, nullable) VoxelChunkContentsHandle_Voxel *voxels_array;

/// The total size of the contents.
- (size_t)totalSize;

@end


#pragma clang assume_nonnull end
