// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData.h"



#if DEBUG
	void mvvdLog(NSString *format, ...)
	{
		va_list variadicArgs;
		va_start(variadicArgs, format);
		NSString *logString = [[[NSString alloc] initWithFormat:format arguments:variadicArgs] autorelease];
		printf("%s\n", logString.UTF8String);
		va_end(variadicArgs);
	}
#else
	void mvvdLog(NSString *format, ...) {}
#endif

#if DEBUG
	NSString *indentationStringOfLength(int length) {
		return [@"" stringByPaddingToLength:length withString:@"\t" startingAtIndex:0];
	}
#endif



typedef MagicaVoxelVoxData ThisClass;

typedef uint8_t FourCharDataArray[4];

typedef union _MagicNumber {
	FourCharDataArray const *array;
	uint8_t const *ptr;
	FourCharCode const *fourCharCode;
} MagicNumber; // @todo: Rename to MagicNumberDataPtr?

static const char kValidMagicNumber_string[] = "VOX ";
static const MagicNumber kValidMagicNumber = { .ptr = (uint8_t const *)&kValidMagicNumber_string };

static const ptrdiff_t kMagicNumber_offset = 0;
static const size_t kMagicNumber_size = 4;
static const ptrdiff_t kVersionNumber_offset = kMagicNumber_offset + kMagicNumber_size;
static const size_t kVersionNumber_size = 4;
static const ptrdiff_t kRootChunk_offset = kVersionNumber_offset + kVersionNumber_size;


#import "MagicaVoxelVoxData_ChunkIdent.h"

static const char kMainChunkIdent_string[] = "MAIN";
static const ChunkIdent kMainChunkIdent = { .ptr = (uint8_t const *)&kMainChunkIdent_string };
static const char kSizeChunkIdent_string[] = "SIZE";
static const ChunkIdent kSizeChunkIdent = { .ptr = (uint8_t const *)&kSizeChunkIdent_string };
static const char kVoxelChunkIdent_string[] = "XYZI";
static const ChunkIdent kVoxelChunkIdent = { .ptr = (uint8_t const *)&kVoxelChunkIdent_string };
static const char kPaletteChunkIdent_string[] = "RGBA";
static const ChunkIdent kPaletteChunkIdent = { .ptr = (uint8_t const *)&kPaletteChunkIdent_string };
static const char kMaterialOldChunkIdent_string[] = "MATT";
static const ChunkIdent kMaterialOldChunkIdent = { .ptr = (uint8_t const *)&kMaterialOldChunkIdent_string };
static const char kPackChunkIdent_string[] = "PACK";
static const ChunkIdent kPackChunkIdent = { .ptr = (uint8_t const *)&kPackChunkIdent_string };
static const char kTransformNodeChunkIdent_string[] = "nTRN";
static const ChunkIdent kTransformNodeChunkIdent = { .ptr = (uint8_t const *)&kTransformNodeChunkIdent_string };
static const char kGroupNodeChunkIdent_string[] = "nGRP";
static const ChunkIdent kGroupNodeChunkIdent = { .ptr = (uint8_t const *)&kGroupNodeChunkIdent_string };
static const char kShapeNodeChunkIdent_string[] = "nSHP";
static const ChunkIdent kShapeNodeChunkIdent = { .ptr = (uint8_t const *)&kShapeNodeChunkIdent_string };
static const char kLayerChunkIdent_string[] = "LAYR";
static const ChunkIdent kLayerChunkIdent = { .ptr = (uint8_t const *)&kLayerChunkIdent_string };
static const char kMaterialChunkIdent_string[] = "MATL";
static const ChunkIdent kMaterialChunkIdent = { .ptr = (uint8_t const *)&kMaterialChunkIdent_string };
static const char kRObjChunkIdent_string[] = "rOBJ";
static const ChunkIdent kRObjChunkIdent = { .ptr = (uint8_t const *)&kRObjChunkIdent_string };


#import "MagicaVoxelVoxData_SizeChunkContentsHandle.h"
#import "MagicaVoxelVoxData_VoxelChunkContentsHandle.h"
#import "MagicaVoxelVoxData_PaletteChunkContentsHandle.h"
#import "MagicaVoxelVoxData_PackChunkContentsHandle.h"
#import "MagicaVoxelVoxData_TransformNodeChunkContentsHandle.h"
#import "MagicaVoxelVoxData_GroupNodeChunkContentsHandle.h"
#import "MagicaVoxelVoxData_ShapeNodeChunkContentsHandle.h"


#import "MagicaVoxelVoxData_ChunkHandle.h"

static const size_t kChunkPaddingMaxSize = 1;

//static const RGBAValuesDataArray kDefaultPaletteRGBAValues[256] = ;
static PaletteChunkContentsHandle *kDefaultPaletteContents;
struct {
	FourCharDataArray ident;
	uint32_t contentsSize;
	uint32_t childrenTotalSize;;
	RGBAValuesData contents[256];
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
typedef ChunkHandle * (^ChunkChildParserB)(ChunkIdent parentIdent, ptrdiff_t startOffset, size_t remainingSizeAllowance, ptrdiff_t *out_endOffset);



@interface MagicaVoxelVoxData () {
	NSData *_data;
	
	MagicNumber _magicNumber_ptr;
	uint32_t const *_versionNumber_ptr;
	
	ChunkHandle *_rootChunk;
	
	uint32_t _modelCount;
	
	MagicaVoxelVoxData_TransformNode *_sceneGraphRootNode;
}

- (instancetype)initUsingDataInitializer:(void (^)(void))dataInitializer;

- (MagicNumber)magicNumber;

- (void)calculateModelCount;
@end



@implementation MagicaVoxelVoxData

@synthesize nsData=_data;
@synthesize modelCount=_modelCount;
@synthesize sceneGraphRootNode=_sceneGraphRootNode;


+ (void)initialize
{
	static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
		
		kDefaultPaletteChunk = [[ChunkHandle alloc]
			initWithData: [NSData dataWithBytes:&kDefaultPaletteData length:sizeof(kDefaultPaletteData)]
			offset: 0
		];
		kDefaultPaletteContents = [[PaletteChunkContentsHandle alloc]
			initWithData: [NSData dataWithBytes:&kDefaultPaletteData.contents length:sizeof(kDefaultPaletteData.contents)]
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
	[_sceneGraphRootNode release];
	
	[super dealloc];
}

#if DEBUG
	static int DEBUG_sParseDepth = 0;
#endif

- (void)parseData
{
	_magicNumber_ptr = (MagicNumber){
		.ptr = (uint8_t const *)&_data.bytes[kMagicNumber_offset]
	};
	
	_versionNumber_ptr = (uint32_t const *)&_data.bytes[kVersionNumber_offset];
	
	// @fixme: This may cause retain cycles of `chunkParser`.  The solution I've found to prevent this is the `__weak` attribute, which isn't allowed in MRC.
	__block ChunkHandle * (^chunkParser)(ptrdiff_t) = ^(ptrdiff_t startOffset)
	{
		ChunkContentsParserB contentsParser = ^id (ChunkIdent ident, ptrdiff_t contentsStartOffset, uint32_t size)
		{
			#if DEBUG
				NSData *contentsData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[contentsStartOffset] length:size freeWhenDone:NO];
				NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
				mvvdLog(@"%@Parsing chunk ID %@'s contents (of size %d):\n" @"%@\tData: %@",
					indentationString, NSStringFromChunkIdent(ident), size,
					indentationString, contentsData
				);
			#endif
			
			if (*ident.fourCharCode == *kSizeChunkIdent.fourCharCode)
				return [self parseSizeContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kVoxelChunkIdent.fourCharCode)
				return [self parseVoxelContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kPaletteChunkIdent.fourCharCode)
				return [self parsePaletteContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kMaterialOldChunkIdent.fourCharCode)
				return nil; // materials ignored for now
			else if (*ident.fourCharCode == *kPackChunkIdent.fourCharCode)
				return [self parsePackContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kTransformNodeChunkIdent.fourCharCode)
				return [self parseTransformNodeContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kGroupNodeChunkIdent.fourCharCode)
				return [self parseGroupNodeContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kShapeNodeChunkIdent.fourCharCode)
				return [self parseShapeNodeContentsDataAtOffset:contentsStartOffset withDataSize:size];
			else if (*ident.fourCharCode == *kLayerChunkIdent.fourCharCode)
				return nil; // Mysterious “LAYR” chunk, found in newer vox files.  Isn't in the spec, so I don't know what it is nor how to parse it.
			else if (*ident.fourCharCode == *kMaterialChunkIdent.fourCharCode)
				return nil; // Mysterious “MATL” chunk, found in newer vox files.  Isn't in the spec, so I don't know what it is nor how to parse it.
			else if (*ident.fourCharCode == *kRObjChunkIdent.fourCharCode)
				return nil; // Mysterious “rObj” chunk, found in newer vox files.  Isn't in the spec, so I don't know what it is nor how to parse it.
			else
				@throw [NSException exceptionWithName: NSInvalidArgumentException
					reason: [NSString stringWithFormat:@"Unknown chunk ID %c%c%c%c.", (*ident.array)[0], (*ident.array)[1], (*ident.array)[2], (*ident.array)[3]]
					userInfo: nil
				];
		};
		ChunkChildParserB childParser = ^(ChunkIdent parentIdent, ptrdiff_t childStartOffset, size_t remainingSizeAllowance, ptrdiff_t *out_endOffset)
		{
			#if DEBUG
				NSData *childData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[childStartOffset] length:remainingSizeAllowance freeWhenDone:NO];
				NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
				mvvdLog(@"%@Parsing child of chunk ID %@:\n" @"%@\tData: %@",
					indentationString, NSStringFromChunkIdent(parentIdent),
					indentationString, childData
				);
				
				int preexistingParseDepth = DEBUG_sParseDepth;
				++DEBUG_sParseDepth;
			#endif
			
			ChunkHandle *childChunk = chunkParser(childStartOffset);
			
			#if DEBUG
				DEBUG_sParseDepth = preexistingParseDepth;
			#endif
			
			if (out_endOffset != NULL)
				*out_endOffset = (ptrdiff_t)(childStartOffset + childChunk.totalSize);
			return childChunk;
		};
		
		return [self parseChunkDataAtOffset:startOffset withContentsParser:contentsParser childParser:childParser];
	};
	
	#if DEBUG
		DEBUG_sParseDepth = 0;
	#endif
	_rootChunk = [chunkParser(kRootChunk_offset) retain];
	
	[self calculateModelCount];
	
	
	TransformNodeChunkContentsHandle *rootTransformNodeContents = [self transformNodeForNodeID:0];
	if (rootTransformNodeContents)
		_sceneGraphRootNode = [[self sceneGraphNodeForTransformChunkContents:rootTransformNodeContents] retain];
}

- (ChunkHandle *)parseChunkDataAtOffset:(ptrdiff_t)baseOffset withContentsParser:(ChunkContentsParserB)contentsParser childParser:(ChunkChildParserB)childParser
{
	ChunkHandle *chunk = [[ChunkHandle alloc] initWithData:_data offset:baseOffset];
	
	#if DEBUG
		NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
		mvvdLog(@"%@Parsing chunk ID %@ (with contents sized %d; children sized %d).",
			indentationString, NSStringFromChunkIdent(chunk.ident), chunk.contentsSize, chunk.childrenTotalSize
		);
		
		int preexistingParseDepth = DEBUG_sParseDepth;
		++DEBUG_sParseDepth;
	#endif
	
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
			[chunk addChildChunk:NSStringFromChunkIdent(childChunk.ident) handle:childChunk];
			
			size_t childrenSizeParsedThusFar = endOffset - childrenOffset;
			if (!(childrenSizeParsedThusFar + kChunkPaddingMaxSize < childrenTotalSize))
				break;
			
			childOffset = endOffset;
			childrenRemainingSize = childrenTotalSize - childrenSizeParsedThusFar;
			// @assert: childrenRemainingSize^new == childrenRemainingSize^old - (endOffset^old - childOffset^old)
		} while (true);
	}
	
	#if DEBUG
		DEBUG_sParseDepth = preexistingParseDepth;
	#endif
	
	return [chunk autorelease];
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

- (PackChunkContentsHandle *)parsePackContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	return [[[PackChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
}

- (TransformNodeChunkContentsHandle *)parseTransformNodeContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	TransformNodeChunkContentsHandle *transformNodeContents = [[[TransformNodeChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
	#if DEBUG
		int preexistingParseDepth = DEBUG_sParseDepth;
		++DEBUG_sParseDepth;
		NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
		
		mvvdLog(@"%@nodeID: %d", indentationString, transformNodeContents.nodeID);
		
		NSDictionary<NSString*,NSString*> *nodeAttributes = NSDictionaryFromVoxDict(transformNodeContents.nodeAttributes);
		mvvdLog(@"%@nodeAttributes: %@", indentationString, [nodeAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
		mvvdLog(@"%@nodeAttributesName: %@", indentationString, NSStringFromVoxString(transformNodeContents.nodeAttributeName));
		mvvdLog(@"%@nodeAttributesHidden: %@", indentationString, @(transformNodeContents.nodeAttributeHidden));
		
		for (int frameI = 0; frameI < transformNodeContents.numFrames; ++frameI) {
			NSDictionary<NSString*,NSString*> *frameAttributes = NSDictionaryFromVoxDict([transformNodeContents frameAttributesForFrame:frameI]);
			mvvdLog(@"%@frameAttributes[%d]: %@", indentationString, frameI, [frameAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
			simd_int3 translation = [transformNodeContents frameAttributeSIMDTranslationForFrame:frameI];
			mvvdLog(@"%@frameAttributes[%d] SIMDTranslation: (x: %d, y: %d, z: %d)", indentationString, frameI, translation.x, translation.y, translation.z);
			simd_float3x3 rotation = [transformNodeContents frameAttributeSIMDRotationForFrame:frameI];
			mvvdLog(@"%@frameAttributes[%d] SIMDRotation: (00: %f, 01: %f, 02: %f, 10: %f, 11: %f, 12: %f, 20: %f, 21: %f, 22: %f)", indentationString, frameI,
				rotation.columns[0][0], rotation.columns[0][1], rotation.columns[0][2],
				rotation.columns[1][0], rotation.columns[1][1], rotation.columns[2][2],
				rotation.columns[2][0], rotation.columns[2][1], rotation.columns[2][2]
			);
		}
		
		DEBUG_sParseDepth = preexistingParseDepth;
	#endif
	
	return transformNodeContents;
}

- (GroupNodeChunkContentsHandle *)parseGroupNodeContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	GroupNodeChunkContentsHandle *groupNodeContents = [[[GroupNodeChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
	#if DEBUG
		int preexistingParseDepth = DEBUG_sParseDepth;
		++DEBUG_sParseDepth;
		NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
		
		mvvdLog(@"%@nodeID: %d", indentationString, groupNodeContents.nodeID);
		
		NSDictionary<NSString*,NSString*> *nodeAttributes = NSDictionaryFromVoxDict(groupNodeContents.nodeAttributes);
		mvvdLog(@"%@nodeAttributes: %@", indentationString, [nodeAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
		
		DEBUG_sParseDepth = preexistingParseDepth;
	#endif
	
	return groupNodeContents;
}

- (ShapeNodeChunkContentsHandle *)parseShapeNodeContentsDataAtOffset:(ptrdiff_t)offset withDataSize:(uint32_t)size
{
	ShapeNodeChunkContentsHandle *shapeNodeContents = [[[ShapeNodeChunkContentsHandle alloc] initWithData:_data offset:offset] autorelease];
	#if DEBUG
		int preexistingParseDepth = DEBUG_sParseDepth;
		++DEBUG_sParseDepth;
		NSString *indentationString = indentationStringOfLength(DEBUG_sParseDepth);
		
		mvvdLog(@"%@nodeID: %d", indentationString, shapeNodeContents.nodeID);
		
		NSDictionary<NSString*,NSString*> *nodeAttributes = NSDictionaryFromVoxDict(shapeNodeContents.nodeAttributes);
		mvvdLog(@"%@nodeAttributes: %@", indentationString, [nodeAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
		
		for (int modelI = 0; modelI < shapeNodeContents.numModels; ++modelI) {
			int32_t modelID = [shapeNodeContents modelIDForModel:modelI];
			mvvdLog(@"%@modelIDs[%d]: %d", indentationString, modelI, modelID);
			
			NSDictionary<NSString*,NSString*> *modelAttributes = NSDictionaryFromVoxDict([shapeNodeContents modelAttributesForModel:modelI]);
			mvvdLog(@"%@modelAttributes[%d]: %@", indentationString, modelI, [modelAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
		}
		
		DEBUG_sParseDepth = preexistingParseDepth;
	#endif
	
	return shapeNodeContents;
}

- (MagicNumber)magicNumber; {
	return _magicNumber_ptr;
}

- (uint32_t)versionNumber; {
	return *_versionNumber_ptr;
}

- (void)calculateModelCount
{
	NSArray<ChunkHandle*>* sizeChunks = _rootChunk.childrenChunks[@(kSizeChunkIdent_string)];
	NSArray<ChunkHandle*>* voxelChunks = _rootChunk.childrenChunks[@(kVoxelChunkIdent_string)];
	
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kPackChunkIdent_string)].firstObject;
	if (chunkHandle) {
		PackChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
		if (!chunkContents) {
			_modelCount = 0; return;
		}
		
		_modelCount = chunkContents.numModels;
		
		NSParameterAssert(sizeChunks.count == _modelCount);
		NSParameterAssert(voxelChunks.count == _modelCount);
	}
	else { // model count deduced from number of size/voxel chunks
		NSParameterAssert(sizeChunks.count == voxelChunks.count);
		_modelCount = (uint32_t)sizeChunks.count;
	}
}

- (MagicaVoxelVoxData_XYZDimensions)dimensionsForModelID:(uint32_t)modelID
{
	NSParameterAssert(modelID >= 0 && modelID < _modelCount);
	
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kSizeChunkIdent_string)][modelID];
	if (!chunkHandle)
		return (MagicaVoxelVoxData_XYZDimensions){ 0, 0, 0 };
	
	SizeChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return (MagicaVoxelVoxData_XYZDimensions){ 0, 0, 0 };
	
	return *(MagicaVoxelVoxData_XYZDimensions *)*chunkContents.xyzSize_ptr;
}

- (MagicaVoxelVoxData_VoxelArray)voxelsForModelID:(uint32_t)modelID
{
	NSParameterAssert(modelID >= 0 && modelID < _modelCount);
	
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kVoxelChunkIdent_string)][modelID];
	if (!chunkHandle)
		return kMagicaVoxelVoxData_VoxelArray_invalidSentinel;
	
	VoxelChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return kMagicaVoxelVoxData_VoxelArray_invalidSentinel;
	
	return (MagicaVoxelVoxData_VoxelArray){
		.count = chunkContents.numVoxels,
		.array = (MagicaVoxelVoxData_Voxel *)chunkContents.voxels
	};
}

- (MagicaVoxelVoxData_PaletteColorArray)paletteColors
{
	ChunkHandle *chunkHandle = _rootChunk.childrenChunks[@(kPaletteChunkIdent_string)].firstObject;
	if (!chunkHandle)
		chunkHandle = kDefaultPaletteChunk;
	
	PaletteChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
	if (!chunkContents)
		return kMagicaVoxelVoxData_PaletteColorArray_invalidSentinel;
	
	return (MagicaVoxelVoxData_PaletteColorArray){
		.count = 255, // last color is unused
		.array = (MagicaVoxelVoxData_PaletteColor *)chunkContents.colors
	};
}

- (MagicaVoxelVoxData_ShapeNode *)sceneGraphNodeForShapeChunkContents:(ShapeNodeChunkContentsHandle *)chunkContents
{
	MagicaVoxelVoxData_ShapeNode *node = [MagicaVoxelVoxData_ShapeNode new];
	
	int modelCount = chunkContents.models_count;
	NSMutableArray<MagicaVoxelVoxData_Model*> *models = [[NSMutableArray alloc] initWithCapacity:modelCount];
	for (int modelI = 0; modelI < modelCount; ++modelI) {
		MagicaVoxelVoxData_Model *model = [MagicaVoxelVoxData_Model new];
		model.modelID = [chunkContents modelIDForModel:modelI];
		
		[models addObject:model];
		[model release];
	}
	node.models = models;
	[models release];
	
	return [node autorelease];
}

- (MagicaVoxelVoxData_GroupNode *)sceneGraphNodeForGroupChunkContents:(GroupNodeChunkContentsHandle *)chunkContents
{
	MagicaVoxelVoxData_GroupNode *node = [MagicaVoxelVoxData_GroupNode new];
	
	int childCount = chunkContents.childNodes_count;
	NSMutableArray<MagicaVoxelVoxData_TransformNode*> *childrenNodes = [[NSMutableArray alloc] initWithCapacity:childCount];
	GroupNodeChunkContentsHandle_Child const *childChunkDatums = chunkContents.childNodes;
	for (int childI = 0; childI < childCount; ++childI) {
		int32_t childNodeID = childChunkDatums[childI].childID;
		
		TransformNodeChunkContentsHandle *transformChunkContents = [self transformNodeForNodeID:childNodeID];
		if (!transformChunkContents) {
			NSLog(@"Error: Unexpectedly could not find TransformNodeChunkContentsHandle #%d child of GroupNodeChunkContentsHandle #%d.", childNodeID, chunkContents.nodeID);
			continue;
		}
		
		MagicaVoxelVoxData_TransformNode *childNode = [self sceneGraphNodeForTransformChunkContents:transformChunkContents];
		[childrenNodes addObject:childNode];
	}
	node.childrenNodes = childrenNodes;
	[childrenNodes release];
	
	return [node autorelease];
}

- (MagicaVoxelVoxData_TransformNode *)sceneGraphNodeForTransformChunkContents:(TransformNodeChunkContentsHandle *)chunkContents
{
	MagicaVoxelVoxData_TransformNode *node = [MagicaVoxelVoxData_TransformNode new];
	
	node.name = NSStringFromVoxString(chunkContents.nodeAttributeName);
	node.hidden = chunkContents.nodeAttributeHidden;
	
	int frameCount = chunkContents.frames_count;
	NSMutableArray<MagicaVoxelVoxData_Frame*> *frames = [[NSMutableArray alloc] initWithCapacity:frameCount];
	for (int frameI = 0; frameI < frameCount; ++frameI) {
		MagicaVoxelVoxData_Frame *frame = [MagicaVoxelVoxData_Frame new];
		frame.translation = [chunkContents frameAttributeSIMDTranslationForFrame:frameI];
		frame.rotation = [chunkContents frameAttributeSIMDRotationForFrame:frameI];
		
		[frames addObject:frame];
		[frame release];
	}
	node.frames = frames;
	[frames release];
	
	int32_t childNodeID = chunkContents.childNodeID;
	do {
		GroupNodeChunkContentsHandle *groupChunkContents = [self groupNodeForNodeID:childNodeID];
		if (groupChunkContents) {
			node.childNode = [self sceneGraphNodeForGroupChunkContents:groupChunkContents];
			break;
		}
		ShapeNodeChunkContentsHandle *shapeChunkContents = [self shapeNodeForNodeID:childNodeID];
		if (shapeChunkContents) {
			node.childNode = [self sceneGraphNodeForShapeChunkContents:shapeChunkContents];
			break;
		}
		// else:
		NSLog(@"Error: Unexpectedly could not find GroupNodeChunkContentsHandle or ShapeNodeChunkContentsHandle #%d child of TransformNodeChunkContentsHandle #%d.", childNodeID, chunkContents.nodeID);
	} while (0);
	
	return [node autorelease];
}

- (MagicaVoxelVoxData_TransformNode *)sceneGraphRootNode {
	return [[_sceneGraphRootNode copy] autorelease];
}

- (TransformNodeChunkContentsHandle *)transformNodeForNodeID:(uint32_t)nodeID
{
	NSArray<ChunkHandle*> *chunkHandles = _rootChunk.childrenChunks[@(kTransformNodeChunkIdent_string)];
	if (!chunkHandles)
		return nil;
	
	for (ChunkHandle *chunkHandle in chunkHandles) {
		TransformNodeChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
		if (!chunkContents)
			continue;
		
		if (chunkContents.nodeID == nodeID)
			return chunkContents;
	}
	
	return nil; // `nodeID` not found
}

- (GroupNodeChunkContentsHandle *)groupNodeForNodeID:(uint32_t)nodeID
{
	NSArray<ChunkHandle*> *chunkHandles = _rootChunk.childrenChunks[@(kGroupNodeChunkIdent_string)];
	if (!chunkHandles)
		return nil;
	
	for (ChunkHandle *chunkHandle in chunkHandles) {
		GroupNodeChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
		if (!chunkContents)
			continue;
		
		if (chunkContents.nodeID == nodeID)
			return chunkContents;
	}
	
	return nil; // `nodeID` not found
}

- (ShapeNodeChunkContentsHandle *)shapeNodeForNodeID:(uint32_t)nodeID
{
	NSArray<ChunkHandle*> *chunkHandles = _rootChunk.childrenChunks[@(kShapeNodeChunkIdent_string)];
	if (!chunkHandles)
		return nil;
	
	for (ChunkHandle *chunkHandle in chunkHandles) {
		ShapeNodeChunkContentsHandle *chunkContents = chunkHandle.contentsHandle;
		if (!chunkContents)
			continue;
		
		if (chunkContents.nodeID == nodeID)
			return chunkContents;
	}
	
	return nil; // `nodeID` not found
}

- (BOOL)isValid
{
	if (_data.length < (kVersionNumber_offset + kVersionNumber_size)) // @tmp: Assuming no chunks; need to be improved considerably.
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


#pragma mark NSCopying Conformance


- (nonnull id)copyWithZone:(nullable NSZone *)zone_unused { 
	return [self retain]; // MagicaVoxelVoxData is immutable, so this is valid & expected.
}

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
		if (errorPtr)
			*errorPtr = [self.class invalidDataErrorForActionVerb:@"write to file"];
		return NO;
	}
	
	return [_data writeToFile:path options:writeOptionsMask error:errorPtr];
}

- (BOOL)writeToURL:(NSURL *)url options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr
{
	if (!self.valid) {
		if (errorPtr)
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
