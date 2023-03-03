// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef struct _SizeChunkContentsHandle_Size {
	uint32_t const x, y, z;
} SizeChunkContentsHandle_Size;

static const ptrdiff_t kSizeChunk_xyzSize_offset = 0;
static const size_t kSizeChunk_xyzSize_size = sizeof(SizeChunkContentsHandle_Size);



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface SizeChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t xyzSize_offset;
@property (nonatomic, assign, readonly) SizeChunkContentsHandle_Size const *xyzSize_ptr;
@property (nonatomic, assign, readonly) SizeChunkContentsHandle_Size xyzSize;

/// The total size of the contents.
- (size_t)totalSize;


// Description

@property (readonly, copy) NSString *debugDescription;

@end


#pragma clang assume_nonnull end
