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
NSString *const kMDLVoxelAssetOptionPaletteIndexReplacements = @"MDLVoxelAssetOptionPaletteReplacements";
NSString *const kMDLVoxelAssetOptionSkipMeshFaceDirections = @"MDLVoxelAssetOptionSkipMeshFaceDirections";


typedef NSDictionary<NSNumber*,NSNumber*> PaletteIndexToPaletteIndexDictionary;

typedef struct _OptionsValues {
	BOOL calculateShellLevels : 1;
	BOOL skipNonZeroShellMesh : 1;
	BOOL meshGenerationFlattening : 1;
	BOOL convertZUpToYUp : 1;
	BOOL generateAmbientOcclusion : 1;
	
	MDLVoxelAssetMeshGenerationMode meshGenerationMode;
	id voxelMesh;
	PaletteIndexToPaletteIndexDictionary *paletteIndexReplacements;
	MDLVoxelAssetSkipMeshFaceDirections skipMeshFaceDirections;
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
	MDLVoxelAsset_VoxelDimensions _voxelDimensions;
	
	NSMutableArray<MDLMesh*> *_meshes;
	PerVertexMeshData *_verticesRawData;
	uint16_t *_vertexIndicesRawData;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors, meshes=_meshes;

- (uint32_t)voxelCount {
	return _mvvoxData.voxels_count;
}

- (MDLVoxelAsset_VoxelDimensions)voxelDimensions {
	return _voxelDimensions;
}

- (MDLAxisAlignedBoundingBox)boundingBox {
	return (MDLAxisAlignedBoundingBox){
		.minBounds = { 0, 0, 0 },
		.maxBounds = { _voxelDimensions.x, _voxelDimensions.z, _voxelDimensions.y },
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
	_voxelDimensions = _options.convertZUpToYUp ?
		(MDLVoxelAsset_VoxelDimensions){ mvvoxDimensions.x, mvvoxDimensions.z, mvvoxDimensions.y } :
		(MDLVoxelAsset_VoxelDimensions){ mvvoxDimensions.x, mvvoxDimensions.y, mvvoxDimensions.z };
	
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
	NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:_voxelDimensions.x];
	for (uint32_t xI = 0; xI < _voxelDimensions.x; ++xI) {
		[(voxelPaletteIndices[xI] = [[NSMutableArray alloc] initWithCapacity:_voxelDimensions.y]) release];
		for (uint32_t yI = 0; yI < _voxelDimensions.y; ++yI) {
			[(voxelPaletteIndices[xI][yI] = [[NSMutableArray alloc] initWithCapacity:_voxelDimensions.z]) release];
			for (uint32_t zI = 0; zI < _voxelDimensions.z; ++zI)
				voxelPaletteIndices[xI][yI][zI] = zeroPaletteIndex;
		}
	}
	//NSMutableArray<NSValue*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:voxelCount];
	for (int32_t vI = 0; vI < voxelCount; ++vI) {
		MagicaVoxelVoxData_Voxel *voxVoxel = &mvvoxVoxels[vI];
		MDLVoxelIndex voxelIndex = _voxelsRawData[vI];
		
		uint8_t colorIndex = voxVoxel->colorIndex;
		if (_options.paletteIndexReplacements != nil) {
			NSNumber *replacementValue = _options.paletteIndexReplacements[@(colorIndex)];
			if (replacementValue != nil)
				colorIndex = replacementValue.unsignedCharValue;
		}
		voxelPaletteIndices[voxelIndex.x][voxelIndex.y][voxelIndex.z] = @(colorIndex);
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
	PaletteIndexToPaletteIndexDictionary * (^parsePaletteIndexToPaletteIndexDictionary)(NSString *, PaletteIndexToPaletteIndexDictionary *) = ^(NSString *optionKey, PaletteIndexToPaletteIndexDictionary *defaultValue){
		id dictValue = [options_dict objectForKey:optionKey];
		BOOL isNonNilAndOfCorrectType = dictValue != nil && [dictValue isKindOfClass:[PaletteIndexToPaletteIndexDictionary class]];
		return isNonNilAndOfCorrectType ? dictValue : defaultValue;
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
	
	_options.paletteIndexReplacements = [parsePaletteIndexToPaletteIndexDictionary(kMDLVoxelAssetOptionPaletteIndexReplacements, nil) retain];
	
	_options.skipMeshFaceDirections = parseNSUIntegerEnum(kMDLVoxelAssetOptionSkipMeshFaceDirections, MDLVoxelAssetSkipMeshFaceDirectionsNone);
}


typedef void(^GenerateMesh_AddMeshDataCallback)(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType geometryType);

- (void)generateMesh
{
	if (_meshes == nil) {
		_meshes = [NSMutableArray new];
	} else {
		[_meshes removeAllObjects];
		for (MDLObject *object in super.objects) {
			[super removeObject:object];
		}
	}
	
	free(_verticesRawData);
	_verticesRawData = NULL;
	free(_vertexIndicesRawData);
	_vertexIndicesRawData = NULL;
	
	GenerateMesh_AddMeshDataCallback addMeshDataCallback = ^(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType geometryType) {
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
		
		MDLSubmesh *submesh = [[MDLSubmesh alloc] initWithIndexBuffer:indexBufferData indexCount:vertexIndicesCount indexType:MDLIndexBitDepthUInt16 geometryType:geometryType material:nil];
		
		MDLMesh *mesh = [[MDLMesh alloc] initWithVertexBuffer:vertexBufferData vertexCount:verticesCount descriptor:meshDescriptor submeshes:@[ submesh ]];
		[submesh release];
		[vertexBufferData release];
		[indexBufferData release];
		
		if (_options.generateAmbientOcclusion) {
			BOOL aoSuccess = [mesh generateAmbientOcclusionVertexColorsWithQuality:0.1 attenuationFactor:0.1 objectsToConsider:super.objects vertexAttributeNamed:MDLVertexAttributeOcclusionValue];
		}
		
		[_meshes addObject:mesh];
		[super addObject:mesh];
		[mesh release];
	};
	
	switch (_options.meshGenerationMode) {
		case MDLVoxelAssetMeshGenerationModeSkip:
			return;
		case MDLVoxelAssetMeshGenerationModeSceneKit:
			[self generateSceneKitMesh:addMeshDataCallback];
			break;
		case MDLVoxelAssetMeshGenerationModeGreedyTri:
			[self generateGreedyTriMesh:addMeshDataCallback];
			break;
		case MDLVoxelAssetMeshGenerationModeGreedyQuad:
			[self generateGreedyQuadMesh:addMeshDataCallback];
			break;
	}
}

- (void)generateSceneKitMesh:(GenerateMesh_AddMeshDataCallback)addMeshDataCallback
{
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
			if (_options.paletteIndexReplacements != nil) {
				NSNumber *replacementValue = _options.paletteIndexReplacements[@(colorIndex)];
				if (replacementValue != nil)
					colorIndex = replacementValue.unsignedCharValue;
			}
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
		
		addMeshDataCallback(
			verticesData, ((voxILimit - startVoxI) * kVerticesPerVoxel),
			vertexIndicesData, ((voxILimit - startVoxI) * kVertexIndicesPerVoxel),
			MDLGeometryTypeTriangles
		);
		
		[verticesData release];
		[vertexIndicesData release];
	}
}

- (void)generateGreedyQuadMesh:(GenerateMesh_AddMeshDataCallback)addMeshDataCallback
{
	[self generateGreedyMesh:^(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType _) {
			addMeshDataCallback(verticesData, verticesCount, vertexIndicesData, vertexIndicesCount, MDLGeometryTypeQuads);
		}
		verticesPerFace: 4
		vertexIndicesPerFace: 4
		addVerticesRawDataCallback: ^(uint32_t baseVertI, vector_short3 basePosition, vector_short3 positionUDelta, vector_short3 positionVDelta, vector_float3 normalData, vector_float3 colorData, vector_float2 textureCoordinateData) {
			_verticesRawData[baseVertI + 0] = (PerVertexMeshData){
				{ // position
					basePosition[0],
					basePosition[1],
					basePosition[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 1] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionUDelta[0],
					basePosition[1] + positionUDelta[1],
					basePosition[2] + positionUDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 2] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionUDelta[0] + positionVDelta[0],
					basePosition[1] + positionUDelta[1] + positionVDelta[1],
					basePosition[2] + positionUDelta[2] + positionVDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 3] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionVDelta[0],
					basePosition[1] + positionVDelta[1],
					basePosition[2] + positionVDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
		}
		addVertexIndicesRawDataCallback: ^(uint32_t baseVertIndexI, uint32_t baseVertI, BOOL isBackFace) {
			if (!isBackFace) {
				_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 0;
				_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 1;
				_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 2;
				_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 3;
			} else {
				_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 3;
				_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 2;
				_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 1;
				_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 0;
			}
		}
	];
}

- (void)generateGreedyTriMesh:(GenerateMesh_AddMeshDataCallback)addMeshDataCallback
{
	[self generateGreedyMesh:^(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType _) {
			addMeshDataCallback(verticesData, verticesCount, vertexIndicesData, vertexIndicesCount, MDLGeometryTypeQuads);
		}
		verticesPerFace: 4
		vertexIndicesPerFace: 6
		addVerticesRawDataCallback: ^(uint32_t baseVertI, vector_short3 basePosition, vector_short3 positionUDelta, vector_short3 positionVDelta, vector_float3 normalData, vector_float3 colorData, vector_float2 textureCoordinateData) {
			_verticesRawData[baseVertI + 0] = (PerVertexMeshData){
				{ // position
					basePosition[0],
					basePosition[1],
					basePosition[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 1] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionUDelta[0],
					basePosition[1] + positionUDelta[1],
					basePosition[2] + positionUDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 2] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionUDelta[0] + positionVDelta[0],
					basePosition[1] + positionUDelta[1] + positionVDelta[1],
					basePosition[2] + positionUDelta[2] + positionVDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
			_verticesRawData[baseVertI + 3] = (PerVertexMeshData){
				{ // position
					basePosition[0] + positionVDelta[0],
					basePosition[1] + positionVDelta[1],
					basePosition[2] + positionVDelta[2]
				},
				normalData, textureCoordinateData, colorData,
			};
		}
		addVertexIndicesRawDataCallback: ^(uint32_t baseVertIndexI, uint32_t baseVertI, BOOL isBackFace) {
			if (!isBackFace) {
				_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 0;
				_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 1;
				_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 2;
				
				_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 0;
				_vertexIndicesRawData[baseVertIndexI + 4] = baseVertI + 2;
				_vertexIndicesRawData[baseVertIndexI + 5] = baseVertI + 3;
			} else {
				_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 2;
				_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 1;
				_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 0;
				
				_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 3;
				_vertexIndicesRawData[baseVertIndexI + 4] = baseVertI + 2;
				_vertexIndicesRawData[baseVertIndexI + 5] = baseVertI + 0;
			}
		}
	];
}

typedef void(^GenerateGreedyMesh_AddVerticesRawDataCallback)(uint32_t baseVertI, vector_short3 basePosition, vector_short3 positionUDelta, vector_short3 positionVDelta, vector_float3 normalData, vector_float3 colorData, vector_float2 textureCoordinateData);
typedef void(^GenerateGreedyMesh_AddVertexIndicesRawDataCallback)(uint32_t baseVertIndexI, uint32_t baseVertI, BOOL isBackFace);

- (void)generateGreedyMesh:(GenerateMesh_AddMeshDataCallback)addMeshDataCallback
	verticesPerFace:(uint32_t)verticesPerFace vertexIndicesPerFace:(uint32_t)vertexIndicesPerFace
	addVerticesRawDataCallback:(GenerateGreedyMesh_AddVerticesRawDataCallback)addVerticesRawDataCallback addVertexIndicesRawDataCallback:(GenerateGreedyMesh_AddVertexIndicesRawDataCallback)addVertexIndicesRawDataCallback
{
	static const short kMagicaVoxelMaxDimension = 126;
	
	vector_short3 dimensions = { _voxelDimensions.x, _voxelDimensions.y, _voxelDimensions.z };
	NSParameterAssert(dimensions.x <= kMagicaVoxelMaxDimension && dimensions.y <= kMagicaVoxelMaxDimension && dimensions.z <= kMagicaVoxelMaxDimension);
	
	const uint32_t faceCountGuess = ( MAX(MAX(dimensions.x, dimensions.y), dimensions.z) + MIN(MIN(dimensions.x, dimensions.y), dimensions.z) ) * 2;
	uint32_t faceCount = 0;
	uint32_t faceCapacity = faceCountGuess;
	
	{
		uint32_t vertexCapacity = faceCapacity * verticesPerFace;
		_verticesRawData = malloc(vertexCapacity * sizeof(PerVertexMeshData));
		#if DEBUG
			memset(_verticesRawData, '\xFF', vertexCapacity * sizeof(PerVertexMeshData));
		#endif
		
		uint32_t vertexIndexCapacity = faceCapacity * vertexIndicesPerFace;
		_vertexIndicesRawData = malloc(vertexIndexCapacity * sizeof(uint16_t));
		#if DEBUG
			memset(_vertexIndicesRawData, '\xFF', vertexIndexCapacity * sizeof(uint16_t));
		#endif
	}
	
	uint8_t *voxelPaletteIndices3DRawData = calloc(dimensions.x * dimensions.y * dimensions.z, sizeof(uint8_t));
	
	for (short xI = dimensions.x - 1; xI >= 0; --xI) {
		for (short yI = dimensions.y - 1; yI >= 0; --yI) {
			for (short zI = dimensions.z - 1; zI >= 0; --zI) {
				voxelPaletteIndices3DRawData[
					(xI * dimensions.y * dimensions.z) +
					(yI * dimensions.z) +
					zI
				] = _voxelPaletteIndices[xI][yI][zI].unsignedCharValue;
			}
		}
	}
	
	// Will contain the groups of matching voxel faces as we proceed through the chunk in 6 directions - once for each face.
	uint8_t paletteIndexMask[kMagicaVoxelMaxDimension * kMagicaVoxelMaxDimension] = { 0 };

	// The variable `isBackFace` will be TRUE on the first iteration and FALSE on the second - this allows us to track which direction the indices should run during creation of the quad.
	// This loop runs twice, and the inner loop 3 times - totally 6 iterations - one for each voxel face.
	for (signed char backFaceI = 1; backFaceI >= 0; --backFaceI)
	{
		BOOL isBackFace = (BOOL)backFaceI;
		
		// Sweep over the 3 dimensions - most of what follows is well described by Mikola Lysenko in his post - and is ported from his Javascript implementation.
		// Where this implementation diverges, I've added commentary.
		for (int axisI = 0; axisI < 3; axisI++)
		{
			NSUInteger meshFaceDirection = 1 << (axisI * 2 + (isBackFace ? 0 : 1));
			if ((_options.skipMeshFaceDirections & meshFaceDirection) != 0)
				continue;
			
			vector_short3 x = { 0,0,0 };
			
			vector_short3 q = { 0,0,0 }; q[axisI] = 1;
			
			int u = (axisI + 1) % 3;
			int v = (axisI + 2) % 3;
			
			// Move through the dimension from front to back
			for (x[axisI] = -1; x[axisI] < dimensions[axisI];)
			{
				// Compute the `paletteIndexMask`
				int n = 0;
				
				for (x[v] = 0; x[v] < dimensions[v]; x[v] += 1) {
					for (x[u] = 0; x[u] < dimensions[u]; x[u] += 1) {
						// Retrieve two voxel faces for comparison.
						uint8_t voxelAPaletteIndex = 0;
						if (x[axisI] >= 0) {
							vector_short3 i = x;
							voxelAPaletteIndex = voxelPaletteIndices3DRawData[
								(i.x * dimensions.y * dimensions.z) +
								(i.y * dimensions.z) +
								i.z
							];
						}
						uint8_t voxelBPaletteIndex = 0;
						if (x[axisI] < dimensions[axisI] - 1) {
							vector_short3 i = x + q;
							voxelBPaletteIndex = voxelPaletteIndices3DRawData[
								(i.x * dimensions.y * dimensions.z) +
								(i.y * dimensions.z) +
								i.z
							];
						}
						
						// Note that we're using the equals function in the voxel face class here, which lets the faces be compared based on any number of attributes.
						// Also, we choose the face to add to the `paletteIndexMask` depending on whether we're moving through on a backface or not.
						if (voxelAPaletteIndex != 0 && voxelBPaletteIndex != 0 && voxelAPaletteIndex == voxelBPaletteIndex)
							paletteIndexMask[n] = 0;
						else if (isBackFace)
							paletteIndexMask[n] = voxelBPaletteIndex;
						else // !isBackFace
							paletteIndexMask[n] = voxelAPaletteIndex;
						
						n += 1;
					}
				}
				
				x[axisI] += 1;
				
				// Generate the mesh for the `paletteIndexMask`
				n = 0;
				
				for (int vI = 0; vI < dimensions[v]; ++vI)
				{
					for (int uI = 0; uI < dimensions[u];)
					{
						uint8_t paletteIndex = paletteIndexMask[n];
						
						if (paletteIndex == 0) {
							uI += 1;
							n += 1;
							continue;
						}
						
						// Compute the quad width
						int width = 1;
						while (uI + width < dimensions[u]) {
							uint8_t checkPaletteIndex = paletteIndexMask[n + width];
							if (checkPaletteIndex != paletteIndex)
								break;
							
							width += 1;
						}
						
						// Compute quad height
						int height = 1;
						while (vI + height < dimensions[v]) {
							for (int uCheckI = 0; uCheckI < width; ++uCheckI) {
								uint8_t checkPaletteIndex = paletteIndexMask[n + (height * dimensions[u]) + uCheckI];
								if (checkPaletteIndex != paletteIndex)
									goto breakComputeHeight;
							}
							
							height += 1;
						}
						breakComputeHeight: ;
						
						// Add quad
						
						if (faceCount == faceCapacity) {
							uint32_t oldVertexCapacity = faceCapacity * verticesPerFace;
							uint32_t oldVertexIndexCapacity = faceCapacity * vertexIndicesPerFace;
							
							faceCapacity += faceCountGuess;
							uint32_t newVertexCapacity = faceCapacity * verticesPerFace;
							uint32_t newVertexIndexCapacity = faceCapacity * vertexIndicesPerFace;
							
							_verticesRawData = realloc(_verticesRawData, newVertexCapacity * sizeof(PerVertexMeshData));
							#if DEBUG
								memset(&_verticesRawData[oldVertexCapacity], '\xFF', (newVertexCapacity - oldVertexCapacity) * sizeof(PerVertexMeshData));
							#endif
							
							uint32_t vertexIndexCount = faceCapacity * vertexIndicesPerFace;
							_vertexIndicesRawData = realloc(_vertexIndicesRawData, vertexIndexCount * sizeof(uint16_t));
							#if DEBUG
								memset(&_vertexIndicesRawData[oldVertexIndexCapacity], '\xFF', (newVertexIndexCapacity - oldVertexIndexCapacity) * sizeof(uint16_t));
							#endif
						}
						
						uint32_t faceI = faceCount;
						++faceCount; // NOTE: It's crucial that this only bumps up one at a time; if it were incremented more, the above `(faceCount == faceCapacity)` & `memset()` logic would need to be revised.
						
						x[u] = uI;
						x[v] = vI;
						
						vector_short3 uDelta = { 0, 0, 0 }; uDelta[u] = width;
						vector_short3 vDelta = { 0, 0, 0 }; vDelta[v] = height;
						
						// Call the quad function in order to render a merged quad in the scene.
						// Passing `paletteIndex` to the function, which is an instance of the VoxelFace class containing all the attributes of the face - which allows for variables to be passed to shaders - for example lighting values used to create ambient occlusion.
						{
							uint32_t baseVertI = faceI * verticesPerFace;
							uint32_t baseVertIndexI = faceI * vertexIndicesPerFace;
							
							vector_float3 normalData = { 0.0 }; normalData[axisI] = isBackFace ? -1.0 : +1.0;
							
							Color *color = _paletteColors[paletteIndex];
							CGFloat color_cgArray[4];
							[color getRed:&color_cgArray[0] green:&color_cgArray[1] blue:&color_cgArray[2] alpha:&color_cgArray[3]];
							vector_float3 colorData = { color_cgArray[0], color_cgArray[1], color_cgArray[2] };
							static const vector_short2 mvvoxPaletteTextureSize = { 256, 1 };
							vector_float2 textureCoordinateData = { /* x: */ (paletteIndex - 1 + 0.5f) / mvvoxPaletteTextureSize.x, /* y: */ 0.5f }; // NOTE: no special-case for index #0 (transparent)
							
							addVerticesRawDataCallback(baseVertI, x, uDelta, vDelta, normalData, colorData, textureCoordinateData);
							
							addVertexIndicesRawDataCallback(baseVertIndexI, baseVertI, isBackFace);
						}
						
						// Zero out the `paletteIndexMask`
						for (int vZeroingI = height - 1; vZeroingI >= 0; --vZeroingI)
							memset(&paletteIndexMask[n + (vZeroingI * dimensions[u])], 0, width);
						
						// Increment the counters and continue
						uI += width;
						n += width;
					} // `uI`
				} // `vI`
			} // `x[axisI]`
		} // `axisI`
	} // `backFaceI`
	
	free(voxelPaletteIndices3DRawData);
	
	// @note: We hang onto `_verticesRawData` & `_vertexIndicesRawData` and free them ourselves since they're probably be oversized (`faceCapacity > faceCount`) and the `NSData`s only address the length we used (so no more data is sent to the GPU than necessary).
	uint32_t vertexCount = faceCount * verticesPerFace;
	NSData *verticesData = [[NSData alloc] initWithBytesNoCopy: _verticesRawData
		length: vertexCount * sizeof(PerVertexMeshData)
		freeWhenDone: NO
	];
	uint32_t vertexIndexCount = faceCount * vertexIndicesPerFace;
	NSData *vertexIndicesData = [[NSData alloc] initWithBytesNoCopy: _vertexIndicesRawData
		length: vertexIndexCount * sizeof(uint16_t)
		freeWhenDone: NO
	];
	
	addMeshDataCallback(verticesData, vertexCount, vertexIndicesData, vertexIndexCount, 0);
	
	[verticesData release];
	[vertexIndicesData release];
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
	
	[_options.paletteIndexReplacements release];
	_options.paletteIndexReplacements = nil;
	
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
