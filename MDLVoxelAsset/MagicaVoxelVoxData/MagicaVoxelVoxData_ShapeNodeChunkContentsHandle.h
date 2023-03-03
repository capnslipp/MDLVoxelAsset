// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>

#import "MagicaVoxelVoxData_types.h"


#pragma mark Constants

static const ptrdiff_t kShapeNodeChunk_nodeID_offset = 0;
static const size_t kShapeNodeChunk_nodeID_size = 4;

static const ptrdiff_t kShapeNodeChunk_nodeAttributes_offset = (kShapeNodeChunk_nodeID_offset + kShapeNodeChunk_nodeID_size);

static const ptrdiff_t kShapeNodeChunk_numModels_afterNodeAttributesOffset = 0;
static const size_t kShapeNodeChunk_numModels_size = 4;

static const ptrdiff_t kShapeNodeChunk_models_afterNodeAttributesOffset = (kShapeNodeChunk_numModels_afterNodeAttributesOffset + kShapeNodeChunk_numModels_size);



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface ShapeNodeChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t nodeID_offset;
@property (nonatomic, assign, readonly) int32_t const *nodeID_ptr;
@property (nonatomic, assign, readonly) int32_t nodeID;

@property (nonatomic, assign, readonly) ptrdiff_t nodeAttributes_offset;
@property (nonatomic, assign, readonly) void const *nodeAttributes_ptr;
@property (nonatomic, assign, readonly) size_t nodeAttributes_size;
@property (nonatomic, assign, readonly) VoxDict nodeAttributes;

@property (nonatomic, assign, readonly) ptrdiff_t numModels_offset;
@property (nonatomic, assign, readonly) int32_t const *numModels_ptr;
@property (nonatomic, assign, readonly) int32_t numModels;

@property (nonatomic, assign, readonly) ptrdiff_t models_offset;
@property (nonatomic, assign, readonly) int32_t models_count;
@property (nonatomic, assign, nullable) void const *models_ptr;
@property (nonatomic, assign, readonly) size_t models_size;

- (int32_t)modelIDForModel:(uint32_t)modelIndex;
- (VoxDict)modelAttributesForModel:(uint32_t)modelIndex;

/// The total size of the contents.
- (size_t)totalSize;


// Description

@property (readonly, copy) NSString *debugDescription;

@end


#pragma clang assume_nonnull end
