// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <Foundation/Foundation.h>



#import <ModelIO/ModelIO.h>
#import <MDLVoxelAsset/MDLVoxelAsset.h>
#import <MDLVoxelAsset/MDLColoredVoxelArray.h>
#import <MDLVoxelAsset/MagicaVoxelVoxData.h>

#if TARGET_OS_IPHONE
	@class UIColor;
	typedef UIColor Color;
#else
	@class NSColor;
	typedef NSColor Color;
#endif



#pragma clang assume_nonnull begin


typedef NSDictionary<NSNumber*,NSNumber*> PaletteIndexToPaletteIndexDictionary;

typedef struct _OptionsValues {
	BOOL calculateShellLevels : 1;
	BOOL skipNonZeroShellMesh : 1;
	BOOL meshGenerationFlattening : 1;
	BOOL convertZUpToYUp : 1;
	BOOL generateAmbientOcclusion : 1;
	
	MDLVoxelAssetMeshGenerationMode meshGenerationMode;
	id _Nullable voxelMesh;
	PaletteIndexToPaletteIndexDictionary *_Nullable paletteIndexReplacements;
	MDLVoxelAssetSkipMeshFaceDirections skipMeshFaceDirections;
} OptionsValues;



@interface MDLVoxelAssetModel : NSObject


/// @param options: A dictionary of MDLVoxelArray & MDLMesh initialization options.
- (instancetype)initWithMVVoxData:(MagicaVoxelVoxData *)mvvoxData modelID:(uint32_t)modelID optionsValues:(const OptionsValues)optionsValues;

- (instancetype)initWithSCNScene:(SCNScene *)scnScene voxelizationParams:(nullable NSDictionary<NSString*,id> *)voxelizationParams optionsValues:(const OptionsValues)optionsValues dimensions:(MDLVoxelAsset_VoxelDimensions)dimensions palette:(NSArray<Color*> *)paletteColors;

@property (nonatomic, assign, readonly) uint32_t modelID;

@property (nonatomic, assign, readonly) MDLAxisAlignedBoundingBox boundingBox;

@property (nonatomic, retain, readonly) MDLColoredVoxelArray *voxelArray;
@property (nonatomic, assign, readonly) uint32_t voxelCount;
@property (nonatomic, assign, readonly) MDLVoxelAsset_VoxelDimensions voxelDimensions;

@property (nonatomic, retain, readonly) NSArray<NSArray<NSArray<NSNumber*>*>*> *voxelPaletteIndices;

- (void)calculateShellLevels;

@property (nonatomic, retain, readonly) NSArray<MDLMesh*> *meshes;


@end


#pragma clang assume_nonnull end
