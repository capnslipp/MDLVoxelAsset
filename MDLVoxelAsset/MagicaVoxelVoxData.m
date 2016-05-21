//  MagicaVoxelVoxData.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/16/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MagicaVoxelVoxData.h"



typedef MagicaVoxelVoxData ThisClass;

typedef uint8_t FourCharDataArray[4];

typedef union _MagicNumber {
	FourCharDataArray const *array;
	uint8_t const *ptr;
	FourCharCode const *fourCharCode;
} MagicNumber; // @todo: Rename to MagicNumberDataPtr?

static const char kValidMagicNumber_string[] = "VOX ";
static const MagicNumber kValidMagicNumber = { .ptr = (uint8_t const *)&kValidMagicNumber_string };

static const ptrdiff_t kMagicNumber_Offset = 0;
static const size_t kMagicNumber_Size = 4;
static const ptrdiff_t kVersionNumber_Offset = kMagicNumber_Offset + kMagicNumber_Size;
static const size_t kVersionNumber_Size = 4;
static const ptrdiff_t kRootChunk_Offset = kVersionNumber_Offset + kVersionNumber_Size;


#import "MagicaVoxelVoxData_ChunkIdent.h"

static const char kMainChunkIdent_string[] = "MAIN";
static const ChunkIdent kMainChunkIdent = { .ptr = (uint8_t const *)&kMainChunkIdent_string };
static const char kSizeChunkIdent_string[] = "SIZE";
static const ChunkIdent kSizeChunkIdent = { .ptr = (uint8_t const *)&kSizeChunkIdent_string };
static const char kVoxelChunkIdent_string[] = "XYZI";
static const ChunkIdent kVoxelChunkIdent = { .ptr = (uint8_t const *)&kVoxelChunkIdent_string };
static const char kPaletteChunkIdent_string[] = "RGBA";
static const ChunkIdent kPaletteChunkIdent = { .ptr = (uint8_t const *)&kPaletteChunkIdent_string };


#import "MagicaVoxelVoxData_SizeChunkContentsHandle.h"
#import "MagicaVoxelVoxData_VoxelChunkContentsHandle.h"
#import "MagicaVoxelVoxData_PaletteChunkContentsHandle.h"


#import "MagicaVoxelVoxData_ChunkHandle.h"

static const size_t kChunkPadding_MinSize = 0;
static const size_t kChunkPadding_MaxSize = 1;

//static const RGBAValuesDataArray kDefaultPaletteRGBAValues[256] = ;
static PaletteChunkContentsHandle *kDefaultPaletteContents;
struct {
	FourCharDataArray ident;
	uint32_t contentsSize;
	uint32_t childrenTotalSize;;
	RGBAValuesDataArray contents[256];
	// `children` is zero-length
} kDefaultPaletteData = {
	.ident = {'R','G','B','A'},
	.contentsSize = 4 * 256,
	.childrenTotalSize = 0,
	.contents = {
		{ 0xFF, 0xFF, 0xFF, 0xFF }, { 0xFF, 0xFF, 0xCC, 0xFF }, { 0xFF, 0xFF, 0x99, 0xFF }, { 0xFF, 0xFF, 0x66, 0xFF }, { 0xFF, 0xFF, 0x33, 0xFF }, { 0xFF, 0xFF, 0x00, 0xFF }, { 0xFF, 0xCC, 0xFF, 0xFF }, { 0xFF, 0xCC, 0xCC, 0xFF },
		{ 0xFF, 0xCC, 0x99, 0xFF }, { 0xFF, 0xCC, 0x66, 0xFF }, { 0xFF, 0xCC, 0x33, 0xFF }, { 0xFF, 0xCC, 0x00, 0xFF }, { 0xFF, 0x99, 0xFF, 0xFF }, { 0xFF, 0x99, 0xCC, 0xFF }, { 0xFF, 0x99, 0x99, 0xFF }, { 0xFF, 0x99, 0x66, 0xFF },
		{ 0xFF, 0x99, 0x33, 0xFF }, { 0xFF, 0x99, 0x00, 0xFF }, { 0xFF, 0x66, 0xFF, 0xFF }, { 0xFF, 0x66, 0xCC, 0xFF }, { 0xFF, 0x66, 0x99, 0xFF }, { 0xFF, 0x66, 0x66, 0xFF }, { 0xFF, 0x66, 0x33, 0xFF }, { 0xFF, 0x66, 0x00, 0xFF },
		{ 0xFF, 0x33, 0xFF, 0xFF }, { 0xFF, 0x33, 0xCC, 0xFF }, { 0xFF, 0x33, 0x99, 0xFF }, { 0xFF, 0x33, 0x66, 0xFF }, { 0xFF, 0x33, 0x33, 0xFF }, { 0xFF, 0x33, 0x00, 0xFF }, { 0xFF, 0x00, 0xFF, 0xFF }, { 0xFF, 0x00, 0xCC, 0xFF },
		{ 0xFF, 0x00, 0x99, 0xFF }, { 0xFF, 0x00, 0x66, 0xFF }, { 0xFF, 0x00, 0x33, 0xFF }, { 0xFF, 0x00, 0x00, 0xFF }, { 0xCC, 0xFF, 0xFF, 0xFF }, { 0xCC, 0xFF, 0xCC, 0xFF }, { 0xCC, 0xFF, 0x99, 0xFF }, { 0xCC, 0xFF, 0x66, 0xFF },
		{ 0xCC, 0xFF, 0x33, 0xFF }, { 0xCC, 0xFF, 0x00, 0xFF }, { 0xCC, 0xCC, 0xFF, 0xFF }, { 0xCC, 0xCC, 0xCC, 0xFF }, { 0xCC, 0xCC, 0x99, 0xFF }, { 0xCC, 0xCC, 0x66, 0xFF }, { 0xCC, 0xCC, 0x33, 0xFF }, { 0xCC, 0xCC, 0x00, 0xFF },
		{ 0xCC, 0x99, 0xFF, 0xFF }, { 0xCC, 0x99, 0xCC, 0xFF }, { 0xCC, 0x99, 0x99, 0xFF }, { 0xCC, 0x99, 0x66, 0xFF }, { 0xCC, 0x99, 0x33, 0xFF }, { 0xCC, 0x99, 0x00, 0xFF }, { 0xCC, 0x66, 0xFF, 0xFF }, { 0xCC, 0x66, 0xCC, 0xFF },
		{ 0xCC, 0x66, 0x99, 0xFF }, { 0xCC, 0x66, 0x66, 0xFF }, { 0xCC, 0x66, 0x33, 0xFF }, { 0xCC, 0x66, 0x00, 0xFF }, { 0xCC, 0x33, 0xFF, 0xFF }, { 0xCC, 0x33, 0xCC, 0xFF }, { 0xCC, 0x33, 0x99, 0xFF }, { 0xCC, 0x33, 0x66, 0xFF },
		{ 0xCC, 0x33, 0x33, 0xFF }, { 0xCC, 0x33, 0x00, 0xFF }, { 0xCC, 0x00, 0xFF, 0xFF }, { 0xCC, 0x00, 0xCC, 0xFF }, { 0xCC, 0x00, 0x99, 0xFF }, { 0xCC, 0x00, 0x66, 0xFF }, { 0xCC, 0x00, 0x33, 0xFF }, { 0xCC, 0x00, 0x00, 0xFF },
		{ 0x99, 0xFF, 0xFF, 0xFF }, { 0x99, 0xFF, 0xCC, 0xFF }, { 0x99, 0xFF, 0x99, 0xFF }, { 0x99, 0xFF, 0x66, 0xFF }, { 0x99, 0xFF, 0x33, 0xFF }, { 0x99, 0xFF, 0x00, 0xFF }, { 0x99, 0xCC, 0xFF, 0xFF }, { 0x99, 0xCC, 0xCC, 0xFF },
		{ 0x99, 0xCC, 0x99, 0xFF }, { 0x99, 0xCC, 0x66, 0xFF }, { 0x99, 0xCC, 0x33, 0xFF }, { 0x99, 0xCC, 0x00, 0xFF }, { 0x99, 0x99, 0xFF, 0xFF }, { 0x99, 0x99, 0xCC, 0xFF }, { 0x99, 0x99, 0x99, 0xFF }, { 0x99, 0x99, 0x66, 0xFF },
		{ 0x99, 0x99, 0x33, 0xFF }, { 0x99, 0x99, 0x00, 0xFF }, { 0x99, 0x66, 0xFF, 0xFF }, { 0x99, 0x66, 0xCC, 0xFF }, { 0x99, 0x66, 0x99, 0xFF }, { 0x99, 0x66, 0x66, 0xFF }, { 0x99, 0x66, 0x33, 0xFF }, { 0x99, 0x66, 0x00, 0xFF },
		{ 0x99, 0x33, 0xFF, 0xFF }, { 0x99, 0x33, 0xCC, 0xFF }, { 0x99, 0x33, 0x99, 0xFF }, { 0x99, 0x33, 0x66, 0xFF }, { 0x99, 0x33, 0x33, 0xFF }, { 0x99, 0x33, 0x00, 0xFF }, { 0x99, 0x00, 0xFF, 0xFF }, { 0x99, 0x00, 0xCC, 0xFF },
		{ 0x99, 0x00, 0x99, 0xFF }, { 0x99, 0x00, 0x66, 0xFF }, { 0x99, 0x00, 0x33, 0xFF }, { 0x99, 0x00, 0x00, 0xFF }, { 0x66, 0xFF, 0xFF, 0xFF }, { 0x66, 0xFF, 0xCC, 0xFF }, { 0x66, 0xFF, 0x99, 0xFF }, { 0x66, 0xFF, 0x66, 0xFF },
		{ 0x66, 0xFF, 0x33, 0xFF }, { 0x66, 0xFF, 0x00, 0xFF }, { 0x66, 0xCC, 0xFF, 0xFF }, { 0x66, 0xCC, 0xCC, 0xFF }, { 0x66, 0xCC, 0x99, 0xFF }, { 0x66, 0xCC, 0x66, 0xFF }, { 0x66, 0xCC, 0x33, 0xFF }, { 0x66, 0xCC, 0x00, 0xFF },
		{ 0x66, 0x99, 0xFF, 0xFF }, { 0x66, 0x99, 0xCC, 0xFF }, { 0x66, 0x99, 0x99, 0xFF }, { 0x66, 0x99, 0x66, 0xFF }, { 0x66, 0x99, 0x33, 0xFF }, { 0x66, 0x99, 0x00, 0xFF }, { 0x66, 0x66, 0xFF, 0xFF }, { 0x66, 0x66, 0xCC, 0xFF },
		{ 0x66, 0x66, 0x99, 0xFF }, { 0x66, 0x66, 0x66, 0xFF }, { 0x66, 0x66, 0x33, 0xFF }, { 0x66, 0x66, 0x00, 0xFF }, { 0x66, 0x33, 0xFF, 0xFF }, { 0x66, 0x33, 0xCC, 0xFF }, { 0x66, 0x33, 0x99, 0xFF }, { 0x66, 0x33, 0x66, 0xFF },
		{ 0x66, 0x33, 0x33, 0xFF }, { 0x66, 0x33, 0x00, 0xFF }, { 0x66, 0x00, 0xFF, 0xFF }, { 0x66, 0x00, 0xCC, 0xFF }, { 0x66, 0x00, 0x99, 0xFF }, { 0x66, 0x00, 0x66, 0xFF }, { 0x66, 0x00, 0x33, 0xFF }, { 0x66, 0x00, 0x00, 0xFF },
		{ 0x33, 0xFF, 0xFF, 0xFF }, { 0x33, 0xFF, 0xCC, 0xFF }, { 0x33, 0xFF, 0x99, 0xFF }, { 0x33, 0xFF, 0x66, 0xFF }, { 0x33, 0xFF, 0x33, 0xFF }, { 0x33, 0xFF, 0x00, 0xFF }, { 0x33, 0xCC, 0xFF, 0xFF }, { 0x33, 0xCC, 0xCC, 0xFF },
		{ 0x33, 0xCC, 0x99, 0xFF }, { 0x33, 0xCC, 0x66, 0xFF }, { 0x33, 0xCC, 0x33, 0xFF }, { 0x33, 0xCC, 0x00, 0xFF }, { 0x33, 0x99, 0xFF, 0xFF }, { 0x33, 0x99, 0xCC, 0xFF }, { 0x33, 0x99, 0x99, 0xFF }, { 0x33, 0x99, 0x66, 0xFF },
		{ 0x33, 0x99, 0x33, 0xFF }, { 0x33, 0x99, 0x00, 0xFF }, { 0x33, 0x66, 0xFF, 0xFF }, { 0x33, 0x66, 0xCC, 0xFF }, { 0x33, 0x66, 0x99, 0xFF }, { 0x33, 0x66, 0x66, 0xFF }, { 0x33, 0x66, 0x33, 0xFF }, { 0x33, 0x66, 0x00, 0xFF },
		{ 0x33, 0x33, 0xFF, 0xFF }, { 0x33, 0x33, 0xCC, 0xFF }, { 0x33, 0x33, 0x99, 0xFF }, { 0x33, 0x33, 0x66, 0xFF }, { 0x33, 0x33, 0x33, 0xFF }, { 0x33, 0x33, 0x00, 0xFF }, { 0x33, 0x00, 0xFF, 0xFF }, { 0x33, 0x00, 0xCC, 0xFF },
		{ 0x33, 0x00, 0x99, 0xFF }, { 0x33, 0x00, 0x66, 0xFF }, { 0x33, 0x00, 0x33, 0xFF }, { 0x33, 0x00, 0x00, 0xFF }, { 0x00, 0xFF, 0xFF, 0xFF }, { 0x00, 0xFF, 0xCC, 0xFF }, { 0x00, 0xFF, 0x99, 0xFF }, { 0x00, 0xFF, 0x66, 0xFF },
		{ 0x00, 0xFF, 0x33, 0xFF }, { 0x00, 0xFF, 0x00, 0xFF }, { 0x00, 0xCC, 0xFF, 0xFF }, { 0x00, 0xCC, 0xCC, 0xFF }, { 0x00, 0xCC, 0x99, 0xFF }, { 0x00, 0xCC, 0x66, 0xFF }, { 0x00, 0xCC, 0x33, 0xFF }, { 0x00, 0xCC, 0x00, 0xFF },
		{ 0x00, 0x99, 0xFF, 0xFF }, { 0x00, 0x99, 0xCC, 0xFF }, { 0x00, 0x99, 0x99, 0xFF }, { 0x00, 0x99, 0x66, 0xFF }, { 0x00, 0x99, 0x33, 0xFF }, { 0x00, 0x99, 0x00, 0xFF }, { 0x00, 0x66, 0xFF, 0xFF }, { 0x00, 0x66, 0xCC, 0xFF },
		{ 0x00, 0x66, 0x99, 0xFF }, { 0x00, 0x66, 0x66, 0xFF }, { 0x00, 0x66, 0x33, 0xFF }, { 0x00, 0x66, 0x00, 0xFF }, { 0x00, 0x33, 0xFF, 0xFF }, { 0x00, 0x33, 0xCC, 0xFF }, { 0x00, 0x33, 0x99, 0xFF }, { 0x00, 0x33, 0x66, 0xFF },
		{ 0x00, 0x33, 0x33, 0xFF }, { 0x00, 0x33, 0x00, 0xFF }, { 0x00, 0x00, 0xFF, 0xFF }, { 0x00, 0x00, 0xCC, 0xFF }, { 0x00, 0x00, 0x99, 0xFF }, { 0x00, 0x00, 0x66, 0xFF }, { 0x00, 0x00, 0x33, 0xFF }, { 0xEE, 0x00, 0x00, 0xFF },
		{ 0xDD, 0x00, 0x00, 0xFF }, { 0xBB, 0x00, 0x00, 0xFF }, { 0xAA, 0x00, 0x00, 0xFF }, { 0x88, 0x00, 0x00, 0xFF }, { 0x77, 0x00, 0x00, 0xFF }, { 0x55, 0x00, 0x00, 0xFF }, { 0x44, 0x00, 0x00, 0xFF }, { 0x22, 0x00, 0x00, 0xFF },
		{ 0x11, 0x00, 0x00, 0xFF }, { 0x00, 0xEE, 0x00, 0xFF }, { 0x00, 0xDD, 0x00, 0xFF }, { 0x00, 0xBB, 0x00, 0xFF }, { 0x00, 0xAA, 0x00, 0xFF }, { 0x00, 0x88, 0x00, 0xFF }, { 0x00, 0x77, 0x00, 0xFF }, { 0x00, 0x55, 0x00, 0xFF },
		{ 0x00, 0x44, 0x00, 0xFF }, { 0x00, 0x22, 0x00, 0xFF }, { 0x00, 0x11, 0x00, 0xFF }, { 0x00, 0x00, 0xEE, 0xFF }, { 0x00, 0x00, 0xDD, 0xFF }, { 0x00, 0x00, 0xBB, 0xFF }, { 0x00, 0x00, 0xAA, 0xFF }, { 0x00, 0x00, 0x88, 0xFF },
		{ 0x00, 0x00, 0x77, 0xFF }, { 0x00, 0x00, 0x55, 0xFF }, { 0x00, 0x00, 0x44, 0xFF }, { 0x00, 0x00, 0x22, 0xFF }, { 0x00, 0x00, 0x11, 0xFF }, { 0xEE, 0xEE, 0xEE, 0xFF }, { 0xDD, 0xDD, 0xDD, 0xFF }, { 0xBB, 0xBB, 0xBB, 0xFF },
		{ 0xAA, 0xAA, 0xAA, 0xFF }, { 0x88, 0x88, 0x88, 0xFF }, { 0x77, 0x77, 0x77, 0xFF }, { 0x55, 0x55, 0x55, 0xFF }, { 0x44, 0x44, 0x44, 0xFF }, { 0x22, 0x22, 0x22, 0xFF }, { 0x11, 0x11, 0x11, 0xFF }, { 0x00, 0x00, 0x00, 0xFF },
	},
};
static ChunkHandle *kDefaultPaletteChunk;


typedef id (^ChunkContentsParserB)(ChunkIdent ident, ptrdiff_t startOffset, uint32_t size);
/// @return: endOffset; potentially the `startOffset` of the next chunk.
typedef ChunkHandle * (^ChunkChildParserB)(ChunkIdent parentIdent, ptrdiff_t startOffset, uint32_t remainingSizeAllowance, ptrdiff_t *out_endOffset);



@interface MagicaVoxelVoxData () {
	NSData *_data;
	
	MagicNumber _magicNumber_ptr;
	uint32_t const *_versionNumber_ptr;
	
	ChunkHandle *_rootChunk;
}

- (instancetype)initUsingDataInitializer:(void (^)(void))dataInitializer;

- (MagicNumber)magicNumber;

@end



@implementation MagicaVoxelVoxData

@synthesize nsData=_data;


+ (void)initialize
{
	static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
		
		kDefaultPaletteChunk = [[ChunkHandle alloc]
			initWithData: [NSData dataWithBytesNoCopy:&kDefaultPaletteData length:sizeof(kDefaultPaletteData)]
			offset: 0
		];
		kDefaultPaletteContents = [[PaletteChunkContentsHandle alloc]
			initWithData: [NSData dataWithBytesNoCopy:&kDefaultPaletteData.contents length:sizeof(kDefaultPaletteData.contents)]
			offset: 0
		];
		kDefaultPaletteChunk.contentsHandle = kDefaultPaletteContents;
    });
	
}

- (instancetype)initUsingDataInitializer:(void (^)(void))dataInitializer
{
	self = [super init];
	if (self == nil)
		return nil;
	
	dataInitializer();
	[self parseData];
	
	return self;
}

- (void)dealloc
{
	[_rootChunk release];
	[_data release];
	
	[super dealloc];
}

- (void)parseData
{
	_magicNumber_ptr = (MagicNumber){
		.ptr = (uint8_t const *)&_data.bytes[kMagicNumber_Offset]
	};
	
	_versionNumber_ptr = (uint32_t const *)&_data.bytes[kVersionNumber_Offset];
	
	// @fixme: This may cause retain cycles of `chunkParser`.  The solution I've found to prevent this is the `__weak` attribute, which isn't allowed in MRC.
	__block ChunkHandle * (^chunkParser)(ptrdiff_t) = ^(ptrdiff_t startOffset)
	{
		ChunkContentsParserB contentsParser = ^id (ChunkIdent ident, ptrdiff_t contentsStartOffset, uint32_t size)
		{
			NSData *contentsData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[contentsStartOffset] length:size freeWhenDone:NO];
			NSLog(@"Parsing contents of size %d for chunk ID %@:\n\t%@",
				size, NSStringFromChunkIdent(ident), contentsData
			);
			
			if (*ident.fourCharCode == *kSizeChunkIdent.fourCharCode)
				return [self parseSizeContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kVoxelChunkIdent.fourCharCode)
				return [self parseVoxelContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kPaletteChunkIdent.fourCharCode)
				return [self parsePaletteContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else
				@throw [NSException exceptionWithName: NSInvalidArgumentException
					reason: [NSString stringWithFormat:@"Unknown chunk ID %c%c%c%c.", (*ident.array)[0], (*ident.array)[1], (*ident.array)[2], (*ident.array)[3]]
					userInfo: nil
				];
		};
		ChunkChildParserB childParser = ^(ChunkIdent parentIdent, ptrdiff_t childStartOffset, uint32_t remainingSizeAllowance, ptrdiff_t *out_endOffset)
		{
			NSData *childData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[childStartOffset] length:remainingSizeAllowance freeWhenDone:NO];
			NSLog(@"Parsing child of chunk ID %@:\n\t%@",
				NSStringFromChunkIdent(parentIdent), childData
			);
			
			ChunkHandle *childChunk = chunkParser(childStartOffset);
			
			if (out_endOffset != NULL)
				*out_endOffset = (ptrdiff_t)(childStartOffset + childChunk.totalSize);
			return childChunk;
		};
		
		return [self parseChunkDataAtOffset:startOffset withContentsParser:contentsParser childParser:childParser];
	};
	_rootChunk = chunkParser(kRootChunk_Offset);
}

- (ChunkHandle *)parseChunkDataAtOffset:(ptrdiff_t)baseOffset withContentsParser:(ChunkContentsParserB)contentsParser childParser:(ChunkChildParserB)childParser
{
	ChunkHandle *chunk = [[ChunkHandle alloc] initWithData:_data offset:baseOffset];
	
	NSLog(@"Parsing chunk ID %@, with contents sized %d, and children sized %d.",
		NSStringFromChunkIdent(chunk.ident), chunk.contentsSize, chunk.childrenTotalSize
	);
	
	uint32_t contentsSize = chunk.contentsSize;
	if (contentsSize > 0)
		chunk.contentsHandle = contentsParser(chunk.ident, chunk.contents_offset, contentsSize);
	
	uint32_t childrenTotalSize = chunk.childrenTotalSize;
	if (childrenTotalSize > 0) {
		ptrdiff_t const childrenOffset = chunk.children_offset;
		
		ptrdiff_t childOffset = childrenOffset;
		size_t childrenRemainingSize = childrenTotalSize;
		do {
			ptrdiff_t endOffset;
			ChunkHandle *childChunk = childParser(chunk.ident, childOffset, childrenRemainingSize, &endOffset);
			chunk.childrenChunks[NSStringFromChunkIdent(childChunk.ident)] = childChunk;
			
			size_t childrenSizeParsedThusFar = endOffset - childrenOffset;
			if (!(childrenSizeParsedThusFar + kChunkPadding_MaxSize < childrenTotalSize))
				break;
			
			childOffset = endOffset;
			childrenRemainingSize = childrenTotalSize - childrenSizeParsedThusFar;
			// @assert: childrenRemainingSize^new == childrenRemainingSize^old - (endOffset^old - childOffset^old)
		} while (true);
	}
	
	return chunk;
}

- (SizeChunkContentsHandle *)parseSizeContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	return [[[SizeChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
}

- (VoxelChunkContentsHandle *)parseVoxelContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	return [[[VoxelChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
}

- (PaletteChunkContentsHandle *)parsePaletteContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	return [[[PaletteChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
}

- (MagicNumber)magicNumber; {
	return _magicNumber_ptr;
}

- (uint32_t)versionNumber; {
	return *_versionNumber_ptr;
}

- (MagicaVoxelVoxData_XYZDimensions)dimensions
{
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kSizeChunkIdent_string)];
	if (!chunkHandle)
		return (MagicaVoxelVoxData_XYZDimensions){ 0, 0, 0 };
	
	SizeChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return (MagicaVoxelVoxData_XYZDimensions){ 0, 0, 0 };
	
	return *(MagicaVoxelVoxData_XYZDimensions *)*chunkContents.xyzSize_ptr;
}

- (MagicaVoxelVoxData_PaletteColor *)paletteColors_array
{
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kPaletteChunkIdent_string)];
	if (!chunkHandle)
		chunkHandle = kDefaultPaletteChunk;
	
	PaletteChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return NULL;
	
	return (MagicaVoxelVoxData_PaletteColor *)chunkContents.colors_array;
}

- (NSUInteger)paletteColors_count {
	return 255; // last color is unused
}

- (MagicaVoxelVoxData_Voxel *)voxels_array
{
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kVoxelChunkIdent_string)];
	if (!chunkHandle)
		return NULL;
	
	VoxelChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return NULL;
	
	return (MagicaVoxelVoxData_Voxel *)chunkContents.voxels_array;
}

- (NSUInteger)voxels_count
{
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kVoxelChunkIdent_string)];
	if (!chunkHandle)
		return 0;
	
	VoxelChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return 0;
	
	return chunkContents.numVoxels;
}

- (BOOL)isValid
{
	if (_data.length < (kVersionNumber_Offset + kVersionNumber_Size)) // @tmp: Assuming no chunks; need to be improved considerably.
		return NO;
	
	if (*self.magicNumber.fourCharCode != *kValidMagicNumber.fourCharCode)
		return NO;
	
	if (!(self.versionNumber >= 150))
		return NO;
	
	return YES; // @tmp: Should actually do some checks plz.
}


- (NSError *)invalidDataErrorForActionVerb:(NSString *)attemptedActionVerb
{
	return [NSError errorWithDomain:@"MDLVoxelAsset" code:1 userInfo:@{
		NSLocalizedDescriptionKey: [NSString stringWithFormat:@"This %@ instance contains invalid data; refusing to %@.",
			self.class, attemptedActionVerb
		],
		NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The %@ instance does not contain valid data for the MagicaVoxel .vox format." @"\n\t" @"Spec here: %@",
			self.class, @"http://ephtracy.github.io/index.html?page=mv_vox_format"
		]
	}];
}


#pragma mark NSData-Mirroring Interface

-(NSUInteger)length { return _data.length; }


@end



@implementation MagicaVoxelVoxData (ExtendedData)

-(NSString *)description {
	return [_data description]; // @tmp: This should be MagicaVoxelVoxData-specific
}

- (BOOL)isEqualToData:(NSData *)other {
	return [_data isEqualToData:other];
}


#pragma mark Output

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
	if (!self.valid)
		return NO;
	
	return [_data writeToFile:path atomically:useAuxiliaryFile];
}

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically
{
	if (!self.valid)
		return NO;
	
	return [_data writeToURL:url atomically:atomically];
}

- (BOOL)writeToFile:(NSString *)path options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr
{
	if (!self.valid) {
		*errorPtr = [self.class invalidDataErrorForActionVerb:@"write to file"];
		return NO;
	}
	
	return [_data writeToFile:path options:writeOptionsMask error:errorPtr];
}

- (BOOL)writeToURL:(NSURL *)url options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr
{
	if (!self.valid) {
		*errorPtr = [self.class invalidDataErrorForActionVerb:@"write to URL"];
		return NO;
	}
	
	return [_data writeToURL:url options:writeOptionsMask error:errorPtr];
}

@end

@implementation MagicaVoxelVoxData (DataCreation)

#pragma mark Initializers

+ (instancetype)dataWithBytes:(nullable const void *)bytes length:(NSUInteger)length {
	return [[[ThisClass alloc] initWithBytes:bytes length:length] autorelease];
}
- (instancetype)initWithBytes:(nullable const void *)bytes length:(NSUInteger)length {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBytes:bytes length:length];
	}];
}

+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length {
	return [[[ThisClass alloc] initWithBytesNoCopy:bytes length:length] autorelease];
}
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBytesNoCopy:bytes length:length];
	}];
}

+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b {
	return [[[ThisClass alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:b] autorelease];
}
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:b];
	}];
}

- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length deallocator:(nullable void (^)(void *bytes, NSUInteger length))deallocator {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBytesNoCopy:bytes length:length deallocator:deallocator];
	}];
}

+ (nullable instancetype)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr {
	return [[[ThisClass alloc] initWithContentsOfFile:path options:readOptionsMask error:errorPtr] autorelease];
}
- (nullable instancetype)initWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithContentsOfFile:path options:readOptionsMask error:errorPtr];
	}];
}

+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr {
	return [[[ThisClass alloc] initWithContentsOfURL:url options:readOptionsMask error:errorPtr] autorelease];
}
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithContentsOfURL:url options:readOptionsMask error:errorPtr];
	}];
}

+ (nullable instancetype)dataWithContentsOfFile:(NSString *)path {
	return [[[ThisClass alloc] initWithContentsOfFile:path] autorelease];
}
- (nullable instancetype)initWithContentsOfFile:(NSString *)path {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithContentsOfFile:path];
	}];
}

+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url {
	return [[[ThisClass alloc] initWithContentsOfURL:url] autorelease];
}
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithContentsOfURL:url];
	}];
}

+ (instancetype)dataWithData:(NSData *)data {
	return [[[ThisClass alloc] initWithData:data] autorelease];
}
- (instancetype)initWithData:(NSData *)data {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithData:data];
	}];
}

@end

@implementation MagicaVoxelVoxData (DataBase64Encoding)

#pragma mark Initializers

- (nullable instancetype)initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBase64EncodedString:base64String options:options];
	}];
}
- (nullable instancetype)initWithBase64EncodedData:(NSData *)base64Data options:(NSDataBase64DecodingOptions)options {
	return [self initUsingDataInitializer:^() {
		_data = [[NSData alloc] initWithBase64EncodedData:base64Data options:options];
	}];
}

#pragma mark Output

- (NSString *)base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)options {
	return [_data base64EncodedStringWithOptions:options];
}

- (NSData *)base64EncodedDataWithOptions:(NSDataBase64EncodingOptions)options {
	return [_data base64EncodedDataWithOptions:options];
}

@end