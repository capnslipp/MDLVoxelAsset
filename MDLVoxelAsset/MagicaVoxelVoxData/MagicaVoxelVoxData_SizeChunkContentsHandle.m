//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MagicaVoxelVoxData_SizeChunkContentsHandle.h"



@implementation SizeChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kSizeChunk_XYZSizeSize);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	return self;
}
- (void)dealloc
{
	[_data release];
	_data = nil;
	
	[super dealloc];
}


#pragma Auto-Populated Info Properties

- (ptrdiff_t)xyzSize_offset {
	return _baseOffset;
}
- (const XYZSizeDataArray *)xyzSize_ptr {
	return (uint32_t const (*)[3])&_data.bytes[_baseOffset];
}

- (size_t)totalSize {
	return kSizeChunk_XYZSizeSize;
}


@end
