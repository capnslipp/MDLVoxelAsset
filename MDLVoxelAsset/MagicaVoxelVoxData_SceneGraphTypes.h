// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <Foundation/Foundation.h>
#import <simd/simd.h>



@class MagicaVoxelVoxData_Node;
@class MagicaVoxelVoxData_TransformNode;
@class MagicaVoxelVoxData_Frame;
@class MagicaVoxelVoxData_GroupNode;
@class MagicaVoxelVoxData_ShapeNode;
@class MagicaVoxelVoxData_Model;



NS_ASSUME_NONNULL_BEGIN



@interface MagicaVoxelVoxData_Node : NSObject <NSCopying>
@end



@interface MagicaVoxelVoxData_TransformNode : MagicaVoxelVoxData_Node

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@property (nonatomic, retain) MagicaVoxelVoxData_Node *childNode;
@property (nonatomic, retain) NSArray<MagicaVoxelVoxData_Frame*> *frames;

@end



@interface MagicaVoxelVoxData_GroupNode : MagicaVoxelVoxData_Node

@property (nonatomic, retain) NSArray<MagicaVoxelVoxData_TransformNode*> *childrenNodes;

@end



@interface MagicaVoxelVoxData_ShapeNode : MagicaVoxelVoxData_Node

@property (nonatomic, retain) NSArray<MagicaVoxelVoxData_Model*> *models;

@end



@interface MagicaVoxelVoxData_Frame : NSObject <NSCopying>

@property (nonatomic, assign) simd_int3 translation;
@property (nonatomic, assign) simd_float3x3 rotation;

@end



@interface MagicaVoxelVoxData_Model : NSObject <NSCopying>

@property (nonatomic, assign) int32_t modelID;

@end



NS_ASSUME_NONNULL_END
