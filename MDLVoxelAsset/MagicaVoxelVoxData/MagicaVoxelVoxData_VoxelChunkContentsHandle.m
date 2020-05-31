// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_VoxelChunkContentsHandle.h"



@implementation VoxelChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
}


+ (void)initialize
{
	assert(sizeof(VoxelChunkContentsHandle_Voxel) == 4);
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kVoxelChunk_numVoxels_offset + kVoxelChunk_numVoxels_size);
	
	NSParameterAssert(_data.length >= _baseOffset + kVoxelChunk_voxels_offset + self.voxels_size);
	
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
	return _baseOffset + kVoxelChunk_numVoxels_offset;
}
- (const uint32_t *)numVoxels_ptr {
	return (uint32_t const *)&_data.bytes[self.numVoxels_offset];
}
- (uint32_t)numVoxels {
	return *self.numVoxels_ptr;
}

- (ptrdiff_t)voxels_offset {
	return _baseOffset + kVoxelChunk_voxels_offset;
}
- (ptrdiff_t)voxels_count {
	return self.numVoxels; // just a method alias
}
- (size_t)voxels_size {
	return sizeof(VoxelChunkContentsHandle_Voxel) * self.numVoxels;
}
- (VoxelChunkContentsHandle_Voxel *)voxels {
	return (VoxelChunkContentsHandle_Voxel *)(uint8_t const (*)[4])&_data.bytes[self.voxels_offset];
}

- (size_t)totalSize {
	return kVoxelChunk_numVoxels_size + self.voxels_size;
}

@end
