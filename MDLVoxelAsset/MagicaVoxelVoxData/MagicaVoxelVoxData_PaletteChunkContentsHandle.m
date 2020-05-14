// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_PaletteChunkContentsHandle.h"



#pragma mark Class Definition

@implementation PaletteChunkContentsHandle {
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
	
	NSParameterAssert(_data.length >= _baseOffset + kPaletteChunkColors_Offset + kPaletteChunk_PaletteSize);
	
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

- (ptrdiff_t)colors_offset {
	return _baseOffset + kPaletteChunkColors_Offset;
}
- (PaletteChunkContentsHandle_Color *)colors_array {
	return (PaletteChunkContentsHandle_Color *)(uint8_t const (*)[4])&_data.bytes[_baseOffset + kPaletteChunkColors_Offset];
}

- (size_t)totalSize {
	return kPaletteChunk_PaletteSize;
}


@end
