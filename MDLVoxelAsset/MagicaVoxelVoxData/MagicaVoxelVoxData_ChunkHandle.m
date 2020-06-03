// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_ChunkHandle.h"



#pragma mark Constants

static const ptrdiff_t kChunkIdent_chunkOffset = 0;
static const size_t kChunkIdent_size = 4;
static const ptrdiff_t kChunkContentsSize_chunkOffset = kChunkIdent_chunkOffset + kChunkIdent_size;
static const size_t kChunkContentsSize_size = 4;
static const ptrdiff_t kChunkChildrenTotalSize_chunkOffset = kChunkContentsSize_chunkOffset + kChunkContentsSize_size;
static const size_t kChunkChildrenTotalSize_size = 4;
static const ptrdiff_t kChunkContentsOrChildren_offset = kChunkChildrenTotalSize_chunkOffset + kChunkChildrenTotalSize_size;

static const ptrdiff_t kPtrdiffMax = -(((ptrdiff_t)1 << (sizeof(ptrdiff_t) * 8 - 1)) + 1);
static const ptrdiff_t kInvalidPtrdiff = kPtrdiffMax;



#pragma mark Class Definition

@implementation ChunkHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
	
	NSMutableDictionary<NSString*,NSMutableArray<ChunkHandle*>*> *_childrenChunks;
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkIdent_chunkOffset + kChunkIdent_size);
	_ident = (ChunkIdent){
		.ptr = (uint8_t const *)&_data.bytes[_baseOffset + kChunkIdent_chunkOffset]
	};
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsSize_chunkOffset + kChunkContentsSize_size);
	NSParameterAssert(_data.length >= _baseOffset + kChunkChildrenTotalSize_chunkOffset + kChunkChildrenTotalSize_size);
	
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsOrChildren_offset + self.contentsSize);
	NSParameterAssert(_data.length >= _baseOffset + kChunkContentsOrChildren_offset + self.contentsSize + self.childrenTotalSize);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	return self;
}

- (void)dealloc
{
	[_childrenChunks release];
	_childrenChunks = nil;
	
	[_data release];
	_data = nil;
	
	self.contentsHandle = nil;
	
	[super dealloc];
}


#pragma Auto-Populated Info Properties

- (ptrdiff_t)contentsSize_offset {
	return _baseOffset + kChunkContentsSize_chunkOffset;
}
- (const uint32_t *)contentsSize_ptr {
	return (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsSize_chunkOffset];
}
- (uint32_t)contentsSize {
	return *self.contentsSize_ptr;
}

- (ptrdiff_t)childrenTotalSize_offset {
	return _baseOffset + kChunkChildrenTotalSize_chunkOffset;
}
- (const uint32_t *)childrenTotalSize_ptr {
	return (uint32_t const *)&_data.bytes[_baseOffset + kChunkChildrenTotalSize_chunkOffset];
}
- (uint32_t)childrenTotalSize {
	return *self.childrenTotalSize_ptr;
}

- (ptrdiff_t)contents_offset {
	return (self.contentsSize == 0) ? kInvalidPtrdiff : (_baseOffset + kChunkContentsOrChildren_offset);
}
- (const void *)contents_ptr {
	return (self.contentsSize == 0) ? NULL : (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsOrChildren_offset];
}

- (ptrdiff_t)children_offset {
	return (self.childrenTotalSize == 0) ? kInvalidPtrdiff : (_baseOffset + kChunkContentsOrChildren_offset + self.contentsSize);
}
- (const void *)children_ptr {
	return (self.childrenTotalSize == 0) ? NULL : (uint32_t const *)&_data.bytes[_baseOffset + kChunkContentsOrChildren_offset + self.contentsSize];
}

- (size_t)totalSize
{
	return kChunkIdent_size + kChunkContentsSize_size + kChunkChildrenTotalSize_size + // “header”
		self.contentsSize + self.childrenTotalSize; // “body”: contents/children
}


#pragma “Dumb” Handle-Object-Holder Properties

- (NSDictionary<NSString*,NSArray<ChunkHandle*>*> *)childrenChunks
{
	if (_childrenChunks == nil)
		return [NSDictionary<NSString*,NSArray<ChunkHandle*>*> dictionary]; // empty dictionary
	
	return [[_childrenChunks retain] autorelease];
}

- (void)addChildChunk:(NSString *)identString handle:(ChunkHandle *)handle
{
	if (_childrenChunks == nil)
		_childrenChunks = [NSMutableDictionary<NSString*,NSMutableArray<ChunkHandle*>*> new];
	
	NSMutableArray<ChunkHandle*>* identEntryArray = _childrenChunks[identString];
	if (identEntryArray == nil) {
		identEntryArray = [NSMutableArray<ChunkHandle*> new];
		[(_childrenChunks[identString] = identEntryArray) release];
	}
	
	[identEntryArray addObject:handle];
}


@end
