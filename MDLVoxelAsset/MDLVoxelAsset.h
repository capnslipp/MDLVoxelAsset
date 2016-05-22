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




@interface MDLVoxelAsset : MDLAsset

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, retain) MDLVoxelArray *voxelArray;

@property (nonatomic, retain) NSArray<NSArray<NSArray<NSNumber*>*>*> *voxelPaletteIndices;

@property (nonatomic, retain) NSArray<Color*> *paletteColors;

+ (BOOL)canImportFileExtension:(NSString *)extension;

@end
