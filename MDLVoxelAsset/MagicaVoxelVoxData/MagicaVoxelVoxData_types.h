// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <Foundation/Foundation.h>
#import <simd/matrix.h>



// MARK: VoxString

typedef struct _VoxString {
	int32_t size;
	int8_t const *array;
} VoxString;
static const VoxString kVoxString_invalidValue = (VoxString){ .size = 0, .array = NULL };

VoxString VoxStringAtPtr(void const *const stringPtr);

size_t SizeOfVoxString(const VoxString string);

NSString *NSStringFromVoxString(const VoxString string);



// MARK: VoxDict

typedef struct _VoxDict {
	int32_t count;
	void const *firstPairPtr;
} VoxDict;

VoxDict VoxDictAtPtr(void const *const dictPtr);

size_t SizeOfVoxDict(const VoxDict dict);

BOOL VoxDictGetValue(const VoxDict dict, const VoxString keyString, VoxString *outValueString);

NSDictionary<NSString*,NSString*> *NSDictionaryFromVoxDict(const VoxDict dict);



// MARK: VoxDictPair

typedef struct _VoxDictPair VoxDictPair;
typedef struct _VoxDictPair {
	VoxString key;
	VoxString value;
	/// The next memory location that a pair would be at— more accurately, the “after this pair's end pointer”.
	/// May point to invalid memory; you must reply on the `VoxDict`'s `count` to determine if there's another pair at this pointer or not.
	void const *nextPairPtr;
} VoxDictPair;

VoxDictPair VoxDictPairAtPtr(void const *const pairPtr);

size_t SizeOfVoxDictPair(const VoxDictPair pair);



// MARK: VoxRotation

typedef struct _VoxRotation {
	uint8_t nonZeroInRow1Index : 2;
	uint8_t nonZeroInRow2Index : 2;
	uint8_t signInRow1 : 1;
	uint8_t signInRow2 : 1;
	uint8_t signInRow3 : 1;
} VoxRotation;

simd_float3x3 SIMDMatrixFromVoxRotation(const VoxRotation rotation);
