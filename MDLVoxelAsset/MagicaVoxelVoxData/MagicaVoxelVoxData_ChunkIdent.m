//  MagicaVoxelVoxData.h
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 5/19/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#include "MagicaVoxelVoxData_ChunkIdent.h"



NSString *NSStringFromChunkIdent(ChunkIdent ident) {
	return [NSString stringWithFormat:@"%c%c%c%c", (*ident.array)[0], (*ident.array)[1], (*ident.array)[2], (*ident.array)[3]];
}