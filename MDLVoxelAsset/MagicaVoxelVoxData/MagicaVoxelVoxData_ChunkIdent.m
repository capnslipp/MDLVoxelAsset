// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#include "MagicaVoxelVoxData_ChunkIdent.h"



NSString *NSStringFromChunkIdent(ChunkIdent ident) {
	return [NSString stringWithFormat:@"%c%c%c%c", (*ident.array)[0], (*ident.array)[1], (*ident.array)[2], (*ident.array)[3]];
}
