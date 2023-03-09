// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <Foundation/Foundation.h>

//! Project version number for MDLVoxelAsset.
FOUNDATION_EXPORT double MDLVoxelAssetVersionNumber;

//! Project version string for MDLVoxelAsset.
FOUNDATION_EXPORT const unsigned char MDLVoxelAssetVersionString[];



#import <ModelIO/ModelIO.h>
#import <MDLVoxelAsset/MDLVoxelAsset_DataTypes.h>
#import <MDLVoxelAsset/MDLVoxelAssetModel.h>
#import <MDLVoxelAsset/MagicaVoxelVoxData.h>



#pragma clang assume_nonnull begin


@interface MDLVoxelAsset : MDLObjectContainer <NSCopying>

#pragma mark Creating an Asset

+ (BOOL)canImportFileExtension:(NSString *)extension;

/// @param options: A dictionary of MDLVoxelArray & MDLMesh initialization options.
- (instancetype)initWithURL:(NSURL *)URL options:(nullable NSDictionary<NSString*,id> *)options;
@property(nonatomic, readonly, retain) NSURL *URL;


#pragma mark Working with Asset Content

@property (nonatomic, assign, readonly) MDLAxisAlignedBoundingBox boundingBox;

@property (nonatomic, retain, readonly) NSArray<Color*> *paletteColors;

- (void)calculateShellLevels;

@property (nonatomic, retain, readonly) NSArray<MDLMesh*> *meshes;

@property (nonatomic, retain, readonly) NSArray<MDLVoxelAssetModel*> *models;


#pragma mark Sub-MDLObject Access

- (MDLObject *)objectAtIndex:(NSUInteger)index;
- (MDLObject *)objectAtIndexedSubscript:(NSUInteger)index;

@property (nonatomic, readonly) NSUInteger count;


#pragma mark MDLObjectContainerComponent Overrides

- (void)addObject:(MDLObject*)object;
- (void)removeObject:(MDLObject*)object;

@end


#pragma clang assume_nonnull end
