//  MDLVoxelAsset.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.


#import <Foundation/Foundation.h>

//! Project version number for MDLVoxelAsset.
FOUNDATION_EXPORT double MDLVoxelAssetVersionNumber;

//! Project version string for MDLVoxelAsset.
FOUNDATION_EXPORT const unsigned char MDLVoxelAssetVersionString[];



#import <ModelIO/ModelIO.h>
#import "MagicaVoxelVoxData.h"

#if TARGET_OS_IPHONE
	@class UIColor;
	typedef UIColor Color;
#else
	@class NSColor;
	typedef NSColor Color;
#endif



#pragma clang assume_nonnull begin

/// If true, runs `-calculateShellLevels` on initialization.
///		Value: Boolean NSNumber
///		Default Value: `false`
FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionCalculateShellLevels;

/// If true, keeps only the “at-surface” shell, discarding all interior (>= -1) shells.
///		Value: Boolean NSNumber
///		Default Value: `false`
///		Requires: `kMDLVoxelAssetOptionCalculateShellLevels` to be true
FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionSkipNonZeroShellMesh;

/// Determines the method used to generate the MDLMesh.
///		Value: `MDLVoxelAssetMeshGenerationMode` enum NSNumber
///		Default Value: `MDLVoxelAssetMeshGenerationModeSceneKit`
FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionMeshGenerationMode;
typedef NS_ENUM(NSUInteger, MDLVoxelAssetMeshGenerationMode) {
	/// Skips mesh generation.  `-objects` will be empty.
	MDLVoxelAssetMeshGenerationModeSkip,
	/// Generates using SceneKit SCNGeometry, assembling them into an `SCNNode` tree, combining them into fewer draw calls with `-flattenedClone`, then packaging that up in an `MDLObject`.
	///		Not the most efficient approach, but the most straight-forward & reliable, since it relies on SceneKit & ModelIO to take care of all the vertex/normal/material/etc. buffer allocation & arrangement.
    MDLVoxelAssetMeshGenerationModeSceneKit,
};

FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionConvertZUpToYUp;

FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionGenerateAmbientOcclusion;


@interface MDLVoxelAsset : MDLObjectContainer <NSCopying>

#pragma mark Creating an Asset

+ (BOOL)canImportFileExtension:(NSString *)extension;

/// @param options: A dictionary of MDLVoxelArray & MDLMesh initialization options.
- (instancetype)initWithURL:(NSURL *)URL options:(nullable NSDictionary<NSString*,id> *)options;
@property(nonatomic, readonly, retain) NSURL *URL;


#pragma mark Working with Asset Content

@property (nonatomic, assign, readonly) MDLAxisAlignedBoundingBox boundingBox;

@property (nonatomic, retain, readonly) MDLVoxelArray *voxelArray;
@property (nonatomic, assign, readonly) NSUInteger voxelCount;

@property (nonatomic, retain, readonly) NSArray<NSArray<NSArray<NSNumber*>*>*> *voxelPaletteIndices;

@property (nonatomic, retain, readonly) NSArray<Color*> *paletteColors;

- (void)calculateShellLevels;


#pragma mark Sub-MDLObject Access

- (MDLObject *)objectAtIndex:(NSUInteger)index;
- (nullable MDLObject *)objectAtIndexedSubscript:(NSUInteger)index;

@property (nonatomic, readonly) NSUInteger count;


#pragma mark MDLObjectContainerComponent Overrides

- (void)addObject:(MDLObject*)object;
- (void)removeObject:(MDLObject*)object;

@end


#pragma clang assume_nonnull end
