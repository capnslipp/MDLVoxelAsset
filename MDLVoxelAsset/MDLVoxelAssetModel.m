// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <MDLVoxelAsset/MDLVoxelAssetModel.h>

#import <MDLVoxelAsset/MagicaVoxelVoxData.h>

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



typedef MDLVoxelIndex* MDLVoxelIndexPtr;

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

static const uint8_t kZeroPaletteIndex = 0;



uint32_t arrayIndexFrom3DCoords(uint8_t x, uint8_t y, uint8_t z, const vector_short3 dimensions) {
	return ((x) * dimensions.y + y) * dimensions.z + z;
}



@interface MDLVoxelAssetModel ()

@property (nonatomic, retain, readonly) NSArray<Color*> *paletteColors;

@end


@implementation MDLVoxelAssetModel {
	OptionsValues _options;
	
	MagicaVoxelVoxData *_mvvoxData;
	
	MagicaVoxelVoxData_Voxel *_mvvoxVoxelsArray;
	MDLVoxelIndex *_voxelsRawData;
	NSData *_voxelsData;
	
	MDLVoxelArray *_voxelArray;
	uint8_t *_voxelPaletteIndices3DRawData;
	NSArray<Color*> *_paletteColors;
	uint32_t _voxelCount;
	MDLVoxelAsset_VoxelDimensions _voxelDimensions;
	
	NSMutableArray<MDLMesh*> *_meshes;
	PerVertexMeshData *_verticesRawData;
	uint16_t *_vertexIndicesRawData;
	
	int32_t _innermostShellLevel;
	int32_t _outermostShellLevel;
}

@synthesize modelID=_modelID, voxelArray=_voxelArray, paletteColors=_paletteColors, meshes=_meshes, innermostShellLevel=_innermostShellLevel, outermostShellLevel=_outermostShellLevel;

- (uint8_t)safeGetVoxelPaletteIndexAtX:(int16_t)x Y:(int16_t)y Z:(int16_t)z {
	vector_short3 dimensions = { _voxelDimensions.x, _voxelDimensions.y, _voxelDimensions.z };
	
	if (x < 0 || y < 0 || z < 0)
		return kZeroPaletteIndex;
	if (x >= dimensions.x || y >= dimensions.y || z >= dimensions.z)
		return kZeroPaletteIndex;
	
	return _voxelPaletteIndices3DRawData[arrayIndexFrom3DCoords(x, y, z, dimensions)];
}

- (uint8_t)safeGetVoxelPaletteIndexAt:(vector_short3)vector {
	return [self safeGetVoxelPaletteIndexAtX:vector.x Y:vector.y Z:vector.z];
}

- (uint32_t)voxelCount {
	return _voxelCount;
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


- (instancetype)initWithMVVoxData:(MagicaVoxelVoxData *)mvvoxData modelID:(uint32_t)modelID optionsValues:(const OptionsValues)optionsValues
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_options = optionsValues;
	[_options.voxelMesh retain];
	[_options.paletteIndexReplacements retain];
	
	_mvvoxData = [mvvoxData retain];
	
	NSParameterAssert(modelID >= 0 && modelID < _mvvoxData.modelCount);
	_modelID = modelID;
	
	MagicaVoxelVoxData_VoxelArray mvvoxVoxels = [_mvvoxData voxelsForModelID:_modelID];
	
	MagicaVoxelVoxData_XYZDimensions mvvoxDimensions = [_mvvoxData dimensionsForModelID:_modelID];
	
	MDLVoxelAsset_VoxelDimensions voxelDimensions = _options.convertZUpToYUp ?
		(MDLVoxelAsset_VoxelDimensions){ mvvoxDimensions.x, mvvoxDimensions.z, mvvoxDimensions.y } :
		(MDLVoxelAsset_VoxelDimensions){ mvvoxDimensions.x, mvvoxDimensions.y, mvvoxDimensions.z };
	_voxelDimensions = voxelDimensions;
	vector_short3 dimensions = { _voxelDimensions.x, _voxelDimensions.y, _voxelDimensions.z };
	
	_voxelsRawData = calloc(mvvoxVoxels.count, sizeof(MDLVoxelIndex));
	for (int32_t vI = mvvoxVoxels.count - 1; vI >= 0; --vI) {
		const MagicaVoxelVoxData_Voxel *mvvoxVoxel = &mvvoxVoxels.array[vI];
		
		if (_options.convertZUpToYUp)
			_voxelsRawData[vI] = (MDLVoxelIndex){ mvvoxVoxel->x, mvvoxVoxel->z, (mvvoxDimensions.y - 1 + -mvvoxVoxel->y), 0 };
		else
			_voxelsRawData[vI] = (MDLVoxelIndex){ mvvoxVoxel->x, mvvoxVoxel->y, mvvoxVoxel->z, 0 };
	}
	_voxelsData = [[NSData alloc] initWithBytesNoCopy:_voxelsRawData length:(mvvoxVoxels.count * sizeof(MDLVoxelIndex)) freeWhenDone:NO];
	
	_mvvoxVoxelsArray = calloc(mvvoxVoxels.count, sizeof(MagicaVoxelVoxData_Voxel));
	memcpy(_mvvoxVoxelsArray, [_mvvoxData voxelsForModelID:_modelID].array, mvvoxVoxels.count * sizeof(MagicaVoxelVoxData_Voxel));
	_voxelCount = mvvoxVoxels.count;
	
	_innermostShellLevel = 0;
	_outermostShellLevel = 0;
	if (_options.calculateShellLevels) {
		[self calculateShellLevels];
		
		if (_options.skipNonZeroShellMesh) {
			// Loop through all original voxels in `_voxelsRawData`, copying them to the same or earlier array positions and recucing the `_voxelCount`.
			uint32_t originalVoxI = 0;
			uint32_t updatedVoxI = 0;
			for (uint32_t originalVoxI = 0; originalVoxI < _voxelCount; ++originalVoxI) {
				MDLVoxelIndex voxelIndex = _voxelsRawData[originalVoxI];
				
				// Basically, while hitting non-shell-zero, searches through the `originalVoxI` indexes (without changing `updatedVoxI`) until we hit a zero-shell voxel.
				if (voxelIndex.w != 0)
					continue;
				
				_voxelsRawData[updatedVoxI] = voxelIndex;
				memcpy(&_mvvoxVoxelsArray[updatedVoxI], &_mvvoxVoxelsArray[originalVoxI], sizeof(MagicaVoxelVoxData_Voxel));
				
				++updatedVoxI;
			}
			_voxelCount = updatedVoxI;
		}
		
		[_voxelsData release];
		_voxelsData = [[NSData alloc] initWithBytesNoCopy:_voxelsRawData length:(_voxelCount * sizeof(MDLVoxelIndex)) freeWhenDone:NO];
	}
	
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
	
	_voxelPaletteIndices3DRawData = calloc(voxelDimensions.x * voxelDimensions.y * voxelDimensions.z, sizeof(uint8_t));
	for (int32_t vI = 0; vI < _voxelCount; ++vI) {
		const MagicaVoxelVoxData_Voxel *mvvoxVoxel = &_mvvoxVoxelsArray[vI];
		
		uint8_t colorIndex = mvvoxVoxel->colorIndex;
		if (_options.paletteIndexReplacements != nil) {
			NSNumber *replacementValue = _options.paletteIndexReplacements[@(colorIndex)];
			if (replacementValue != nil)
				colorIndex = replacementValue.unsignedCharValue;
		}
		
		_voxelPaletteIndices3DRawData[arrayIndexFrom3DCoords(mvvoxVoxel->x, mvvoxVoxel->y, mvvoxVoxel->z, dimensions)] = colorIndex;
	}
	
	
	MagicaVoxelVoxData_PaletteColorArray mvvoxPaletteColors = _mvvoxData.paletteColors;
	
	NSMutableArray<Color*> *paletteColors = [[NSMutableArray alloc] initWithCapacity:(mvvoxPaletteColors.count + 1)];
	paletteColors[0] = [Color clearColor];
	for (uint16_t pI = 1; pI <= mvvoxPaletteColors.count; ++pI) {
		const MagicaVoxelVoxData_PaletteColor *voxColor = &mvvoxPaletteColors.array[pI - 1];
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
	return [self retain]; // MDLVoxelAssetModel is immutable, so just keep using the same instance.
}


typedef void(^GenerateMesh_AddMeshDataCallback)(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType geometryType);

- (void)generateMesh
{
	if (_meshes == nil) {
		_meshes = [NSMutableArray new];
	} else {
		[_meshes removeAllObjects];
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
			// TODO: Figure out `objectsToConsider:`
			BOOL aoSuccess = [mesh generateAmbientOcclusionVertexColorsWithQuality:0.1 attenuationFactor:0.1 objectsToConsider:[NSArray<MDLObject*> array] vertexAttributeNamed:MDLVertexAttributeOcclusionValue];
		}
		
		[_meshes addObject:mesh];
		[mesh release];
	};
	
	switch (_options.meshGenerationMode) {
		case MDLVoxelAssetMeshGenerationModeSkip:
			return;
		case MDLVoxelAssetMeshGenerationModeSceneKit:
			[self generateSceneKitMesh:addMeshDataCallback];
			break;
		case MDLVoxelAssetMeshGenerationModeMDLVoxelArrayCoarse:
			if ([MDLVoxelArray instancesRespondToSelector:@selector(coarseMesh)])
				[self generateMDLVoxelArrayMesh:NO];
			break;
		case MDLVoxelAssetMeshGenerationModeMDLVoxelArraySmooth:
			[self generateMDLVoxelArrayMesh:YES];
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
	static uint32_t const kFacesPerVoxel = 6;
	
	static uint32_t const kVerticesPerVoxel = 4 * kFacesPerVoxel;
	uint32_t vertexCount = _voxelCount * kVerticesPerVoxel;
	NSAssert(sizeof(kVoxelCubeVertexData) / sizeof(PerVertexMeshData) == kVerticesPerVoxel,
		@"`sizeof(kVoxelCubeVertexData) / sizeof(PerVertexMeshData)` must equal %lu.", (unsigned long)kVerticesPerVoxel
	);
	_verticesRawData = calloc(vertexCount, sizeof(PerVertexMeshData));
	#if DEBUG
		memset(_verticesRawData, '\xFF', vertexCount * sizeof(PerVertexMeshData));
	#endif
	
	static uint32_t const kVertexIndicesPerVoxel = 6 * kFacesPerVoxel;
	uint32_t vertexIndexCount = _voxelCount * kVertexIndicesPerVoxel;
	NSAssert(sizeof(kVoxelCubeVertexIndexData) / sizeof(uint16_t) == kVertexIndicesPerVoxel,
		@"`sizeof(kVoxelCubeVertexIndexData) / sizeof(uint16_t)` must equal %lu.", (unsigned long)kVertexIndicesPerVoxel
	);
	_vertexIndicesRawData = calloc(vertexIndexCount, sizeof(uint16_t));
	#if DEBUG
		memset(_vertexIndicesRawData, '\xFF', vertexIndexCount * sizeof(uint16_t));
	#endif
	
	for (uint32_t voxI = 0; voxI < _voxelCount; ++voxI)
	{
		MDLVoxelIndex voxelIndex = _voxelsRawData[voxI];
		
		uint32_t baseVertI = voxI * kVerticesPerVoxel;
		memcpy(&_verticesRawData[baseVertI], kVoxelCubeVertexData, sizeof(kVoxelCubeVertexData));
		for (uint32_t vertI = 0; vertI < kVerticesPerVoxel; ++vertI)
			_verticesRawData[baseVertI + vertI].position += (vector_float3){ voxelIndex.x, voxelIndex.y, voxelIndex.z };
		
		uint8_t colorIndex = _mvvoxVoxelsArray[voxI].colorIndex;
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
	
	static const uint32_t kPerMeshVertexCountLimit = 65536;
	const uint32_t perMeshVoxelCountLimit = kPerMeshVertexCountLimit / kVerticesPerVoxel;
	
	for (uint32_t voxI = 0; voxI < _voxelCount; ++voxI)
	{
		uint32_t startVoxI = voxI;
		uint32_t voxILimit = MIN(voxI + perMeshVoxelCountLimit, _voxelCount);
		
		while (voxI < voxILimit)
		{
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

- (void)generateMDLVoxelArrayMesh:(BOOL)smooth
{
	MDLMesh *mesh;
	if (smooth)
		mesh = [_voxelArray meshUsingAllocator:nil];
	else
		mesh = [_voxelArray coarseMesh];
	
	if (_options.generateAmbientOcclusion) {
		// TODO: Figure out `objectsToConsider:`
		BOOL aoSuccess = [mesh generateAmbientOcclusionVertexColorsWithQuality:0.1 attenuationFactor:0.1 objectsToConsider:[NSArray<MDLObject*> array] vertexAttributeNamed:MDLVertexAttributeOcclusionValue];
	}
	
	[_meshes addObject:mesh];
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
		addVertexIndicesRawDataCallback: ^(uint32_t baseVertIndexI, uint32_t baseVertI) {
			_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 0;
			_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 1;
			_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 2;
			_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 3;
		}
	];
}

- (void)generateGreedyTriMesh:(GenerateMesh_AddMeshDataCallback)addMeshDataCallback
{
	[self generateGreedyMesh:^(NSData *verticesData, uint32_t verticesCount, NSData *vertexIndicesData, uint32_t vertexIndicesCount, MDLGeometryType _) {
			addMeshDataCallback(verticesData, verticesCount, vertexIndicesData, vertexIndicesCount, MDLGeometryTypeTriangles);
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
		addVertexIndicesRawDataCallback: ^(uint32_t baseVertIndexI, uint32_t baseVertI) {
			_vertexIndicesRawData[baseVertIndexI + 0] = baseVertI + 0;
			_vertexIndicesRawData[baseVertIndexI + 1] = baseVertI + 1;
			_vertexIndicesRawData[baseVertIndexI + 2] = baseVertI + 2;
			
			_vertexIndicesRawData[baseVertIndexI + 3] = baseVertI + 0;
			_vertexIndicesRawData[baseVertIndexI + 4] = baseVertI + 2;
			_vertexIndicesRawData[baseVertIndexI + 5] = baseVertI + 3;
		}
	];
}

typedef void(^GenerateGreedyMesh_AddVerticesRawDataCallback)(uint32_t baseVertI, vector_short3 basePosition, vector_short3 positionUDelta, vector_short3 positionVDelta, vector_float3 normalData, vector_float3 colorData, vector_float2 textureCoordinateData);
typedef void(^GenerateGreedyMesh_AddVertexIndicesRawDataCallback)(uint32_t baseVertIndexI, uint32_t baseVertI);

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
	
	// Will contain the groups of matching voxel faces as we proceed through the chunk in 6 directions - once for each face.
	int16_t paletteIndexMask[kMagicaVoxelMaxDimension * kMagicaVoxelMaxDimension] = { 0 };
	
	// Sweep over the 3 dimensions - most of what follows is well described by Mikola Lysenko in his post - and is ported from his Javascript implementation.
	// Where this implementation diverges, I've added commentary.
	for (int axisI = 0; axisI < 3; axisI++)
	{
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
					int16_t voxelAPaletteIndex = 0;
					if (x[axisI] >= 0) {
						vector_short3 i = x;
						voxelAPaletteIndex = _voxelPaletteIndices3DRawData[arrayIndexFrom3DCoords(i.x, i.y, i.z, dimensions)];
					}
					int16_t voxelBPaletteIndex = 0;
					if (x[axisI] < dimensions[axisI] - 1) {
						vector_short3 i = x + q;
						voxelBPaletteIndex = _voxelPaletteIndices3DRawData[arrayIndexFrom3DCoords(i.x, i.y, i.z, dimensions)];
					}
					
					// Note that we're using the equals function in the voxel face class here, which lets the faces be compared based on any number of attributes.
					// Also, we choose the face to add to the `paletteIndexMask` depending on whether we're moving through on a backface or not.
					if ((voxelAPaletteIndex != 0 && voxelBPaletteIndex != 0) || voxelAPaletteIndex == voxelBPaletteIndex)
						paletteIndexMask[n] = 0;
					else if (voxelAPaletteIndex != 0)
						paletteIndexMask[n] = voxelAPaletteIndex;
					else // `voxelBPaletteIndex != 0`
						paletteIndexMask[n] = -voxelBPaletteIndex;
					
					if (voxelAPaletteIndex > 255 || voxelBPaletteIndex > 255)
						printf("");
					if (n == 470)
						printf("");
					
					n += 1;
				}
			}
			
			
			x[axisI] += 1;
			
			// Generate the mesh for the `paletteIndexMask` using lexicographic ordering
			n = 0;
			
			for (int vI = 0; vI < dimensions[v]; ++vI)
			{
				for (int uI = 0; uI < dimensions[u];)
				{
					int16_t paletteIndex = paletteIndexMask[n];
					
					if (paletteIndex == 0) {
						uI += 1;
						n += 1;
						continue;
					}
					
					BOOL isPosFace = paletteIndex > 0;
					
					// Compute the quad width
					int width = 1;
					while (uI + width < dimensions[u]) {
						int16_t checkPaletteIndex = paletteIndexMask[n + width];
						if (checkPaletteIndex != paletteIndex)
							break;
						
						width += 1;
					}
					
					// Compute quad height
					int height = 1;
					while (vI + height < dimensions[v]) {
						for (int uCheckI = 0; uCheckI < width; ++uCheckI) {
							int16_t checkPaletteIndex = paletteIndexMask[n + (height * dimensions[u]) + uCheckI];
							if (checkPaletteIndex != paletteIndex)
								goto breakComputeHeight;
						}
						
						height += 1;
					}
					breakComputeHeight: ;
					
					if (!isPosFace)
						paletteIndex = -paletteIndex;
					
					NSUInteger meshFaceDirection = 1 << (axisI * 2 + (isPosFace ? 1 : 0));
					if ((_options.skipMeshFaceDirections & meshFaceDirection) == 0)
					{
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
						
						vector_short3 uDelta = { 0, 0, 0 };
						vector_short3 vDelta = { 0, 0, 0 };
						if (isPosFace) {
							vDelta[v] = height;
							uDelta[u] = width;
						} else {
							uDelta[v] = height;
							vDelta[u] = width;
						}
						
						// Call the quad function in order to render a merged quad in the scene.
						// Passing `paletteIndex` to the function, which is an instance of the VoxelFace class containing all the attributes of the face - which allows for variables to be passed to shaders - for example lighting values used to create ambient occlusion.
						{
							uint32_t baseVertI = faceI * verticesPerFace;
							uint32_t baseVertIndexI = faceI * vertexIndicesPerFace;
							
							vector_float3 normal = { 0.0 }; normal[axisI] = isPosFace ? +1.0 : -1.0;
							
							Color *color = _paletteColors[paletteIndex];
							CGFloat color_cgArray[4];
							[color getRed:&color_cgArray[0] green:&color_cgArray[1] blue:&color_cgArray[2] alpha:&color_cgArray[3]];
							vector_float3 colorData = { color_cgArray[0], color_cgArray[1], color_cgArray[2] };
							static const vector_short2 mvvoxPaletteTextureSize = { 256, 1 };
							vector_float2 textureCoordinateData = { /* x: */ (paletteIndex - 1 + 0.5f) / mvvoxPaletteTextureSize.x, /* y: */ 0.5f }; // NOTE: no special-case for index #0 (transparent)
							
							addVerticesRawDataCallback(baseVertI, x, uDelta, vDelta, normal, colorData, textureCoordinateData);
							
							addVertexIndicesRawDataCallback(baseVertIndexI, baseVertI);
						}
					} // `(_options.skipMeshFaceDirections & meshFaceDirection) == 0`
					
					// Zero out the `paletteIndexMask`
					for (int vZeroingI = height - 1; vZeroingI >= 0; --vZeroingI)
						memset(&paletteIndexMask[n + (vZeroingI * dimensions[u])], 0, width * sizeof(int16_t));
					
					// Increment the counters and continue
					uI += width;
					n += width;
				} // `uI`
			} // `vI`
		} // `x[axisI]`
	} // `axisI`
	
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
	
	free(_mvvoxVoxelsArray);
	_mvvoxVoxelsArray = NULL;
	
	free(_voxelsRawData);
	_voxelsRawData = NULL;
	[_voxelsData release];
	_voxelsData = nil;
	
	[_paletteColors release];
	_paletteColors = nil;
	free(_voxelPaletteIndices3DRawData);
	_voxelPaletteIndices3DRawData = NULL;
	[_voxelArray release];
	_voxelArray = nil;
	
	[_mvvoxData release];
	_mvvoxData = nil;
	
	[_options.voxelMesh release];
	[_options.paletteIndexReplacements release];
	
	[super dealloc];
}


+ (BOOL)canImportFileExtension:(NSString *)extension
{
	if ([extension isEqualToString:@"vox"])
		return YES;
	
	return NO;
}


- (NSArray<NSArray<NSArray<NSNumber*>*>*> *)voxelPaletteIndices
{
	vector_short3 dimensions = { _voxelDimensions.x, _voxelDimensions.y, _voxelDimensions.z };
	
	NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*> *voxelPaletteIndices = [[NSMutableArray alloc] initWithCapacity:dimensions.x];
	for (uint32_t xI = 0; xI < dimensions.x; ++xI) {
		[(voxelPaletteIndices[xI] = [[NSMutableArray alloc] initWithCapacity:dimensions.y]) release];
		for (uint32_t yI = 0; yI < dimensions.y; ++yI) {
			[(voxelPaletteIndices[xI][yI] = [[NSMutableArray alloc] initWithCapacity:dimensions.z]) release];
			for (uint32_t zI = 0; zI < dimensions.z; ++zI) {
				uint8_t paletteIndex = _voxelPaletteIndices3DRawData[arrayIndexFrom3DCoords(xI, yI, zI, dimensions)];
				[(voxelPaletteIndices[xI][yI][zI] = [[NSNumber alloc] initWithUnsignedChar:paletteIndex]) release];
			}
		}
	}
	
	return [voxelPaletteIndices autorelease];
}


MDLVoxelIndexPtr calculateShellLevels_safeGetVoxelIndexPtr(vector_short3 coord, MDLVoxelIndexPtr *voxelIndexPtrs3D, vector_short3 dimensions) {
	if (coord.x < 0 || coord.y < 0 || coord.z < 0)
		return NULL;
	if (coord.x >= dimensions.x || coord.y >= dimensions.y || coord.z >= dimensions.z)
		return NULL;
	
	return voxelIndexPtrs3D[arrayIndexFrom3DCoords(coord.x, coord.y, coord.z, dimensions)];
}

- (void)calculateShellLevels
{
	MDLVoxelIndex *voxelIndices = _voxelsRawData;
	uint32_t voxelCount = self.voxelCount;
	vector_short3 dimensions = { _voxelDimensions.x, _voxelDimensions.y, _voxelDimensions.z };
	
	MDLVoxelIndexPtr *voxelIndexPtrs3D = calloc(_voxelDimensions.x * _voxelDimensions.y * _voxelDimensions.z, sizeof(MDLVoxelIndexPtr));
	for (int64_t vI = voxelCount - 1; vI >= 0; --vI) {
		MDLVoxelIndexPtr voxelIndexPtr = &voxelIndices[vI];
		voxelIndexPtrs3D[arrayIndexFrom3DCoords(voxelIndexPtr->x, voxelIndexPtr->y, voxelIndexPtr->z, dimensions)] = voxelIndexPtr;
	}
	
	_outermostShellLevel = 0;
	
	// Iteratively loops over all the `voxelIndices` at the `currentShellLevel`, checks if they have neighbors on all sides of the same or lower (inner) shell levels, and if so reduces it's level by -1.
	// Repeats the whole process with `--currentShellLevel`, continuing until it has made a pass without finding any voxels to reduce the shell level of (`!didAddShell`).
	BOOL didAddShell;
	int currentShellLevel = 0;
	 while (true) // do-while-do loop
	 {
		// do:
		
		didAddShell = NO;
		
		for (int32_t vI = voxelCount - 1; vI >= 0; --vI) {
			MDLVoxelIndex voxel = voxelIndices[vI];
			if (voxel.w != currentShellLevel)
				continue;
			
			vector_short3 coord = simd_make_short3(voxel.x, voxel.y, voxel.z);
			
			MDLVoxelIndexPtr neighborXPos = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(+1, 0, 0), voxelIndexPtrs3D, dimensions);
			MDLVoxelIndexPtr neighborXNeg = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(-1, 0, 0), voxelIndexPtrs3D, dimensions);
			MDLVoxelIndexPtr neighborYPos = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(0, +1, 0), voxelIndexPtrs3D, dimensions);
			MDLVoxelIndexPtr neighborYNeg = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(0, -1, 0), voxelIndexPtrs3D, dimensions);
			MDLVoxelIndexPtr neighborZPos = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(0, 0, +1), voxelIndexPtrs3D, dimensions);
			MDLVoxelIndexPtr neighborZNeg = calculateShellLevels_safeGetVoxelIndexPtr(coord + simd_make_short3(0, 0, -1), voxelIndexPtrs3D, dimensions);
			
			// check for presense of neighbors, and if present, that it's the same or lower (inner) shell level.
			BOOL coveredXPos = (neighborXPos != NULL) && (neighborXPos->w <= currentShellLevel);
			BOOL coveredXNeg = (neighborXNeg != NULL) && (neighborXNeg->w <= currentShellLevel);
			BOOL coveredYPos = (neighborYPos != NULL) && (neighborYPos->w <= currentShellLevel);
			BOOL coveredYNeg = (neighborYNeg != NULL) && (neighborYNeg->w <= currentShellLevel);
			BOOL coveredZPos = (neighborZPos != NULL) && (neighborZPos->w <= currentShellLevel);
			BOOL coveredZNeg = (neighborZNeg != NULL) && (neighborZNeg->w <= currentShellLevel);
			
			BOOL coveredOnAllSides = coveredXPos && coveredXNeg && coveredYPos && coveredYNeg && coveredZPos && coveredZNeg;
			if (coveredOnAllSides) {
				voxel.w = currentShellLevel - 1;
				voxelIndices[vI] = voxel;
				
				didAddShell = YES;
			}
		}
		
		// while (didAddShell)
		if (!didAddShell) { break; }
		
		// do:
		
		_innermostShellLevel = currentShellLevel;
		
		--currentShellLevel;
	}
	
	free(voxelIndexPtrs3D);
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:_voxelsData boundingBox:self.boundingBox voxelExtent:1.0f];
}


@end
