//  MDLVoxelAsset.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <ModelIO/ModelIO.h>

@class UIColor;



@interface MDLVoxelAsset : MDLAsset

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, retain) MDLVoxelArray *voxelArray;

@property (nonatomic, retain) NSArray<NSValue*> *voxelPaletteIndices;

@property (nonatomic, retain) NSArray<UIColor*> *paletteColors;

+ (BOOL)canImportFileExtension:(NSString *)extension;

@end
