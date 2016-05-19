//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>




typedef uint32_t XYZSizeDataArray[3];


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface SizeChunkContentsHandle : NSObject  {
}

@property (nonatomic, assign, nullable) XYZSizeDataArray const *xyzSize;

@end
