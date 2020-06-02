// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_PackChunkContentsHandle.h"



@implementation PackChunkContentsHandle {
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
	
	NSParameterAssert(_data.length >= _baseOffset + kPackChunk_numModels_offset + kPackChunk_numModels_size);
	
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

- (ptrdiff_t)numModels_offset {
	return _baseOffset + kPackChunk_numModels_offset;
}
- (const NumModelsData *)numModels_ptr {
	return (uint32_t const (*))&_data.bytes[self.numModels_offset];
}

- (size_t)totalSize {
	return kPackChunk_numModels_size;
}


@end
