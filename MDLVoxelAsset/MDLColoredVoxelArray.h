// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <ModelIO/ModelIO.h>



NS_ASSUME_NONNULL_BEGIN


typedef vector_int4 MDLColoredVoxelIndex;


/// Alternate implementation of MDLVoxelArray-like functionality, but storing a 32-bit color for each voxel instead of shell level.
@interface MDLColoredVoxelArray : MDLObject


#pragma mark Creating a Voxel Array

- (instancetype)initWithAsset:(MDLAsset*)asset divisions:(int)divisions patchRadius:(float)patchRadius;

- (instancetype)initWithData:(NSData*)voxelData boundingBox:(MDLAxisAlignedBoundingBox)boundingBox voxelExtent:(float)voxelExtent;


#pragma mark Examining Voxels

@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic, readonly) MDLVoxelIndexExtent voxelIndexExtent;

- (BOOL)voxelExistsAtIndex:(MDLColoredVoxelIndex)index allowAnyX:(BOOL)allowAnyX allowAnyY:(BOOL)allowAnyY allowAnyZ:(BOOL)allowAnyZ;

- (nullable NSData *)voxelsWithinExtent:(MDLVoxelIndexExtent)extent;

- (nullable NSData *)voxelIndices;


#pragma mark Modifying Voxels

- (void)setVoxelAtIndex:(MDLColoredVoxelIndex)index;

- (void)setVoxelsForMesh:(nonnull MDLMesh*)mesh divisions:(int)divisions patchRadius:(float)patchRadius;


#pragma mark Performing Constructive Solid Geometry Operations

- (void)unionWithVoxels:(MDLVoxelArray*)voxels;

- (void)intersectWithVoxels:(MDLVoxelArray*)voxels;

- (void)differenceWithVoxels:(MDLVoxelArray*)voxels;


#pragma mark Relating Voxels to Scene Space

@property (nonatomic, readonly) MDLAxisAlignedBoundingBox boundingBox;

- (MDLColoredVoxelIndex)indexOfSpatialLocation:(vector_float3)location;

- (vector_float3)spatialLocationOfIndex:(MDLColoredVoxelIndex)index;

- (MDLAxisAlignedBoundingBox)voxelBoundingBoxAtIndex:(MDLColoredVoxelIndex)index;


@end


NS_ASSUME_NONNULL_END
