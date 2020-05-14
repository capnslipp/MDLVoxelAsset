// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.


#import <Foundation/Foundation.h>

//! Project version number for MDLVoxelAsset.
FOUNDATION_EXPORT double MDLVoxelAssetVersionNumber;

//! Project version string for MDLVoxelAsset.
FOUNDATION_EXPORT const unsigned char MDLVoxelAssetVersionString[];



#import <ModelIO/ModelIO.h>
#import <MDLVoxelAsset/MagicaVoxelVoxData.h>

#if TARGET_OS_IPHONE
	@class UIColor;
	typedef UIColor Color;
#else
	@class NSColor;
	typedef NSColor Color;
#endif



#pragma clang assume_nonnull begin

typedef struct _MDLVoxelAsset_VoxelDimensions {
	uint32_t const x, y, z;
} MDLVoxelAsset_VoxelDimensions;

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
	/// FILL IN
	MDLVoxelAssetMeshGenerationModeMDLVoxelArrayCoarse,
	MDLVoxelAssetMeshGenerationModeMDLVoxelArraySmooth,
	/// Generates exterior quad-faces, greedily-combined.  Ported from Mikola Lysenko's Greedy Meshing method: https://0fps.net/2012/06/30/meshing-in-a-minecraft-game/
	MDLVoxelAssetMeshGenerationModeGreedyTri,
	/// Generates exterior quad-faces, greedily-combined.  Ported from Mikola Lysenko's Greedy Meshing method: https://0fps.net/2012/06/30/meshing-in-a-minecraft-game/
	MDLVoxelAssetMeshGenerationModeGreedyQuad,
};

FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionConvertZUpToYUp;

FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionGenerateAmbientOcclusion;

/// Specifies palette indices that'll be replaced with different indices (prior to mesh generation).
/// 	Value: A `NSDictionary<NSNumber*,NSNumber*>` where the keys are `uint8_t`-`NSNumber`s representing indices to be replaced, and the values are `uint8_t`-`NSNumber`s representing the value to replace each with.
/// 		And number provided as a replacement-value may not be listed as a key.  Providing a replacement value that is also provided as key(s) is unsupported behavior (and not checked for; replacement may be incomplete or may livelock).
FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionPaletteIndexReplacements;

/// Skips mesh generation for faces pointing in the specified direction
/// 	Value: `MDLVoxelAssetSkipMeshFaceDirections` enum, packed in an `NSNumber`
/// 	Default Value: `MDLVoxelAssetSkipMeshFaceDirectionsNone` (`0`)
FOUNDATION_EXPORT NSString *const kMDLVoxelAssetOptionSkipMeshFaceDirections;
typedef NS_OPTIONS(NSUInteger, MDLVoxelAssetSkipMeshFaceDirections) {
	MDLVoxelAssetSkipMeshFaceDirectionsNone = 0,
	
	MDLVoxelAssetSkipMeshFaceDirectionsXNeg = 0b000001,
	MDLVoxelAssetSkipMeshFaceDirectionsXPos = 0b000010,
	MDLVoxelAssetSkipMeshFaceDirectionsYNeg = 0b000100,
	MDLVoxelAssetSkipMeshFaceDirectionsYPos = 0b001000,
	MDLVoxelAssetSkipMeshFaceDirectionsZNeg = 0b010000,
	MDLVoxelAssetSkipMeshFaceDirectionsZPos = 0b100000,
};



@interface MDLVoxelAsset : MDLObjectContainer <NSCopying>

#pragma mark Creating an Asset

+ (BOOL)canImportFileExtension:(NSString *)extension;

/// @param options: A dictionary of MDLVoxelArray & MDLMesh initialization options.
- (instancetype)initWithURL:(NSURL *)URL options:(nullable NSDictionary<NSString*,id> *)options;
@property(nonatomic, readonly, retain) NSURL *URL;


#pragma mark Working with Asset Content

@property (nonatomic, assign, readonly) MDLAxisAlignedBoundingBox boundingBox;

@property (nonatomic, retain, readonly) MDLVoxelArray *voxelArray;
@property (nonatomic, assign, readonly) uint32_t voxelCount;
@property (nonatomic, assign, readonly) MDLVoxelAsset_VoxelDimensions voxelDimensions;

@property (nonatomic, retain, readonly) NSArray<NSArray<NSArray<NSNumber*>*>*> *voxelPaletteIndices;

@property (nonatomic, retain, readonly) NSArray<Color*> *paletteColors;

- (void)calculateShellLevels;

@property (nonatomic, retain, readonly) NSArray<MDLMesh*> *meshes;


#pragma mark Sub-MDLObject Access

- (MDLObject *)objectAtIndex:(NSUInteger)index;
- (MDLObject *)objectAtIndexedSubscript:(NSUInteger)index;

@property (nonatomic, readonly) NSUInteger count;


#pragma mark MDLObjectContainerComponent Overrides

- (void)addObject:(MDLObject*)object;
- (void)removeObject:(MDLObject*)object;

@end


#pragma clang assume_nonnull end
