//  MDLVoxelAsset.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import "MDLVoxelAsset.h"

#import "MagicaVoxelVoxData.h"

#import <GLKit/GLKMathUtils.h>
#import <SceneKit/ModelIO.h>
#import <SceneKit/SceneKitTypes.h>
#import <SceneKit/SCNGeometry.h>
#import <SceneKit/SCNMaterial.h>
#import <SceneKit/SCNMaterialProperty.h>
#import <SceneKit/SCNNode.h>
#import <SceneKit/SCNParametricGeometry.h>
#import <objc/message.h> // @for: objc_msgSendSuper()

#if TARGET_OS_IPHONE
	#import <UIKit/UIColor.h>
	typedef UIColor Color;
#else
	#import <AppKit/NSColor.h>
	typedef NSColor Color;
#endif



NSString *const kMDLVoxelAssetOptionCalculateShellLevels = @"MDLVoxelAssetOptionCalculateShellLevels";
NSString *const kMDLVoxelAssetOptionSkipNonZeroShellMesh = @"MDLVoxelAssetOptionSkipNonZeroShellMesh";
NSString *const kMDLVoxelAssetOptionMeshGenerationMode = @"MDLVoxelAssetOptionMeshGenerationMode";
NSString *const kMDLVoxelAssetOptionMeshGenerationFlattening = @"MDLVoxelAssetOptionMeshGenerationFlattening";
NSString *const kMDLVoxelAssetOptionVoxelMesh = @"MDLVoxelAssetOptionVoxelMesh";
NSString *const kMDLVoxelAssetOptionConvertZUpToYUp = @"MDLVoxelAssetOptionConvertZUpToYUp";
NSString *const kMDLVoxelAssetOptionGenerateAmbientOcclusion = @"MDLVoxelAssetOptionGenerateAmbientOcclusion";


typedef struct _OptionsValues {
	BOOL calculateShellLevels : 1;
	BOOL skipNonZeroShellMesh : 1;
	BOOL meshGenerationFlattening : 1;
	BOOL convertZUpToYUp : 1;
	BOOL generateAmbientOcclusion : 1;
	
	MDLVoxelAssetMeshGenerationMode meshGenerationMode;
	id voxelMesh;
} OptionsValues;


typedef struct _PerVertexMeshData {
	vector_float3 __attribute__((aligned(4))) position;
	vector_float3 __attribute__((aligned(4))) normal;
	vector_float2 __attribute__((aligned(4))) textureCoordinate;
	vector_float3 __attribute__((aligned(4))) color;
} __attribute__((aligned(4))) PerVertexMeshData;

static const PerVertexMeshData kVoxelCubeVertexData[] = {
	// X+ Facing
	{ .position = { 1, 0, 0 }, .normal = { +1,  0,  0 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 1, 1, 0 }, .normal = { +1,  0,  0 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 1, 0, 1 }, .normal = { +1,  0,  0 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 1, 1, 1 }, .normal = { +1,  0,  0 }, .textureCoordinate = { 1, 1 } },
	// X- Facing
	{ .position = { 0, 0, 0 }, .normal = { -1,  0,  0 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 0, 0, 1 }, .normal = { -1,  0,  0 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 0, 1, 0 }, .normal = { -1,  0,  0 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 0, 1, 1 }, .normal = { -1,  0,  0 }, .textureCoordinate = { 1, 1 } },
	// Y+ Facing
	{ .position = { 0, 1, 0 }, .normal = {  0, +1,  0 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 0, 1, 1 }, .normal = {  0, +1,  0 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 1, 1, 0 }, .normal = {  0, +1,  0 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 1, 1, 1 }, .normal = {  0, +1,  0 }, .textureCoordinate = { 1, 1 } },
	// Y- Facing
	{ .position = { 0, 0, 0 }, .normal = {  0, -1,  0 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 1, 0, 0 }, .normal = {  0, -1,  0 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 0, 0, 1 }, .normal = {  0, -1,  0 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 1, 0, 1 }, .normal = {  0, -1,  0 }, .textureCoordinate = { 1, 1 } },
	// Z+ Facing
	{ .position = { 0, 0, 1 }, .normal = {  0,  0, +1 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 1, 0, 1 }, .normal = {  0,  0, +1 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 0, 1, 1 }, .normal = {  0,  0, +1 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 1, 1, 1 }, .normal = {  0,  0, +1 }, .textureCoordinate = { 1, 1 } },
	// Z- Facing
	{ .position = { 0, 0, 0 }, .normal = {  0,  0, -1 }, .textureCoordinate = { 0, 0 } },
	{ .position = { 0, 1, 0 }, .normal = {  0,  0, -1 }, .textureCoordinate = { 1, 0 } },
	{ .position = { 1, 0, 0 }, .normal = {  0,  0, -1 }, .textureCoordinate = { 0, 1 } },
	{ .position = { 1, 1, 0 }, .normal = {  0,  0, -1 }, .textureCoordinate = { 1, 1 } },
};

static const uint16_t kVoxelCubeVertexIndexData[] = {
	// X+ Facing
	(0*4 + 0), (0*4 + 1), (0*4 + 2), (0*4 + 2), (0*4 + 1), (0*4 + 3),
	// X- Facing
	(1*4 + 0), (1*4 + 1), (1*4 + 2), (1*4 + 2), (1*4 + 1), (1*4 + 3),
	// Y+ Facing
	(2*4 + 0), (2*4 + 1), (2*4 + 2), (2*4 + 2), (2*4 + 1), (2*4 + 3),
	// Y- Facing
	(3*4 + 0), (3*4 + 1), (3*4 + 2), (3*4 + 2), (3*4 + 1), (3*4 + 3),
	// Z+ Facing
	(4*4 + 0), (4*4 + 1), (4*4 + 2), (4*4 + 2), (4*4 + 1), (4*4 + 3),
	// Z- Facing
	(5*4 + 0), (5*4 + 1), (5*4 + 2), (5*4 + 2), (5*4 + 1), (5*4 + 3),
};



@interface MDLVoxelAsset ()

@property(nonatomic, readwrite, retain) NSURL *URL;

@end


@implementation MDLVoxelAsset {
	OptionsValues _options;
	
	MagicaVoxelVoxData *_mvvoxData;
	
	MDLVoxelIndex *_voxelsRawData;
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
	NSArray<NSArray<NSArray<NSNumber*>*>*> *_voxelPaletteIndices;
	NSArray<Color*> *_paletteColors;
	
	NSMutableArray<MDLMesh*> *_meshes;
	PerVertexMeshData *_verticesRawData;
	uint16_t *_vertexIndicesRawData;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors;

- (uint32_t)voxelCount {
	return _mvvoxData.voxels_count;
}

- (MDLAxisAlignedBoundingBox)boundingBox {
	MagicaVoxelVoxData_XYZDimensions mvvoxDimensions = _mvvoxData.dimensions;
	
	if (_options.convertZUpToYUp)
		return (MDLAxisAlignedBoundingBox){
			.minBounds = { 0, 0, 0 },
			.maxBounds = { mvvoxDimensions.x, mvvoxDimensions.z, mvvoxDimensions.y },
		};
	else
		return (MDLAxisAlignedBoundingBox){
			.minBounds = { 0, 0, 0 },
			.maxBounds = { mvvoxDimensions.x, mvvoxDimensions.y, mvvoxDimensions.z },
		};
}


- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString*,id> *)options_dict
{
	self = [super init];
	if (self == nil)
		return nil;
	
	[self parseOptions:options_dict];
	
	self.URL = URL;
	
	_mvvoxData = [[MagicaVoxelVoxData alloc] initWithContentsOfURL:URL];
	MagicaVoxelVoxData_Voxel *mvvoxVoxels = _mvvoxData.voxels_array;
	uint32_t voxelCount = self.voxelCount;
	
	MagicaVoxelVoxData_XYZDimensions mvvoxDimensions = _mvvoxData.dimensions;
	MagicaVoxelVoxData_XYZDimensions dimensions = _options.convertZUpToYUp ?
		(MagicaVoxelVoxData_XYZDimensions){ mvvoxDimensions.x, mvvoxDimensions.z, mvvoxDimensions.y } :
		mvvoxDimensions;
	
	_voxelsRawData = calloc(voxelCount, sizeof(MDLVoxelIndex));
	for (int32_t vI = voxelCount - 1; vI >= 0; --vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		
		if (_options.convertZUpToYUp)
			_voxelsRawData[vI] = (MDLVoxelIndex){ voxVoxel->x, voxVoxel->z, (mvvoxDimensions.y - 1 + -voxVoxel->y), 0 };
		else
			_voxelsRawData[vI] = (MDLVoxelIndex){ voxVoxel->x, voxVoxel->y, voxVoxel->z, 0 };
	}
	_voxelsData = [[NSData alloc] initWithBytesNoCopy:_voxelsRawData length:(voxelCount * sizeof(MDLVoxelIndex)) freeWhenDone:NO];
	
	
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
	
	NSNumber *zeroPaletteIndex = @(0);
	NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:dimensions.x];
	for (uint32_t xI = 0; xI < dimensions.x; ++xI) {
		[(voxelPaletteIndices[xI] = [[NSMutableArray alloc] initWithCapacity:dimensions.y]) release];
		for (uint32_t yI = 0; yI < dimensions.y; ++yI) {
			[(voxelPaletteIndices[xI][yI] = [[NSMutableArray alloc] initWithCapacity:dimensions.z]) release];
			for (uint32_t zI = 0; zI < dimensions.z; ++zI)
				voxelPaletteIndices[xI][yI][zI] = zeroPaletteIndex;
		}
	}
	//NSMutableArray<NSValue*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:voxelCount];
	for (int32_t vI = 0; vI < voxelCount; ++vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		MDLVoxelIndex voxelIndex = _voxelsRawData[vI];
		voxelPaletteIndices[voxelIndex.x][voxelIndex.y][voxelIndex.z] = @(voxVoxel->colorIndex);
		//voxelPaletteIndices[vI] = @(voxVoxel->colorIndex);
	}
	_voxelPaletteIndices = voxelPaletteIndices;
	
	
	uint16_t paletteColorCount = _mvvoxData.paletteColors_count;
	MagicaVoxelVoxData_PaletteColor *mvvoxPaletteColors = _mvvoxData.paletteColors_array;
	
	NSMutableArray<Color*> *paletteColors = [[NSMutableArray alloc] initWithCapacity:(paletteColorCount + 1)];
	paletteColors[0] = [Color clearColor];
	for (uint16_t pI = 1; pI <= paletteColorCount; ++pI) {
		MagicaVoxelVoxData_PaletteColor *voxColor = &mvvoxPaletteColors[pI - 1];
		paletteColors[pI] = [Color
			colorWithRed: voxColor->r / 255.f
			green: voxColor->g / 255.f
			blue: voxColor->b / 255.f
			alpha: voxColor->a / 255.f
		];
	}
	_paletteColors = paletteColors;
	
	[self generateMesh];
	
	return self;
}

- (id)copyWithZone:(NSZone *)_ {
	return [self retain]; // MDLVoxelAsset is immutable, so just keep using the same instance.
}

- (void)parseOptions:(NSDictionary<NSString*,id> *)options_dict
{
	BOOL (^parseBool)(NSString *, BOOL) = ^BOOL(NSString *optionKey, BOOL defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && [dictValue isKindOfClass:NSNumber.class];
		return isNonNilAndOfCorrectType ?
			((NSNumber *)dictValue).boolValue :
			defaultValue;
	};
	NSUInteger (^parseNSUIntegerEnum)(NSString *, NSUInteger) = ^(NSString *optionKey, NSUInteger defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && [dictValue isKindOfClass:NSNumber.class];
		return isNonNilAndOfCorrectType ?
			((NSNumber *)dictValue).unsignedIntegerValue :
			defaultValue;
	};
	id (^parseSCNGeometryOrMDLMesh)(NSString *, id) = ^(NSString *optionKey, id defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && ([dictValue isKindOfClass:SCNGeometry.class] || [dictValue isKindOfClass:MDLMesh.class]);
		return isNonNilAndOfCorrectType ?
			dictValue :
			defaultValue;
	};
	
	_options.calculateShellLevels = parseBool(kMDLVoxelAssetOptionCalculateShellLevels, NO);
	
	if (_options.calculateShellLevels)
		_options.skipNonZeroShellMesh = parseBool(kMDLVoxelAssetOptionSkipNonZeroShellMesh, NO);
	else
		_options.skipNonZeroShellMesh = NO;
	
	_options.meshGenerationMode = parseNSUIntegerEnum(kMDLVoxelAssetOptionMeshGenerationMode, MDLVoxelAssetMeshGenerationModeSceneKit);
	
	if (_options.meshGenerationMode != MDLVoxelAssetMeshGenerationModeSkip) {
		_options.meshGenerationFlattening = parseBool(kMDLVoxelAssetOptionMeshGenerationFlattening, YES);
		
		_options.voxelMesh = [parseSCNGeometryOrMDLMesh(kMDLVoxelAssetOptionVoxelMesh, 
			[SCNBox boxWithWidth:1 height:1 length:1 chamferRadius:0.0]
		) retain];
	}
	else {
		_options.meshGenerationFlattening = NO;
		_options.voxelMesh = nil;
	}
	
	_options.convertZUpToYUp = parseBool(kMDLVoxelAssetOptionConvertZUpToYUp, NO);
	
	_options.generateAmbientOcclusion = parseBool(kMDLVoxelAssetOptionGenerateAmbientOcclusion, NO);
}

- (void)generateMesh
{
	if (_meshes == nil)
		_meshes = [NSMutableArray new];
	else
		[_meshes removeAllObjects];
	
	free(_verticesRawData);
	_verticesRawData = NULL;
	free(_vertexIndicesRawData);
	_vertexIndicesRawData = NULL;
	
	
	if (_options.calculateShellLevels)
		[self calculateShellLevels];
	
	uint32_t voxelCount = self.voxelCount;
	
	static uint32_t const kFacesPerVoxel = 6;
	
	static uint32_t const kVerticesPerVoxel = 4 * kFacesPerVoxel;
	uint32_t vertexCount = self.voxelCount * kVerticesPerVoxel;
	NSAssert(sizeof(kVoxelCubeVertexData) / sizeof(PerVertexMeshData) == kVerticesPerVoxel,
		@"`sizeof(kVoxelCubeVertexData) / sizeof(PerVertexMeshData)` must equal %lu.", (unsigned long)kVerticesPerVoxel
	);
	_verticesRawData = calloc(vertexCount, sizeof(PerVertexMeshData));
	#if DEBUG
		memset(_verticesRawData, '\xFF', vertexCount * sizeof(PerVertexMeshData));
	#endif
	
	static uint32_t const kVertexIndicesPerVoxel = 6 * kFacesPerVoxel;
	uint32_t vertexIndexCount = self.voxelCount * kVertexIndicesPerVoxel;
	NSAssert(sizeof(kVoxelCubeVertexIndexData) / sizeof(uint16_t) == kVertexIndicesPerVoxel,
		@"`sizeof(kVoxelCubeVertexIndexData) / sizeof(uint16_t)` must equal %lu.", (unsigned long)kVertexIndicesPerVoxel
	);
	_vertexIndicesRawData = calloc(vertexIndexCount, sizeof(uint16_t));
	#if DEBUG
		memset(_vertexIndicesRawData, '\xFF', vertexIndexCount * sizeof(uint16_t));
	#endif
	
	MagicaVoxelVoxData_Voxel *mvvoxVoxels = _mvvoxData.voxels_array;
	
	{
		uint32_t voxI = 0;
		while (voxI < voxelCount)
		{
			MDLVoxelIndex voxelIndex = _voxelsRawData[voxI];
			
			if (_options.skipNonZeroShellMesh) {
				if (voxelIndex.w != 0) {
					voxelCount -= 1;
					vertexCount -= kVerticesPerVoxel;
					vertexIndexCount -= kVertexIndicesPerVoxel;
					continue;
				}
			}
			
			uint32_t baseVertI = voxI * kVerticesPerVoxel;
			memcpy(&_verticesRawData[baseVertI], kVoxelCubeVertexData, sizeof(kVoxelCubeVertexData));
			for (uint32_t vertI = 0; vertI < kVerticesPerVoxel; ++vertI)
				_verticesRawData[baseVertI + vertI].position += (vector_float3){ voxelIndex.x, voxelIndex.y, voxelIndex.z };
			
			uint8_t colorIndex = mvvoxVoxels[voxI].colorIndex;
			Color *color = _paletteColors[colorIndex];
			CGFloat color_cgArray[4];
			[color getRed:&color_cgArray[0] green:&color_cgArray[1] blue:&color_cgArray[2] alpha:&color_cgArray[3]];
			for (uint32_t vertI = 0; vertI < kVerticesPerVoxel; ++vertI)
				_verticesRawData[baseVertI + vertI].color = (vector_float3){ color_cgArray[0], color_cgArray[1], color_cgArray[2] };
			
			++voxI;
		}
	}
	
	static const uint32_t kPerMeshVertexCountLimit = 65536;
	const uint32_t perMeshVoxelCountLimit = kPerMeshVertexCountLimit / kVerticesPerVoxel;
	
	uint32_t voxI = 0;
	while (voxI < voxelCount)
	{
		uint32_t startVoxI = voxI;
		uint32_t voxILimit = MIN(voxI + perMeshVoxelCountLimit, voxelCount);
		
		while (voxI < voxILimit)
		{
			MDLVoxelIndex voxelIndex = _voxelsRawData[voxI];
			
			if (_options.skipNonZeroShellMesh) {
				if (voxelIndex.w != 0) {
					voxelCount -= 1;
					vertexCount -= kVerticesPerVoxel;
					vertexIndexCount -= kVertexIndicesPerVoxel;
					continue;
				}
			}
			
			uint32_t baseVertI = (voxI - startVoxI) * kVerticesPerVoxel;
			
			uint32_t baseVertIndexI = voxI * kVertexIndicesPerVoxel;
			memcpy(&_vertexIndicesRawData[baseVertIndexI], kVoxelCubeVertexIndexData, sizeof(kVoxelCubeVertexIndexData));
			for (uint32_t vertIndexI = 0; vertIndexI < kVertexIndicesPerVoxel; ++vertIndexI)
				_vertexIndicesRawData[baseVertIndexI + vertIndexI] += baseVertI;
			
			++voxI;
		}
		
		// @note: We hang onto `_verticesRawData` & `_vertexIndicesRawData` and free them ourselves since they're might be oversized (`_options.skipNonZeroShellMesh`) and the `NSData`s only address the length we used (so no more data is sent to the GPU than necessary).
		NSData *verticesData = [[NSData alloc] initWithBytesNoCopy: &_verticesRawData[startVoxI * kVerticesPerVoxel]
			length: (voxILimit - startVoxI) * kVerticesPerVoxel * sizeof(PerVertexMeshData)
			freeWhenDone: NO
		];
		NSData *vertexIndicesData = [[NSData alloc] initWithBytesNoCopy: &_vertexIndicesRawData[startVoxI * kVertexIndicesPerVoxel]
			length: (voxILimit - startVoxI) * kVertexIndicesPerVoxel * sizeof(uint16_t)
			freeWhenDone: NO
		];
		
		MDLVertexDescriptor *meshDescriptor = [[MDLVertexDescriptor new] autorelease];
		[meshDescriptor addOrReplaceAttribute:[[[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:offsetof(PerVertexMeshData, position) bufferIndex:0] autorelease]];
		[meshDescriptor addOrReplaceAttribute:[[[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal format:MDLVertexFormatFloat3 offset:offsetof(PerVertexMeshData, normal)  bufferIndex:0] autorelease]];
		[meshDescriptor addOrReplaceAttribute:[[[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTextureCoordinate format:MDLVertexFormatFloat2 offset:offsetof(PerVertexMeshData, textureCoordinate) bufferIndex:0] autorelease]];
		[meshDescriptor addOrReplaceAttribute:[[[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeColor format:MDLVertexFormatFloat3 offset:offsetof(PerVertexMeshData, color) bufferIndex:0] autorelease]];
		meshDescriptor.layouts[0].stride = sizeof(PerVertexMeshData);
		meshDescriptor.layouts[1].stride = sizeof(PerVertexMeshData);
		meshDescriptor.layouts[2].stride = sizeof(PerVertexMeshData);
		meshDescriptor.layouts[3].stride = sizeof(PerVertexMeshData);
		
		MDLMeshBufferData *vertexBufferData = [[MDLMeshBufferData alloc] initWithType:MDLMeshBufferTypeVertex data:verticesData];
		MDLMeshBufferData *indexBufferData = [[MDLMeshBufferData alloc] initWithType:MDLMeshBufferTypeIndex data:vertexIndicesData];
		[verticesData release];
		[vertexIndicesData release];
		
		MDLSubmesh *submesh = [[MDLSubmesh alloc] initWithIndexBuffer:indexBufferData indexCount:((voxILimit - startVoxI) * kVertexIndicesPerVoxel) indexType:MDLIndexBitDepthUInt16 geometryType:MDLGeometryTypeTriangles material:nil];
		
		MDLMesh *mesh = [[MDLMesh alloc] initWithVertexBuffer:vertexBufferData vertexCount:((voxILimit - startVoxI) * kVerticesPerVoxel) descriptor:meshDescriptor submeshes:@[ submesh ]];
		[submesh release];
		[vertexBufferData release];
		[indexBufferData release];
		
		if (_options.generateAmbientOcclusion) {
			BOOL aoSuccess = [mesh generateAmbientOcclusionVertexColorsWithQuality:0.1 attenuationFactor:0.1 objectsToConsider:super.objects vertexAttributeNamed:MDLVertexAttributeOcclusionValue];
		}
		
		[_meshes addObject:mesh];
		[super addObject:mesh];
		[mesh release];
	}
}

- (void)dealloc
{
	[_meshes release];
	_meshes = nil;
	free(_verticesRawData);
	_verticesRawData = NULL;
	free(_vertexIndicesRawData);
	_vertexIndicesRawData = NULL;
	
	free(_voxelsRawData);
	_voxelsRawData = NULL;
	[_voxelsData release];
	_voxelsData = nil;
	
	[_paletteColors release];
	_paletteColors = nil;
	[_voxelPaletteIndices release];
	_voxelPaletteIndices = nil;
	[_voxelArray release];
	_voxelArray = nil;
	
	[_mvvoxData release];
	_mvvoxData = nil;
	
	[_options.voxelMesh release];
	_options.voxelMesh = nil;
	
	[super dealloc];
}


+ (BOOL)canImportFileExtension:(NSString *)extension
{
	if ([extension isEqualToString:@"vox"])
		return YES;
	
	return NO;
}


- (void)calculateShellLevels
{
	MDLVoxelIndex *voxelIndices = (MDLVoxelIndex *)_voxelsData.bytes;
	uint32_t voxelCount = self.voxelCount;
	
	BOOL didAddShell;
	int currentShellLevel = 0;
	do {
		didAddShell = NO;
		
		for (int32_t vI = voxelCount - 1; vI >= 0; --vI) {
			MDLVoxelIndex voxel = voxelIndices[vI];
			
			// @fixme: Dangerously expensive!
			NSData *neighborVoxelsData = [_voxelArray voxelsWithinExtent:(MDLVoxelIndexExtent){
				.minimumExtent = voxel + (vector_int4){ -1, -1, -1, 0 },
				.maximumExtent = voxel + (vector_int4){ +1, +1, +1, 0 },
			}];
			
			uint32_t neighborVoxelCount = (uint32_t)neighborVoxelsData.length / sizeof(MDLVoxelIndex);
			MDLVoxelIndex const *neighborIndices = (MDLVoxelIndex const *)neighborVoxelsData.bytes;
			
			BOOL coveredXPos = NO, coveredXNeg = NO, coveredYPos = NO, coveredYNeg = NO, coveredZPos = NO, coveredZNeg = NO;
			for (int32_t svI = neighborVoxelCount - 1; svI >= 0; --svI)
			{
				MDLVoxelIndex neighbor = neighborIndices[svI];
				if (neighbor.w != currentShellLevel)
					continue;
				
				if (neighbor.y == voxel.y && neighbor.z == voxel.z) {
					if (neighbor.x == voxel.x + 1)
						coveredXPos = YES;
					else if (neighbor.x == voxel.x - 1)
						coveredXNeg = YES;
				}
				else if (neighbor.x == voxel.x && neighbor.z == voxel.z) {
					if (neighbor.y == voxel.y + 1)
						coveredYPos = YES;
					else if (neighbor.y == voxel.y - 1)
						coveredYNeg = YES;
				}
				else if (neighbor.x == voxel.x && neighbor.y == voxel.y) {
					if (neighbor.z == voxel.z + 1)
						coveredZPos = YES;
					else if (neighbor.z == voxel.z - 1)
						coveredZNeg = YES;
				}
			}
			
			BOOL coveredOnAllSides = coveredXPos && coveredXNeg && coveredYPos && coveredYNeg && coveredZPos && coveredZNeg;
			if (coveredOnAllSides) {
				voxel += (vector_int4){ 0, 0, 0, -1 };
				voxelIndices[vI] = voxel;
				
				didAddShell = YES;
			}
		}
		
		++currentShellLevel;
	} while (didAddShell);
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
}


#pragma mark Sub-MDLObject Access

- (MDLObject *)objectAtIndex:(NSUInteger)index {
	return self.objects[index];
}
- (MDLObject *)objectAtIndexedSubscript:(NSUInteger)index {
	return self.objects[index];
}

- (NSUInteger)count {
	return self.objects.count;
}


#pragma mark MDLObjectContainerComponent Overrides


- (void)addObject:(MDLObject *)object {
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
		reason: [NSString stringWithFormat:@"%@ does not allow mutation; calling this %@ method is not allowed.", MDLVoxelAsset.class, NSStringFromSelector(_cmd)]
		userInfo: @{
			@"receiver": self,
			@"selector": [NSValue value:&_cmd withObjCType:@encode(SEL)],
		}
	];
}

- (void)removeObject:(MDLObject *)object {
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
		reason: [NSString stringWithFormat:@"%@ does not allow mutation; calling this %@ method is not allowed.", MDLVoxelAsset.class, NSStringFromSelector(_cmd)]
		userInfo: @{
			@"receiver": self,
			@"selector": [NSValue value:&_cmd withObjCType:@encode(SEL)],
		}
	];
}


@end
