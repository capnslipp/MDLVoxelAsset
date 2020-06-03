// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_SceneGraphTypes.h"



#pragma mark - MagicaVoxelVoxData_Node

@implementation MagicaVoxelVoxData_Node

- (id)copyWithZone:(NSZone *)zone {
	return NSAllocateObject(self.class, 0, zone);
}

@end



#pragma mark - MagicaVoxelVoxData_TransformNode

@implementation MagicaVoxelVoxData_TransformNode

- (id)copyWithZone:(NSZone *)zone
{
	MagicaVoxelVoxData_TransformNode *copy = [super copyWithZone:zone];
	copy->_name = [_name copy];
	copy->_hidden = _hidden;
	copy->_childNode = [_childNode copy];
	copy->_frames = [[NSArray alloc] initWithArray:_frames copyItems:YES];
	return copy;
}

- (void)dealloc
{
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wnonnull"
	self.name = nil;
	self.childNode = nil;
	self.frames = nil;
	#pragma clang diagnostic pop
	[super dealloc];
}

@end



#pragma mark - MagicaVoxelVoxData_GroupNode

@implementation MagicaVoxelVoxData_GroupNode

- (id)copyWithZone:(NSZone *)zone
{
	MagicaVoxelVoxData_GroupNode *copy = [super copyWithZone:zone];
	copy->_childrenNodes = [[NSArray alloc] initWithArray:_childrenNodes copyItems:YES];
	return copy;
}

- (void)dealloc
{
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wnonnull"
	self.childrenNodes = nil;
	#pragma clang diagnostic pop
	[super dealloc];
}

@end



#pragma mark - MagicaVoxelVoxData_ShapeNode

@implementation MagicaVoxelVoxData_ShapeNode

- (id)copyWithZone:(NSZone *)zone
{
	MagicaVoxelVoxData_ShapeNode *copy = [super copyWithZone:zone];
	copy->_models = [[NSArray alloc] initWithArray:_models copyItems:YES];
	return copy;
}

- (void)dealloc
{
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wnonnull"
	self.models = nil;
	#pragma clang diagnostic pop
	[super dealloc];
}

@end



#pragma mark - MagicaVoxelVoxData_Frame

@implementation MagicaVoxelVoxData_Frame

- (id)copyWithZone:(NSZone *)zone {
	MagicaVoxelVoxData_Frame *copy = NSAllocateObject(self.class, 0, zone);
	copy->_translation = _translation;
	copy->_rotation = _rotation;
	return copy;
}

@end



#pragma mark - MagicaVoxelVoxData_Model

@implementation MagicaVoxelVoxData_Model

- (id)copyWithZone:(NSZone *)zone {
	MagicaVoxelVoxData_Model *copy = NSAllocateObject(self.class, 0, zone);
	copy->_modelID = _modelID;
	return copy;
}

@end
