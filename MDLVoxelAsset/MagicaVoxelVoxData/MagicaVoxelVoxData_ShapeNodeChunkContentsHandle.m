// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_ShapeNodeChunkContentsHandle.h"

#import "MagicaVoxelVoxData_types.h"



@implementation ShapeNodeChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
	
	VoxDict _nodeAttributes;
	size_t _nodeAttributes_size;
	
	int32_t _modelDatums_count;
	size_t _modelDatums_size;
	int32_t *_modelDatumsIDs_array;
	VoxDict *_modelDatumsAttributes_array;
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kShapeNodeChunk_nodeID_offset + kShapeNodeChunk_nodeID_size);
	
	NSParameterAssert(_data.length >= _baseOffset + kShapeNodeChunk_nodeAttributes_offset + self.nodeAttributes_size);
	ptrdiff_t afterNodeAttributesOffset = _baseOffset + kShapeNodeChunk_nodeAttributes_offset + self.nodeAttributes_size;
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kShapeNodeChunk_numModels_afterNodeAttributesOffset + kShapeNodeChunk_numModels_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kShapeNodeChunk_models_afterNodeAttributesOffset + self.models_size);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	_nodeAttributes = VoxDictAtPtr(self.nodeAttributes_ptr);
	_nodeAttributes_size = SizeOfVoxDict(_nodeAttributes);
	
	[self calculateModelDatumsCount];
	[self createModelDatumsArrays];
	
	return self;
}
- (void)dealloc
{
	free(_modelDatumsIDs_array);
	_modelDatumsIDs_array = NULL;
	free(_modelDatumsAttributes_array);
	_modelDatumsAttributes_array = NULL;
	
	[_data release];
	_data = nil;
	
	[super dealloc];
}


#pragma mark - Auto-Populated Info Properties

#pragma mark nodeID

- (ptrdiff_t)nodeID_offset {
	return _baseOffset + kShapeNodeChunk_nodeID_offset;
}
- (int32_t const *)nodeID_ptr {
	return (int32_t const *)&_data.bytes[self.nodeID_offset];
}
- (int32_t)nodeID {
	return *self.nodeID_ptr;
}


#pragma mark nodeAttributes

- (ptrdiff_t)nodeAttributes_offset {
	return _baseOffset + kShapeNodeChunk_nodeAttributes_offset;
}
- (void const *)nodeAttributes_ptr {
	return (void const *)&_data.bytes[self.nodeAttributes_offset];
}
@synthesize nodeAttributes_size=_nodeAttributes_size, nodeAttributes=_nodeAttributes;


#pragma mark numModels

- (ptrdiff_t)numModels_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kShapeNodeChunk_numModels_afterNodeAttributesOffset;
}
- (int32_t const *)numModels_ptr {
	return (int32_t const *)&_data.bytes[self.numModels_offset];
}
- (int32_t)numModels {
	return *self.numModels_ptr;
}


#pragma mark models

- (ptrdiff_t)models_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kShapeNodeChunk_models_afterNodeAttributesOffset;
}
- (void)calculateModelDatumsCount {
	_modelDatums_count = self.numModels;
}
@synthesize models_count=_modelDatums_count;
- (void const *)models_ptr {
	return (void const *)&_data.bytes[self.models_offset];
}

- (void)createModelDatumsArrays
{
	_modelDatums_size = 0;
	_modelDatumsIDs_array = calloc(_modelDatums_size, sizeof(int32_t));
	_modelDatumsAttributes_array = calloc(_modelDatums_size, sizeof(VoxDict));
	
	void const *modelPtr = self.models_ptr;
	for (int modelI = 0; modelI < _modelDatums_count; ++modelI) {
		int32_t modelID = *(int32_t *)&modelPtr[0];
		_modelDatumsIDs_array[modelI] = modelID;
		_modelDatums_size += sizeof(int32_t);
		
		VoxDict modelAttributes = VoxDictAtPtr(&modelPtr[(ptrdiff_t)sizeof(int32_t)]);
		_modelDatumsAttributes_array[modelI] = modelAttributes;
		_modelDatums_size += SizeOfVoxDict(modelAttributes);
		
		modelPtr += (ptrdiff_t)SizeOfVoxDict(modelAttributes);
	}
}
@synthesize models_size=_models_size;

- (int32_t)modelIDForModel:(uint32_t)modelIndex
{
	NSParameterAssert(modelIndex >= 0 && modelIndex < _modelDatums_count);
	return _modelDatumsIDs_array[modelIndex];
}

- (VoxDict)modelAttributesForModel:(uint32_t)modelIndex
{
	NSParameterAssert(modelIndex >= 0 && modelIndex < _modelDatums_count);
	return _modelDatumsAttributes_array[modelIndex];
}


#pragma mark totalSize

- (size_t)totalSize {
	return kShapeNodeChunk_nodeID_size + self.nodeAttributes_size + kShapeNodeChunk_numModels_size + self.models_size;
}


@end
