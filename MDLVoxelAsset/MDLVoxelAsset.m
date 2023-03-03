// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <MDLVoxelAsset/MDLVoxelAsset.h>

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



NSString *const kMDLVoxelAssetOptionCalculateShellLevels = @"MDLVoxelAssetOptionCalculateShellLevels";
NSString *const kMDLVoxelAssetOptionSkipNonZeroShellMesh = @"MDLVoxelAssetOptionSkipNonZeroShellMesh";
NSString *const kMDLVoxelAssetOptionMeshGenerationMode = @"MDLVoxelAssetOptionMeshGenerationMode";
NSString *const kMDLVoxelAssetOptionMeshGenerationFlattening = @"MDLVoxelAssetOptionMeshGenerationFlattening";
NSString *const kMDLVoxelAssetOptionVoxelMesh = @"MDLVoxelAssetOptionVoxelMesh";
NSString *const kMDLVoxelAssetOptionConvertZUpToYUp = @"MDLVoxelAssetOptionConvertZUpToYUp";
NSString *const kMDLVoxelAssetOptionGenerateAmbientOcclusion = @"MDLVoxelAssetOptionGenerateAmbientOcclusion";
NSString *const kMDLVoxelAssetOptionPaletteIndexReplacements = @"MDLVoxelAssetOptionPaletteReplacements";
NSString *const kMDLVoxelAssetOptionSkipMeshFaceDirections = @"MDLVoxelAssetOptionSkipMeshFaceDirections";


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
	
	MagicaVoxelVoxData_TransformNode *_nodeSceneGraph;
	
	NSMutableArray<MDLVoxelAssetModel*> *_models;
}

@synthesize voxelArray=_voxelArray, voxelPaletteIndices=_voxelPaletteIndices, paletteColors=_paletteColors;

- (uint32_t)voxelCount {
	return [_mvvoxData voxelsForModelID:0].count;
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
	
	_models = [NSMutableArray<MDLVoxelAssetModel*> new];
	
	_nodeSceneGraph = [_mvvoxData.sceneGraphRootNode retain];
	if (_nodeSceneGraph)
	{
		MDLObject *objectHierarchy = [self mdlObjectHierarchyForMVVDSceneGraph:_nodeSceneGraph];
		//if (_options.convertZUpToYUp) {
		//	simd_float4x4 matrix = objectHierarchy.transform.matrix;
		//	objectHierarchy.transform.matrix = simd_matrix(matrix.columns[0], matrix.columns[2], matrix.columns[1], matrix.columns[3]); // swap Y & Z columns
		//}
		[super addObject:objectHierarchy];
	}
	else // !_nodeSceneGraph
	{
		uint32_t modelCount = _mvvoxData.modelCount;
		for (uint32_t modelI = 0; modelI < modelCount; ++modelI) {
			MDLVoxelAssetModel *model = [self loadModelWithModelID:modelI];
			
			MDLVoxelAsset_VoxelDimensions modelVoxelDimensions = model.voxelDimensions;
			_voxelDimensions.x = MAX(_voxelDimensions.x, modelVoxelDimensions.x);
			_voxelDimensions.y = MAX(_voxelDimensions.y, modelVoxelDimensions.y);
			_voxelDimensions.z = MAX(_voxelDimensions.z, modelVoxelDimensions.z);
			
			for (MDLMesh *modelMesh in model.meshes)
				[super addObject:modelMesh];
		}
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
	
	return self;
}

- (MDLVoxelAssetModel *)loadModelWithModelID:(int32_t)modelID
{
	MDLVoxelAssetModel *model = [[MDLVoxelAssetModel alloc] initWithMVVoxData:_mvvoxData modelID:modelID optionsValues:_options];
	[_models addObject:model];
	return [model autorelease];
}

- (MDLObject *)mdlObjectHierarchyForMVVDSceneGraph:(MagicaVoxelVoxData_TransformNode *)transformNode
{
	MDLObject *baseObject = [MDLObject new];
	baseObject.name = transformNode.name;
	
	simd_float4x4 zToYBasisConversionMatrix = simd_matrix(
		simd_make_float4(1, 0, 0, 0),
		simd_make_float4(0, 0, 1, 0),
		simd_make_float4(0, 1, 0, 0),
		simd_make_float4(0, 0, 0, 1)
	);
	
	simd_float3x3 rotationMatrix = transformNode.frames[0].rotation;
	//if (_options.convertZUpToYUp)
	//	rotationMatrix = simd_matrix(rotationMatrix.columns[0], -rotationMatrix.columns[2], rotationMatrix.columns[1]); // swap Y & Z columns
	simd_float3 translationVector = simd_float(transformNode.frames[0].translation);
	//if (_options.convertZUpToYUp)
	//	translationVector = simd_make_float3(translationVector.x, translationVector.z, translationVector.y); // swap Y & Z
	
	MagicaVoxelVoxData_Node *childNode = transformNode.childNode;
	if ([childNode isMemberOfClass:MagicaVoxelVoxData_GroupNode.class]) {
		MagicaVoxelVoxData_GroupNode *groupNode = (MagicaVoxelVoxData_GroupNode *)childNode;
		
		simd_float4x4 matrix = simd_matrix(
			simd_make_float4(rotationMatrix.columns[0], 0.0),
			simd_make_float4(rotationMatrix.columns[1], 0.0),
			simd_make_float4(rotationMatrix.columns[2], 0.0),
			simd_make_float4(translationVector, 1.0)
		);
		if (_options.convertZUpToYUp)
			matrix = simd_mul(simd_mul(zToYBasisConversionMatrix, matrix), simd_inverse(zToYBasisConversionMatrix));
		// fix to make sure MDLTransform recognizes it as an affine matrix
		matrix.columns[0] = round(matrix.columns[0] * 100) * 0.01;
		matrix.columns[1] = round(matrix.columns[1] * 100) * 0.01;
		matrix.columns[2] = round(matrix.columns[2] * 100) * 0.01;
		matrix.columns[3] = round(matrix.columns[3] * 100) * 0.01;
		
		baseObject.transform = [[[MDLTransform alloc] initWithMatrix:matrix] autorelease];
		
		for (MagicaVoxelVoxData_TransformNode *childTransformNode in groupNode.childrenNodes) {
			MDLObject *child = [self mdlObjectHierarchyForMVVDSceneGraph:childTransformNode];
			[baseObject addChild:child];
		}
	}
	else if ([childNode isMemberOfClass:MagicaVoxelVoxData_ShapeNode.class]) {
		MagicaVoxelVoxData_ShapeNode *shapeNode = (MagicaVoxelVoxData_ShapeNode *)childNode;
		
		for (MagicaVoxelVoxData_Model *modelNode in shapeNode.models) {
			MDLVoxelAssetModel *model = [self loadModelWithModelID:modelNode.modelID];
			
			// re-pivot the transform
			
			MDLVoxelAsset_VoxelDimensions modelVoxelDimensions = model.voxelDimensions;
			simd_float3 halfDimensions = (_options.convertZUpToYUp ? // un-YZ-swap already-swapped dimensinos
				(simd_float3){ (float)modelVoxelDimensions.x, (float)modelVoxelDimensions.z, (float)modelVoxelDimensions.y } :
				(simd_float3){ (float)modelVoxelDimensions.x, (float)modelVoxelDimensions.y, (float)modelVoxelDimensions.z }
			) * 0.5;
			simd_float4x4 transformPivotMatrix = simd_matrix(
				(simd_float4){ 1, 0, 0, 0 },
				(simd_float4){ 0, 1, 0, 0 },
				(simd_float4){ 0, 0, 1, 0 },
				simd_make_float4(-halfDimensions, 1)
			);
			simd_float4x4 transformRotationMatrix = simd_matrix(
				simd_make_float4(rotationMatrix.columns[0], 0),
				simd_make_float4(rotationMatrix.columns[1], 0),
				simd_make_float4(rotationMatrix.columns[2], 0),
				simd_make_float4(0, 0, 0, 1)
			);
			if (_options.convertZUpToYUp)
				;//translationVector.y = -translationVector.y;
			simd_float4x4 transformTranslationMatrix = simd_matrix(
				(simd_float4){ 1, 0, 0, 0 },
				(simd_float4){ 0, 1, 0, 0 },
				(simd_float4){ 0, 0, 1, 0 },
				simd_make_float4(translationVector, 1)
			);
			simd_float4x4 matrix = simd_mul(transformTranslationMatrix, simd_mul(transformRotationMatrix, transformPivotMatrix));
			if (_options.convertZUpToYUp) {
				matrix = simd_mul(simd_mul(zToYBasisConversionMatrix, matrix), simd_inverse(zToYBasisConversionMatrix));
				//matrix.columns[3].y = -matrix.columns[3].y; // invert Y (up); can't tell you why
			}
			// fix to make sure MDLTransform recognizes it as an affine matrix
			matrix.columns[0] = round(matrix.columns[0] * 100) * 0.01;
			matrix.columns[1] = round(matrix.columns[1] * 100) * 0.01;
			matrix.columns[2] = round(matrix.columns[2] * 100) * 0.01;
			matrix.columns[3] = round(matrix.columns[3] * 100) * 0.01;
			
			baseObject.transform = [[[MDLTransform alloc] initWithMatrix:matrix] autorelease];
			
			// TODO: _voxelDimensions = …
			
			for (MDLMesh *modelMesh in model.meshes)
				[baseObject addChild:modelMesh];
		}
	}
	else {
		NSAssert(false, @"Unhandled childNode %@", childNode);
	}
	
	return [baseObject autorelease];
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

- (void)dealloc
{
	[_models release];
	_models = nil;
	
	[_nodeSceneGraph release];
	_nodeSceneGraph = nil;
	
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
	
	self.URL = nil;
	
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
	for (MDLVoxelAssetModel *model in _models) {
		[model calculateShellLevels];
	}
}

- (NSArray<MDLMesh*> *)meshes
{
	NSMutableArray<MDLMesh*> *allMeshes = [NSMutableArray<MDLMesh*> array];
	for (MDLVoxelAssetModel *model in _models) {
		[allMeshes addObjectsFromArray:model.meshes];
	}
	return allMeshes;
}

- (NSArray<MDLVoxelAssetModel*> *)models
{
	return _models;
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
