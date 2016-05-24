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


@interface MDLVoxelAsset : MDLObjectContainer <NSCopying>

- (MDLAsset *)test;


#pragma mark Creating an Asset

+ (BOOL)canImportFileExtension:(NSString *)extension;

- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString*,id> *)options;
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


#pragma mark NSFastEnumeration Adherance

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;

@end


#pragma clang assume_nonnull end
