// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>

#import "MagicaVoxelVoxData_types.h"


#pragma mark Constants

typedef struct _GroupNodeChunkContentsHandle_Child {
	int32_t childID;
} GroupNodeChunkContentsHandle_Child;

static const ptrdiff_t kGroupNodeChunk_nodeID_offset = 0;
static const size_t kGroupNodeChunk_nodeID_size = 4;

static const ptrdiff_t kGroupNodeChunk_nodeAttributes_offset = (kGroupNodeChunk_nodeID_offset + kGroupNodeChunk_nodeID_size);

static const ptrdiff_t kGroupNodeChunk_numChildNodes_afterNodeAttributesOffset = 0;
static const size_t kGroupNodeChunk_numChildNodes_size = 4;

static const ptrdiff_t kGroupNodeChunk_childNodes_afterNodeAttributesOffset = (kGroupNodeChunk_numChildNodes_afterNodeAttributesOffset + kGroupNodeChunk_numChildNodes_size);



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface GroupNodeChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t nodeID_offset;
@property (nonatomic, assign, readonly) int32_t const *nodeID_ptr;
@property (nonatomic, assign, readonly) int32_t nodeID;

@property (nonatomic, assign, readonly) ptrdiff_t nodeAttributes_offset;
@property (nonatomic, assign, readonly) void const *nodeAttributes_ptr;
@property (nonatomic, assign, readonly) size_t nodeAttributes_size;
@property (nonatomic, assign, readonly) VoxDict nodeAttributes;

@property (nonatomic, assign, readonly) ptrdiff_t numChildNodes_offset;
@property (nonatomic, assign, readonly) int32_t const *numChildNodes_ptr;
@property (nonatomic, assign, readonly) int32_t numChildNodes;

@property (nonatomic, assign, readonly) ptrdiff_t childNodes_offset;
@property (nonatomic, assign, readonly) int32_t childNodes_count;
@property (nonatomic, assign, readonly) size_t childNodes_size;
@property (nonatomic, assign, nullable) GroupNodeChunkContentsHandle_Child const *childNodes;

/// The total size of the contents.
- (size_t)totalSize;


// Description

@property (readonly, copy) NSString *debugDescription;

@end


#pragma clang assume_nonnull end
