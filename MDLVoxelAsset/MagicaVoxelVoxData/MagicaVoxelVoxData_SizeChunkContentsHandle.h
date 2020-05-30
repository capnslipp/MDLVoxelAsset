// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef uint32_t XYZSizeDataArray[3];

static const ptrdiff_t kSizeChunk_xyzSize_offset = 0;
static const size_t kSizeChunk_xyzSize_size = sizeof(XYZSizeDataArray);



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface SizeChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t xyzSize_offset;
@property (nonatomic, assign, readonly) XYZSizeDataArray const *xyzSize_ptr;

/// The total size of the contents.
- (size_t)totalSize;

@end


#pragma clang assume_nonnull end
