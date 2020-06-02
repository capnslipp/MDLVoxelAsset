// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_TransformNodeChunkContentsHandle.h"

#import "MagicaVoxelVoxData_types.h"



@implementation TransformNodeChunkContentsHandle {
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
	
	NSParameterAssert(_data.length >= _baseOffset + kTransformNodeChunk_nodeID_offset + kTransformNodeChunk_nodeID_size);
	
	NSParameterAssert(_data.length >= _baseOffset + kTransformNodeChunk_nodeAttributes_offset + self.nodeAttributes_size);
	ptrdiff_t afterNodeAttributesOffset = _baseOffset + kTransformNodeChunk_nodeAttributes_offset + self.nodeAttributes_size;
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kTransformNodeChunk_childNodeID_afterNodeAttributesOffset + kTransformNodeChunk_childNodeID_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kTransformNodeChunk_reservedID_afterNodeAttributesOffset + kTransformNodeChunk_reservedID_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kTransformNodeChunk_layerID_afterNodeAttributesOffset + kTransformNodeChunk_layerID_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kTransformNodeChunk_numFrames_afterNodeAttributesOffset + kTransformNodeChunk_numFrames_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kTransformNodeChunk_frames_afterNodeAttributesOffset + self.frames_size);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	return self;
}
- (void)dealloc
{
	[_data release];
	_data = nil;
	
	[super dealloc];
}


#pragma mark - Auto-Populated Info Properties

#pragma mark nodeID

- (ptrdiff_t)nodeID_offset {
	return _baseOffset + kTransformNodeChunk_nodeID_offset;
}
- (int32_t const *)nodeID_ptr {
	return (int32_t const *)&_data.bytes[self.nodeID_offset];
}
- (int32_t)nodeID {
	return *self.nodeID_ptr;
}


#pragma mark nodeAttributes

- (ptrdiff_t)nodeAttributes_offset {
	return _baseOffset + kTransformNodeChunk_nodeAttributes_offset;
}
- (void const *)nodeAttributes_ptr {
	return (void const *)&_data.bytes[self.nodeAttributes_offset];
}
- (size_t)nodeAttributes_size {
	return SizeOfVoxDict(self.nodeAttributes);
}
- (VoxDict)nodeAttributes {
	return VoxDictAtPtr(self.nodeAttributes_ptr);
}


#pragma mark childNodeID

- (ptrdiff_t)childNodeID_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kTransformNodeChunk_childNodeID_afterNodeAttributesOffset;
}
- (int32_t const *)childNodeID_ptr {
	return (int32_t const *)&_data.bytes[self.childNodeID_offset];
}
- (int32_t)childNodeID {
	return *self.childNodeID_ptr;
}


#pragma mark reservedID

- (ptrdiff_t)reservedID_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kTransformNodeChunk_reservedID_afterNodeAttributesOffset;
}
- (int32_t const *)reservedID_ptr {
	return (int32_t const *)&_data.bytes[self.reservedID_offset];
}
- (int32_t)reservedID {
	return *self.reservedID_ptr;
}


#pragma mark layerID

- (ptrdiff_t)layerID_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kTransformNodeChunk_layerID_afterNodeAttributesOffset;
}
- (int32_t const *)layerID_ptr {
	return (int32_t const *)&_data.bytes[self.layerID_offset];
}
- (int32_t)layerID {
	return *self.layerID_ptr;
}


#pragma mark numFrames

- (ptrdiff_t)numFrames_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kTransformNodeChunk_numFrames_afterNodeAttributesOffset;
}
- (int32_t const *)numFrames_ptr {
	return (int32_t const *)&_data.bytes[self.numFrames_offset];
}
- (int32_t)numFrames {
	return *self.numFrames_ptr;
}


#pragma mark frames

- (ptrdiff_t)frames_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kTransformNodeChunk_frames_afterNodeAttributesOffset;
}
- (int32_t)frames_count {
	return self.numFrames; // just a method alias
}
- (void const *)frames_ptr {
	return (void const *)&_data.bytes[self.frames_offset];
}
- (size_t)frames_size
{
	size_t size = 0;
	
	int32_t frameCount = self.frames_count;
	void const *framePtr = self.frames_ptr;
	for (int frameI = 0; frameI < frameCount; ++frameI) {
		size_t dictSize = SizeOfVoxDict(VoxDictAtPtr(framePtr));
		framePtr += (ptrdiff_t)dictSize;
		size += dictSize;
	}
	
	return size;
}

- (VoxDict)frameAttributesForFrame:(uint32_t)frameIndex
{
	int32_t frameCount = self.frames_count;
	NSParameterAssert(frameIndex >= 0 && frameIndex < frameCount);
	
	void const *framePtr = self.frames_ptr;
	for (int frameI = 0; frameI < frameIndex; ++frameI) {
		size_t dictSize = SizeOfVoxDict(VoxDictAtPtr(framePtr));
		framePtr += (ptrdiff_t)dictSize;
	}
	
	return VoxDictAtPtr(framePtr);
}

- (VoxString)frameAttributeTranslationStringForFrame:(uint32_t)frameIndex
{
	VoxDict frameAttributes = [self frameAttributesForFrame:frameIndex];
	
	static const char kTranslationKey_CString[] = "_t";
	static const VoxString kTranslationKey_VoxString = {
		.size = sizeof(kTranslationKey_CString) / sizeof(char) - 1,
		.array = (int8_t *)&kTranslationKey_CString
	};
	
	VoxString valueString;
	BOOL didFindValue = VoxDictGetValue(frameAttributes, kTranslationKey_VoxString, &valueString);
	return didFindValue ? valueString : kVoxString_invalidValue;
}


- (simd_int3)frameAttributeSIMDTranslationForFrame:(uint32_t)frameIndex
{
	VoxString translation_VoxString = [self frameAttributeTranslationStringForFrame:frameIndex];
	NSParameterAssert(translation_VoxString.size < 256);
	char translation_CString[256];
	strncpy(translation_CString, (const char *)translation_VoxString.array, translation_VoxString.size);
	translation_CString[translation_VoxString.size] = '\0';
	
	simd_int3 translation = { 0 };
	
	char *componentString = strtok(translation_CString, " ");
	if (componentString == NULL)
		return translation;
	translation[0] = atoi(componentString);
	
	componentString = strtok(NULL, " ");
	if (componentString == NULL)
		return translation;
	translation[1] = atoi(componentString);
	
	componentString = strtok(NULL, " ");
	if (componentString == NULL)
		return translation;
	translation[2] = atoi(componentString);
	
	return translation;
}

- (VoxString)frameAttributeRotationStringForFrame:(uint32_t)frameIndex
{
	VoxDict frameAttributes = [self frameAttributesForFrame:frameIndex];
	
	static const char kRotationKey_CString[] = "_r";
	static const VoxString kRotationKey_VoxString = {
		.size = sizeof(kRotationKey_CString) / sizeof(char) - 1,
		.array = (int8_t *)&kRotationKey_CString
	};
	
	VoxString valueString;
	BOOL didFindValue = VoxDictGetValue(frameAttributes, kRotationKey_VoxString, &valueString);
	return didFindValue ? valueString : kVoxString_invalidValue;
}


- (simd_float3x3)frameAttributeSIMDRotationForFrame:(uint32_t)frameIndex
{
	VoxString rotation_VoxString = [self frameAttributeRotationStringForFrame:frameIndex];
	if (rotation_VoxString.size == 0)
		return matrix_identity_float3x3;
	
	NSParameterAssert(rotation_VoxString.size < 256);
	char rotation_CString[256];
	strncpy(rotation_CString, (const char *)rotation_VoxString.array, rotation_VoxString.size);
	rotation_CString[rotation_VoxString.size] = '\0';
	
	uint8_t rotation_packed = atoi(rotation_CString);
	VoxRotation *rotation = (VoxRotation *)&rotation_packed;
	simd_float3x3 rotation_simd = SIMDMatrixDFromVoxRotation(*rotation);
	return rotation_simd;
}


#pragma mark totalSize

- (size_t)totalSize {
	return kTransformNodeChunk_nodeID_size + self.nodeAttributes_size + kTransformNodeChunk_childNodeID_size + kTransformNodeChunk_reservedID_size + kTransformNodeChunk_layerID_size + kTransformNodeChunk_numFrames_size + self.frames_size;
}


@end
