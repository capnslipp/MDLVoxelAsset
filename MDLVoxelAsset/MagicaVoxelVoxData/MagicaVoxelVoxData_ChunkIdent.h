// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

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
