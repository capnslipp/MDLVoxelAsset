//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>

#import "MagicaVoxelVoxData_ChunkIdent.h"



/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface ChunkHandle : NSObject  {
}

@property (nonatomic, assign) ChunkIdent ident;
@property (nonatomic, assign, nullable) uint32_t const *contentsSize;
@property (nonatomic, assign, nullable) uint32_t const *childrenTotalSize;
@property (nonatomic, retain, nullable) id contents;
@property (nonatomic, retain, nonnull, readonly) NSMutableDictionary<NSString*,ChunkHandle*> *childrenChunks;

/// The total size of the chunk.  Calculated as:
///		The size of the ID (4 bytes) + the contents-size field (4 bytes) + the children-total-size field (4 bytes) + the size of the contents + the size of the children.
- (size_t)totalSize;

@end
