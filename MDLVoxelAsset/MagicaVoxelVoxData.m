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

static const ptrdiff_t kChunkId_ChunkOffset = 0;
static const size_t kChunkId_Size = 4;
static const ptrdiff_t kChunkContentsSize_ChunkOffset = kChunkId_ChunkOffset + kChunkId_Size;
static const size_t kChunkContentsSize_Size = 4;
static const ptrdiff_t kChunkChildrenTotalSize_ChunkOffset = kChunkContentsSize_ChunkOffset + kChunkContentsSize_Size;
static const size_t kChunkChildrenTotalSize_Size = 4;
static const ptrdiff_t kChunkContentsOrChildren_Offset = kChunkChildrenTotalSize_ChunkOffset + kChunkChildrenTotalSize_Size;

typedef union _ChunkId {
	FourCharDataArray const *array;
	uint8_t const *ptr;
	FourCharCode const *fourCharCode;
} ChunkId; // @todo: Rename ChunkIdDataPtr?

typedef struct _ChunkHandle {
	ChunkId id;
	int32_t const *contentsSize;
	int32_t const *childrenTotalSize;
	void const *contents;
	void const *children;
} ChunkHandle;

/// The total size of the chunk.  Calculated as:
///		The size of the ID (4 bytes) + the contents-size field (4 bytes) + the children-total-size field (4 bytes) + the size of the contents + the size of the children.
size_t getChunkTotalSize(ChunkHandle chunk) {
	return offsetof(ChunkHandle, contents) + *chunk.contentsSize + *chunk.childrenTotalSize;
}

static const char kMainChunkId_string[] = "MAIN";
static const ChunkId kMainChunkId = { .ptr = (uint8_t const *)&kMainChunkId_string };
static const char kSizeChunkId_string[] = "SIZE";
static const ChunkId kSizeChunkId = { .ptr = (uint8_t const *)&kSizeChunkId_string };
static const char kVoxelChunkId_string[] = "XYZI";
static const ChunkId kVoxelChunkId = { .ptr = (uint8_t const *)&kVoxelChunkId_string };
static const char kPaletteChunkId_string[] = "RGBA";
static const ChunkId kPaletteChunkId = { .ptr = (uint8_t const *)&kPaletteChunkId_string };

typedef void(^ChunkContentsParserB)(ChunkId id, ptrdiff_t startOffset, int32_t size);
/// @return: endOffset; potentially the `startOffset` of the next chunk.
typedef ptrdiff_t(^ChunkChildParserB)(ChunkId parentId, ptrdiff_t startOffset, int32_t remainingSizeAllowance);



@interface MagicaVoxelVoxData () {
	NSData *_data;
	
	MagicNumber _magicNumber_ptr;
	int32_t const *_versionNumber_ptr;
	
	ChunkHandle _rootChunk;
}

- (instancetype)initUsingDataInitializer:(void (^)(void))dataInitializer;

- (MagicNumber)magicNumber;

@end



@implementation MagicaVoxelVoxData

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
	[_data release];
	
	[super dealloc];
}

- (void)parseData
{
	_magicNumber_ptr = (MagicNumber){
		.ptr = (uint8_t const *)&_data.bytes[kMagicNumber_Offset]
	};
	
	_versionNumber_ptr = (int32_t const *)&_data.bytes[kVersionNumber_Offset];
	
	// @fixme: This may cause retain cycles of `chunkParser`.  The solution I've found to prevent this is the `__weak` attribute, which isn't allowed in MRC.
	__block ChunkHandle (^chunkParser)(ptrdiff_t) = ^(ptrdiff_t startOffset)
	{
		ChunkContentsParserB contentsParser = ^(ChunkId id, ptrdiff_t contentsStartOffset, int32_t size)
		{
			NSData *contentsData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[contentsStartOffset] length:size freeWhenDone:NO];
			NSLog(@"Parsing contents of size %d for chunk ID %@:\n\t%@",
				size,
				[NSString stringWithFormat:@"%c%c%c%c", (*id.array)[0], (*id.array)[1], (*id.array)[2], (*id.array)[3]],
				contentsData
			);
		};
		ChunkChildParserB childParser = ^(ChunkId parentId, ptrdiff_t childStartOffset, int32_t remainingSizeAllowance)
		{
			NSData *childData = [NSData dataWithBytesNoCopy:(void *)&_data.bytes[childStartOffset] length:remainingSizeAllowance freeWhenDone:NO];
			NSLog(@"Parsing child of chunk ID %@:\n\t%@",
				[NSString stringWithFormat:@"%c%c%c%c", (*parentId.array)[0], (*parentId.array)[1], (*parentId.array)[2], (*parentId.array)[3]],
				childData
			);
			
			ChunkHandle childChunk = chunkParser(childStartOffset);
			return (ptrdiff_t)(childStartOffset + getChunkTotalSize(childChunk));
		};
		
		return [self parseChunkDataAtOffset:startOffset withContentsParser:contentsParser childParser:childParser];
	};
	_rootChunk = chunkParser(kRootChunk_Offset);
}

- (ChunkHandle)parseChunkDataAtOffset:(ptrdiff_t)baseOffset withContentsParser:(ChunkContentsParserB)contentsParser childParser:(ChunkChildParserB)childParser
{
	ChunkHandle chunk = (ChunkHandle) {
		.id = (ChunkId){
			.ptr = (uint8_t const *)&_data.bytes[baseOffset + kChunkId_ChunkOffset]
		},
		.contentsSize = (int32_t const *)&_data.bytes[baseOffset + kChunkContentsSize_ChunkOffset],
		.childrenTotalSize = (int32_t const *)&_data.bytes[baseOffset + kChunkChildrenTotalSize_ChunkOffset],
	};
	
	NSLog(@"Parsing chunk ID %@, with contents sized %d, and children sized %d.",
		[NSString stringWithFormat:@"%c%c%c%c", (*chunk.id.array)[0], (*chunk.id.array)[1], (*chunk.id.array)[2], (*chunk.id.array)[3]],
		*chunk.contentsSize,
		*chunk.childrenTotalSize
	);
	
	int32_t contentsSize = *chunk.contentsSize;
	if (contentsSize == 0) {
		chunk.contents = NULL;
	} else {
		ptrdiff_t const contentsOffset = baseOffset + kChunkContentsOrChildren_Offset;
		chunk.contents = &_data.bytes[contentsOffset];
		
		contentsParser(chunk.id, contentsOffset, contentsSize);
	}
	
	int32_t childrenTotalSize = *chunk.childrenTotalSize;
	if (childrenTotalSize == 0) {
		chunk.children = NULL;
	} else {
		ptrdiff_t const childrenOffset = baseOffset + kChunkContentsOrChildren_Offset;
		chunk.children = &_data.bytes[baseOffset + kChunkContentsOrChildren_Offset + contentsSize];
		
		ptrdiff_t childOffset = childrenOffset;
		size_t childrenRemainingSize = childrenTotalSize;
		do {
			ptrdiff_t endOffset = childParser(chunk.id, childOffset, childrenRemainingSize);
			size_t childrenSizeParsedThusFar = endOffset - childrenOffset;
			
			if (!(childrenSizeParsedThusFar < childrenTotalSize))
				break;
			
			childOffset = endOffset;
			childrenRemainingSize = childrenTotalSize - childrenSizeParsedThusFar;
			// @assert: childrenRemainingSize^new == childrenRemainingSize^old - (endOffset^old - childOffset^old)
		} while (true);
	}
	
	return chunk;
}

- (MagicNumber)magicNumber; {
	return _magicNumber_ptr;
}

- (int32_t)versionNumber; {
	return *_versionNumber_ptr;
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