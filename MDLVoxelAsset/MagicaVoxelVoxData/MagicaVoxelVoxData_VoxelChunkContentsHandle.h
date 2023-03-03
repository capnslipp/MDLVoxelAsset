// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef uint8_t XYZCoordsData[3];
typedef struct _VoxelChunkContentsHandle_Voxel {
	XYZCoordsData const xyzCoords;
	uint8_t const colorIndex;
} VoxelChunkContentsHandle_Voxel;

static const ptrdiff_t kVoxelChunk_numVoxels_offset = 0;
static const size_t kVoxelChunk_numVoxels_size = 4;

static const ptrdiff_t kVoxelChunk_voxels_offset = kVoxelChunk_numVoxels_offset + kVoxelChunk_numVoxels_size;



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface VoxelChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t numVoxels_offset;
@property (nonatomic, assign, readonly) uint32_t const *numVoxels_ptr;
@property (nonatomic, assign, readonly) uint32_t numVoxels;

@property (nonatomic, assign, readonly) ptrdiff_t voxels_offset;
@property (nonatomic, assign, readonly) ptrdiff_t voxels_count;
@property (nonatomic, assign, readonly) size_t voxels_size;
@property (nonatomic, assign, nullable) VoxelChunkContentsHandle_Voxel *voxels;

/// The total size of the contents.
- (size_t)totalSize;


// Description

@property (readonly, copy) NSString *debugDescription;

@end


#pragma clang assume_nonnull end
