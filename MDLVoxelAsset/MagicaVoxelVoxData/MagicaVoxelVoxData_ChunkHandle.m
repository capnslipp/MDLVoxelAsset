//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MagicaVoxelVoxData_ChunkHandle.h"



@interface ChunkHandle ()

@property (nonatomic, retain) NSMutableDictionary<NSString*,ChunkHandle*> *childrenChunks;

@end



@implementation ChunkHandle

- (void)dealloc
{
	self.childrenChunks = nil;
	
	[super dealloc];
}

- (NSMutableDictionary<NSString *,ChunkHandle *> *)childrenChunks
{
	if (_childrenChunks == nil)
		_childrenChunks = [NSMutableDictionary<NSString*,ChunkHandle*> new];
	
	return [[_childrenChunks retain] autorelease];
}

- (size_t)totalSize
{
	return sizeof(*_ident.fourCharCode) + sizeof(*_contentsSize) + sizeof(*_childrenTotalSize) + *_contentsSize + *_childrenTotalSize;
}

@end
