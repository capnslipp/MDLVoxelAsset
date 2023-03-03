// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_PaletteChunkContentsHandle.h"

#import "MagicaVoxelVoxData_utilities.h"



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
	
	NSParameterAssert(_data.length >= _baseOffset + kPaletteChunk_colors_offset + kPaletteChunk_colors_size);
	
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

- (uint32_t)numColors {
	return kPaletteChunk_colors_count; // always a full palette
}

- (ptrdiff_t)colors_offset {
	return _baseOffset + kPaletteChunk_colors_offset;
}
- (uint32_t)colors_count {
	return kPaletteChunk_colors_count; // always a full palette
}
- (PaletteChunkContentsHandle_Color *)colors {
	return (PaletteChunkContentsHandle_Color *)(uint8_t const (*)[4])&_data.bytes[self.colors_offset];
}

- (PaletteChunkContentsHandle_Color)colorForPaletteIndex:(uint8_t)paletteIndex {
	return self.colors[paletteIndex - 1];
}

- (size_t)totalSize {
	return kPaletteChunk_colors_size;
}


#pragma mark debugDescription

- (NSString *)debugDescription
{
	NSString *indentationString = indentationStringOfLength(sDebugLogParseDepth);
	NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:400]; // capacity is a rough estimate, based on output from test files
	
	[outputString appendFormat:@"%@numColors: %d\n", indentationString, self.numColors];
	
	[outputString appendFormat:@"%@colors:\n", indentationString];
	for (int colorI = 0; colorI < self.colors_count; ++colorI) {
		uint8_t paletteIndex = colorI + 1;
		PaletteChunkContentsHandle_Color color = self.colors[colorI];
		
		NSString *formatString;
		if (colorI != 255) {
			formatString = @"%@\tcolor #%3d:    #%02X%02X%02X%02X\n";
		} else {
			// Special reserved transparent color:
			formatString = @"%@\tcolor #0/#256:    #%02X%02X%02X%02X (reserved transparent color)\n";
		}
		
		[outputString appendFormat:formatString, indentationString, paletteIndex, color.rgbaValues[0], color.rgbaValues[1], color.rgbaValues[2], color.rgbaValues[3]];
	}
	
	return [outputString autorelease];
}


@end
