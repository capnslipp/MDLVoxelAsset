// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_TransformNodeChunkContentsHandle.h"

#import "MagicaVoxelVoxData_types.h"
#import "MagicaVoxelVoxData_utilities.h"



@implementation TransformNodeChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
	
	VoxDict _nodeAttributes;
	size_t _nodeAttributes_size;
	
	int32_t _frames_count;
	size_t _frames_size;
	VoxDict *_frameAttributesForFrames_array;
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
	
	[self calculateNodeAttributes];
	[self calculateFramesCount];
	[self createFrameAttributesForFramesArray];
	
	return self;
}
- (void)dealloc
{
	free(_frameAttributesForFrames_array);
	_frameAttributesForFrames_array = NULL;
	
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
- (void)calculateNodeAttributes {
	_nodeAttributes = VoxDictAtPtr(self.nodeAttributes_ptr);
	_nodeAttributes_size = SizeOfVoxDict(_nodeAttributes);
}
@synthesize nodeAttributes_size=_nodeAttributes_size, nodeAttributes=_nodeAttributes;

- (VoxString)nodeAttributeName
{
	static const char kNameKey_CString[] = "_name";
	static const VoxString kNameKey_VoxString = {
		.size = sizeof(kNameKey_CString) / sizeof(char) - 1,
		.array = (int8_t *)&kNameKey_CString
	};
	
	VoxString valueString;
	BOOL didFindValue = VoxDictGetValue(_nodeAttributes, kNameKey_VoxString, &valueString);
	return didFindValue ? valueString : kVoxString_invalidValue;
}

- (BOOL)nodeAttributeHidden
{
	static const char kNameKey_CString[] = "_hidden";
	static const VoxString kNameKey_VoxString = {
		.size = sizeof(kNameKey_CString) / sizeof(char) - 1,
		.array = (int8_t *)&kNameKey_CString
	};
	
	VoxString valueString;
	BOOL didFindValue = VoxDictGetValue(_nodeAttributes, kNameKey_VoxString, &valueString);
	if (!didFindValue)
		return NO;
	
	return valueString.array[0] == '1' ? YES : NO;
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
- (void)calculateFramesCount {
	_frames_count = self.numFrames;
}
@synthesize frames_count=_frames_count;
- (void const *)frames_ptr {
	return (void const *)&_data.bytes[self.frames_offset];
}

- (void)createFrameAttributesForFramesArray
{
	_frameAttributesForFrames_array = calloc(_frames_count, sizeof(VoxDict));
	_frames_size = 0;
	
	void const *framePtr = self.frames_ptr;
	for (int frameI = 0; frameI < _frames_count; ++frameI) {
		VoxDict frameDict = VoxDictAtPtr(framePtr);
		_frameAttributesForFrames_array[frameI] = frameDict;
		
		size_t dictSize = SizeOfVoxDict(frameDict);
		_frames_size += dictSize;
		
		framePtr += (ptrdiff_t)dictSize;
	}
}
@synthesize frames_size=_frames_size;

- (VoxDict)frameAttributesForFrame:(uint32_t)frameIndex
{
	NSParameterAssert(frameIndex >= 0 && frameIndex < _frames_count);
	return _frameAttributesForFrames_array[frameIndex];
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
	simd_float3x3 rotation_simd = SIMDMatrixFromVoxRotation(*rotation);
	return rotation_simd;
}


#pragma mark totalSize

- (size_t)totalSize {
	return kTransformNodeChunk_nodeID_size + self.nodeAttributes_size + kTransformNodeChunk_childNodeID_size + kTransformNodeChunk_reservedID_size + kTransformNodeChunk_layerID_size + kTransformNodeChunk_numFrames_size + self.frames_size;
}


#pragma mark debugDescription

- (NSString *)debugDescription
{
	NSString *indentationString = indentationStringOfLength(sDebugLogParseDepth);
	NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:400]; // capacity is a rough estimate, based on output from test files
	
	[outputString appendFormat:@"%@nodeID: %d\n", indentationString, self.nodeID];
	
	NSDictionary<NSString*,NSString*> *nodeAttributes = NSDictionaryFromVoxDict(self.nodeAttributes);
	[outputString appendFormat:@"%@nodeAttributes: %@\n", indentationString, [nodeAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
	[outputString appendFormat:@"%@nodeAttributesName: %@\n", indentationString, NSStringFromVoxString(self.nodeAttributeName)];
	[outputString appendFormat:@"%@nodeAttributesHidden: %@\n", indentationString, @(self.nodeAttributeHidden)];
	
	for (int frameI = 0; frameI < self.numFrames; ++frameI) {
		NSDictionary<NSString*,NSString*> *frameAttributes = NSDictionaryFromVoxDict([self frameAttributesForFrame:frameI]);
		[outputString appendFormat:@"%@frameAttributes[%d]: %@\n", indentationString, frameI, [frameAttributes.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
		simd_int3 translation = [self frameAttributeSIMDTranslationForFrame:frameI];
		[outputString appendFormat:@"%@frameAttributes[%d] SIMDTranslation: (x: %d, y: %d, z: %d)\n", indentationString, frameI, translation.x, translation.y, translation.z];
		simd_float3x3 rotation = [self frameAttributeSIMDRotationForFrame:frameI];
		[outputString appendFormat:@"%@frameAttributes[%d] SIMDRotation: (00: %f, 01: %f, 02: %f, 10: %f, 11: %f, 12: %f, 20: %f, 21: %f, 22: %f)\n", indentationString, frameI,
			rotation.columns[0][0], rotation.columns[0][1], rotation.columns[0][2],
			rotation.columns[1][0], rotation.columns[1][1], rotation.columns[1][2],
			rotation.columns[2][0], rotation.columns[2][1], rotation.columns[2][2]
		];
	}
	
	return [outputString autorelease];
}


@end
