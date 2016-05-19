//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <Foundation/Foundation.h>



#if !defined(FourCharDataArray)
	typedef uint8_t FourCharDataArray[4];
#endif


typedef union _ChunkIdent {
	FourCharDataArray const *array;
	uint8_t const *ptr;
	FourCharCode const *fourCharCode;
} ChunkIdent; // @todo: Rename ChunkIdDataPtr?

NSString *NSStringFromChunkIdent(ChunkIdent ident);
