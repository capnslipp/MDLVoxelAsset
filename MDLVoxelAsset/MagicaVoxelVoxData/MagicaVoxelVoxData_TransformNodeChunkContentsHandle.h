// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>

#import "MagicaVoxelVoxData_types.h"


#pragma mark Constants

static const ptrdiff_t kTransformNodeChunk_nodeID_offset = 0;
static const size_t kTransformNodeChunk_nodeID_size = 4;

static const ptrdiff_t kTransformNodeChunk_nodeAttributes_offset = (kTransformNodeChunk_nodeID_offset + kTransformNodeChunk_nodeID_size);

static const ptrdiff_t kTransformNodeChunk_childNodeID_afterNodeAttributesOffset = 0;
static const size_t kTransformNodeChunk_childNodeID_size = 4;

static const ptrdiff_t kTransformNodeChunk_reservedID_afterNodeAttributesOffset = (kTransformNodeChunk_childNodeID_afterNodeAttributesOffset + kTransformNodeChunk_childNodeID_size);
static const size_t kTransformNodeChunk_reservedID_size = 4;

static const ptrdiff_t kTransformNodeChunk_layerID_afterNodeAttributesOffset = (kTransformNodeChunk_reservedID_afterNodeAttributesOffset + kTransformNodeChunk_reservedID_size);
static const size_t kTransformNodeChunk_layerID_size = 4;

static const ptrdiff_t kTransformNodeChunk_numFrames_afterNodeAttributesOffset = (kTransformNodeChunk_layerID_afterNodeAttributesOffset + kTransformNodeChunk_layerID_size);
static const size_t kTransformNodeChunk_numFrames_size = 4;

static const ptrdiff_t kTransformNodeChunk_frames_afterNodeAttributesOffset = (kTransformNodeChunk_numFrames_afterNodeAttributesOffset + kTransformNodeChunk_numFrames_size);



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface TransformNodeChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t nodeID_offset;
@property (nonatomic, assign, readonly) int32_t const *nodeID_ptr;
@property (nonatomic, assign, readonly) int32_t nodeID;

@property (nonatomic, assign, readonly) ptrdiff_t nodeAttributes_offset;
@property (nonatomic, assign, readonly) void const *nodeAttributes_ptr;
@property (nonatomic, assign, readonly) size_t nodeAttributes_size;
@property (nonatomic, assign, readonly) VoxDict nodeAttributes;

@property (nonatomic, assign, readonly) ptrdiff_t childNodeID_offset;
@property (nonatomic, assign, readonly) int32_t const *childNodeID_ptr;
@property (nonatomic, assign, readonly) int32_t childNodeID;

@property (nonatomic, assign, readonly) ptrdiff_t reservedID_offset;
@property (nonatomic, assign, readonly) int32_t const *reservedID_ptr;
@property (nonatomic, assign, readonly) int32_t reservedID;

@property (nonatomic, assign, readonly) ptrdiff_t layerID_offset;
@property (nonatomic, assign, readonly) int32_t const *layerID_ptr;
@property (nonatomic, assign, readonly) int32_t layerID;

@property (nonatomic, assign, readonly) ptrdiff_t numFrames_offset;
@property (nonatomic, assign, readonly) int32_t const *numFrames_ptr;
@property (nonatomic, assign, readonly) int32_t numFrames;

@property (nonatomic, assign, readonly) ptrdiff_t frames_offset;
@property (nonatomic, assign, readonly) int32_t frames_count;
@property (nonatomic, assign, nullable) void const *frames_ptr;
@property (nonatomic, assign, readonly) size_t frames_size;

- (VoxDict)frameAttributesForFrame:(uint32_t)frameIndex;

- (VoxString)frameAttributeTranslationStringForFrame:(uint32_t)frameIndex;
- (simd_int3)frameAttributeSIMDTranslationForFrame:(uint32_t)frameIndex;

- (VoxString)frameAttributeRotationStringForFrame:(uint32_t)frameIndex;
- (simd_float3x3)frameAttributeSIMDRotationForFrame:(uint32_t)frameIndex;

/// The total size of the contents.
- (size_t)totalSize;

@end


#pragma clang assume_nonnull end
