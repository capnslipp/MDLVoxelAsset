// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>

#import "MagicaVoxelVoxData_ChunkIdent.h"



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface ChunkHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ChunkIdent ident;

@property (nonatomic, assign, readonly) ptrdiff_t contentsSize_offset;
@property (nonatomic, assign, readonly) uint32_t const *contentsSize_ptr;
@property (nonatomic, assign, readonly) uint32_t contentsSize;

@property (nonatomic, assign, readonly) ptrdiff_t childrenTotalSize_offset;
@property (nonatomic, assign, readonly) uint32_t const *childrenTotalSize_ptr;
@property (nonatomic, assign, readonly) uint32_t childrenTotalSize;

@property (nonatomic, assign, readonly) ptrdiff_t contents_offset;
@property (nonatomic, assign, readonly, nullable) void const *contents_ptr;

@property (nonatomic, assign, readonly) ptrdiff_t children_offset;
@property (nonatomic, assign, readonly, nullable) void const *children_ptr;


// Dumb sub-Handle holders (not auto-populated):

@property (nonatomic, retain, nullable) id contentsHandle;
@property (nonatomic, retain, readonly) NSMutableDictionary<NSString*,ChunkHandle*> *childrenChunks;

/// The total size of the chunk.  Calculated as:
///		The size of the ID (4 bytes) + the contents-size field (4 bytes) + the children-total-size field (4 bytes) + the size of the contents + the size of the children.
- (size_t)totalSize;

@end


#pragma clang assume_nonnull end
