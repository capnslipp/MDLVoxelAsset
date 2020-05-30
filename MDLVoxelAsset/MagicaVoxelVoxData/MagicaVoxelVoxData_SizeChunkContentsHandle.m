// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

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
	
	NSParameterAssert(_data.length >= _baseOffset + kSizeChunk_xyzSize_offset + kSizeChunk_xyzSize_size);
	
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
	return _baseOffset + kSizeChunk_xyzSize_offset;
}
- (const XYZSizeDataArray *)xyzSize_ptr {
	return (uint32_t const (*)[3])&_data.bytes[self.xyzSize_offset];
}

- (size_t)totalSize {
	return kSizeChunk_xyzSize_size;
}


@end
