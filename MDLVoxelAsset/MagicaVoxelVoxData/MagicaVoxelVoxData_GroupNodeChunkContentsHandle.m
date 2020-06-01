// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_GroupNodeChunkContentsHandle.h"

#import "MagicaVoxelVoxData_types.h"



@implementation GroupNodeChunkContentsHandle {
	NSData *_data;
	ptrdiff_t _baseOffset;
	
	VoxDict _nodeAttributes;
	size_t _nodeAttributes_size;
}


+ (void)initialize
{
	assert(sizeof(GroupNodeChunkContentsHandle_Child) == sizeof(int32_t));
}


- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_data = [data retain];
	_baseOffset = offset;
	
	NSParameterAssert(_data.length >= _baseOffset + kGroupNodeChunk_nodeID_offset + kGroupNodeChunk_nodeID_size);
	
	NSParameterAssert(_data.length >= _baseOffset + kGroupNodeChunk_nodeAttributes_offset + self.nodeAttributes_size);
	ptrdiff_t afterNodeAttributesOffset = _baseOffset + kGroupNodeChunk_nodeAttributes_offset + self.nodeAttributes_size;
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kGroupNodeChunk_numChildNodes_afterNodeAttributesOffset + kGroupNodeChunk_numChildNodes_size);
	
	NSParameterAssert(_data.length >= afterNodeAttributesOffset + kGroupNodeChunk_childNodes_afterNodeAttributesOffset + self.childNodes_size);
	
	NSParameterAssert(_data.length >= _baseOffset + self.totalSize); // redundant; sanity check
	
	_nodeAttributes = VoxDictAtPtr(self.nodeAttributes_ptr);
	_nodeAttributes_size = SizeOfVoxDict(_nodeAttributes);
	
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
	return _baseOffset + kGroupNodeChunk_nodeID_offset;
}
- (int32_t const *)nodeID_ptr {
	return (int32_t const *)&_data.bytes[self.nodeID_offset];
}
- (int32_t)nodeID {
	return *self.nodeID_ptr;
}


#pragma mark nodeAttributes

- (ptrdiff_t)nodeAttributes_offset {
	return _baseOffset + kGroupNodeChunk_nodeAttributes_offset;
}
- (void const *)nodeAttributes_ptr {
	return (void const *)&_data.bytes[self.nodeAttributes_offset];
}
@synthesize nodeAttributes_size=_nodeAttributes_size, nodeAttributes=_nodeAttributes;


#pragma mark numChildNodes

- (ptrdiff_t)numChildNodes_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kGroupNodeChunk_numChildNodes_afterNodeAttributesOffset;
}
- (int32_t const *)numChildNodes_ptr {
	return (int32_t const *)&_data.bytes[self.numChildNodes_offset];
}
- (int32_t)numChildNodes {
	return *self.numChildNodes_ptr;
}


#pragma mark childNodes

- (ptrdiff_t)childNodes_offset {
	return (self.nodeAttributes_offset + self.nodeAttributes_size) + kGroupNodeChunk_childNodes_afterNodeAttributesOffset;
}
- (int32_t)childNodes_count {
	return self.numChildNodes; // just a method alias
}
- (size_t)childNodes_size {
	return sizeof(GroupNodeChunkContentsHandle_Child) * self.childNodes_count;
}
- (GroupNodeChunkContentsHandle_Child const *)childNodes {
	return (GroupNodeChunkContentsHandle_Child const *)&_data.bytes[self.childNodes_offset];
}


#pragma mark totalSize

- (size_t)totalSize {
	return kGroupNodeChunk_nodeID_size + self.nodeAttributes_size + kGroupNodeChunk_numChildNodes_size + self.childNodes_size;
}


@end
