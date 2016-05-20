//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MagicaVoxelVoxData_VoxelChunkContentsHandle.h"



@implementation VoxelChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kVoxelChunkNumVoxels_Offset + kVoxelChunkNumVoxels_Size);
	
	NSParameterAssert(_data.length >= _baseOffset + kVoxelChunkVoxels_Offset + self.voxelsSize);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	return self;
}
- (void)dealloc
{
	[_data release];
	_data = nil;
	
	[super dealloc];
}


#pragma Auto-Populated Info Properties

- (ptrdiff_t)numVoxels_offset {
	return _baseOffset + kVoxelChunkNumVoxels_Offset;
}
- (const uint32_t *)numVoxels_ptr {
	return (uint32_t const *)&_data.bytes[_baseOffset + kVoxelChunkNumVoxels_Offset];
}
- (uint32_t)numVoxels {
	return *self.numVoxels_ptr;
}

- (size_t)voxelsSize {
	return kVoxelChunk_VoxelSize * self.numVoxels;
}

- (ptrdiff_t)voxels_offset {
	return _baseOffset + kVoxelChunkVoxels_Offset;
}
- (VoxelChunkContentsHandle_Voxel *)voxels_array {
	return (VoxelChunkContentsHandle_Voxel *)(uint8_t const (*)[4])&_data.bytes[_baseOffset + kVoxelChunkVoxels_Offset];
}

- (size_t)totalSize {
	return kVoxelChunkNumVoxels_Size + self.voxelsSize;
}

@end
