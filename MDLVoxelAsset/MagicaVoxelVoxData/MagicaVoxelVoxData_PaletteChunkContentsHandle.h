//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>



typedef uint8_t RGBAValuesDataArray[4];
typedef struct _PaletteChunkContentsHandle_Color {
	RGBAValuesDataArray const rgbaValues;
} PaletteChunkContentsHandle_Color;


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface PaletteChunkContentsHandle : NSObject {
}

@property (nonatomic, assign, nullable) PaletteChunkContentsHandle_Color *colors_array;

@end
