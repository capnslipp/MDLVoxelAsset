//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MagicaVoxelVoxData_ChunkHandle.h"



#pragma mark Constants

static const ptrdiff_t kChunkIdent_ChunkOffset = 0;
static const size_t kChunkIdent_Size = 4;
static const ptrdiff_t kChunkContentsSize_ChunkOffset = kChunkIdent_ChunkOffset + kChunkIdent_Size;
static const size_t kChunkContentsSize_Size = 4;
static const ptrdiff_t kChunkChildrenTotalSize_ChunkOffset = kChunkContentsSize_ChunkOffset + kChunkContentsSize_Size;
static const size_t kChunkChildrenTotalSize_Size = 4;
static const ptrdiff_t kChunkContentsOrChildren_Offset = kChunkChildrenTotalSize_ChunkOffset + kChunkChildrenTotalSize_Size;

static const ptrdiff_t kPtrdiffMax = 1 << (sizeof(ptrdiff_t) * 8 - 1);
static const ptrdiff_t kInvalidPtrdiff = kPtrdiffMax;



#pragma mark Class Definition

@implementation ChunkHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
}
@synthesize childrenChunks=_childrenChunks;


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkIdent_ChunkOffset + kChunkIdent_Size);
	_ident = (ChunkIdent){
		.ptr = (uint8_t const *)&_data.bytes[_baseOffset + kChunkIdent_ChunkOffset]
	};
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsSize_ChunkOffset + kChunkContentsSize_Size);
	NSParameterAssert(_data.length >= _baseOffset + kChunkChildrenTotalSize_ChunkOffset + kChunkChildrenTotalSize_Size);
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsOrChildren_Offset + self.contentsSize);
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsOrChildren_Offset + self.contentsSize + self.childrenTotalSize);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	return self;
}

- (void)dealloc
{
	[_childrenChunks release];
	_childrenChunks = nil;
	
	[_data release];
	_data = nil;
	
	[super dealloc];
}


#pragma Auto-Populated Info Properties

- (ptrdiff_t)contentsSize_offset {
	return _baseOffset + kChunkContentsSize_ChunkOffset;
}
- (const uint32_t *)contentsSize_ptr {
	return (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsSize_ChunkOffset];
}
- (uint32_t)contentsSize {
	return *self.contentsSize_ptr;
}

- (ptrdiff_t)childrenTotalSize_offset {
	return _baseOffset + kChunkChildrenTotalSize_ChunkOffset;
}
- (const uint32_t *)childrenTotalSize_ptr {
	return (uint32_t const *)&_data.bytes[_baseOffset + kChunkChildrenTotalSize_ChunkOffset];
}
- (uint32_t)childrenTotalSize {
	return *self.childrenTotalSize_ptr;
}

- (ptrdiff_t)contents_offset {
	return (self.contentsSize == 0) ? kInvalidPtrdiff : (_baseOffset + kChunkContentsOrChildren_Offset);
}
- (const void *)contents_ptr {
	return (self.contentsSize == 0) ? NULL : (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsOrChildren_Offset];
}

- (ptrdiff_t)children_offset {
	return (self.childrenTotalSize == 0) ? kInvalidPtrdiff : (_baseOffset + kChunkContentsOrChildren_Offset + self.contentsSize);
}
- (const void *)children_ptr {
	return (self.childrenTotalSize == 0) ? NULL : (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsOrChildren_Offset + self.contentsSize];
}

- (size_t)totalSize
{
	return kChunkIdent_Size + kChunkContentsSize_Size + kChunkChildrenTotalSize_Size + // “header”
		self.contentsSize + self.childrenTotalSize; // “body”: contents/children
}


#pragma “Dumb” Handle-Object-Holder Properties

- (NSMutableDictionary<NSString *,ChunkHandle *> *)childrenChunks
{
	if (_childrenChunks == nil)
		_childrenChunks = [NSMutableDictionary<NSString*,ChunkHandle*> new];
	
	return [[_childrenChunks retain] autorelease];
}


@end
