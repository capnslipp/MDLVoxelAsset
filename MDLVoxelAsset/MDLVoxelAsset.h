//  MDLVoxelAsset.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/20/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <ModelIO/ModelIO.h>



@interface MDLVoxelAsset : MDLAsset

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, retain) MDLVoxelArray *voxelArray;

+ (BOOL)canImportFileExtension:(NSString *)extension;

@end
