//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef uint32_t XYZSizeDataArray[3];

static const size_t kSizeChunk_XYZSizeSize = sizeof(XYZSizeDataArray);



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
