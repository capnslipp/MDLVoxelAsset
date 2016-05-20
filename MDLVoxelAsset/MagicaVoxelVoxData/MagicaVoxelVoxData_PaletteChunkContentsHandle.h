//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>


#pragma mark Constants

typedef uint8_t RGBAValuesDataArray[4];
typedef struct _PaletteChunkContentsHandle_Color {
	RGBAValuesDataArray const rgbaValues;
} PaletteChunkContentsHandle_Color;

static const ptrdiff_t kPaletteChunkColors_Offset = 0;
static const size_t kPaletteChunk_ColorSize = sizeof(RGBAValuesDataArray);
static const size_t kPaletteChunk_PaletteSize = kPaletteChunk_ColorSize * 256;



#pragma clang assume_nonnull begin


/// A fairly dumb “struct-ish” metadata & data-pointer store, as a Obj-C object for easier memory management & polymorphism.
@interface PaletteChunkContentsHandle : NSObject

- (instancetype)initWithData:(NSData *)data offset:(ptrdiff_t)offset;


// Auto-populated info properties:

@property (nonatomic, assign, readonly) ptrdiff_t colors_offset;
@property (nonatomic, assign, readonly) PaletteChunkContentsHandle_Color *colors_array;

/// The total size of the contents.
- (size_t)totalSize;

@end


#pragma clang assume_nonnull end
