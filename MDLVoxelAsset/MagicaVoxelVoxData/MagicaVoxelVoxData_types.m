// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_types.h"



// MARK: VoxString

VoxString VoxStringAtPtr(void const *const stringPtr) {
	int32_t size = *(int32_t *)stringPtr;
	return (VoxString){
		.size = size,
		.array = &stringPtr[(ptrdiff_t)sizeof(int32_t)]
	};
}

size_t SizeOfVoxString(const VoxString string) {
	return sizeof(int32_t) + string.size;
}

NSString *NSStringFromVoxString(const VoxString string) {
	return [[[NSString alloc] initWithBytesNoCopy: (void *)string.array
		length: string.size
		encoding: NSASCIIStringEncoding
		freeWhenDone: NO
	] autorelease];
}



// MARK: VoxDict

VoxDict VoxDictAtPtr(void const *const dictPtr) {
	int32_t count = *(int32_t *)dictPtr;
	return (VoxDict){
		.count = count,
		.firstPairPtr = &dictPtr[(ptrdiff_t)sizeof(count)]
	};
}

size_t SizeOfVoxDict(const VoxDict dict)
{
	int32_t count = dict.count;
	size_t size = sizeof(int32_t);
	VoxDictPair pair;
	void const *pairPtr = dict.firstPairPtr;
	for (int pairI = 0; pairI < count; ++pairI) {
		pair = VoxDictPairAtPtr(pairPtr);
		size += SizeOfVoxDictPair(pair);
		pairPtr = pair.nextPairPtr;
	}
	return size;
}

BOOL VoxDictGetValue(const VoxDict dict, const VoxString keyString, VoxString *outValueString)
{
	int32_t count = dict.count;
	VoxDictPair pair;
	void const *pairPtr = dict.firstPairPtr;
	for (int pairI = 0; pairI < count; ++pairI) {
		pair = VoxDictPairAtPtr(pairPtr);
		if (pair.key.size == keyString.size) {
			if (memcmp(pair.key.array, keyString.array, keyString.size) == 0) {
				*outValueString = pair.value;
				return YES;
			}
		}
		
		pairPtr = pair.nextPairPtr;
	}
	
	outValueString = NULL;
	return NO;
}

NSDictionary<NSString*,NSString*> *NSDictionaryFromVoxDict(const VoxDict dict)
{
	int32_t count = dict.count;
	NSMutableDictionary<NSString*,NSString*> *nsDictionary = [[NSMutableDictionary alloc] initWithCapacity:count];
	
	VoxDictPair pair;
	void const *pairPtr = dict.firstPairPtr;
	for (int pairI = 0; pairI < count; ++pairI) {
		pair = VoxDictPairAtPtr(pairPtr);
		nsDictionary[NSStringFromVoxString(pair.key)] = NSStringFromVoxString(pair.value);
		pairPtr = pair.nextPairPtr;
	}
	
	return [nsDictionary autorelease];
}



// MARK: VoxDictPair

VoxDictPair VoxDictPairAtPtr(void const *const pairPtr)
{
	VoxString key = VoxStringAtPtr(&pairPtr[0]);
	size_t keySize = SizeOfVoxString(key);
	VoxString value = VoxStringAtPtr(&pairPtr[(ptrdiff_t)keySize]);
	size_t valueSize = SizeOfVoxString(value);
	
	return (VoxDictPair){
		.key = key,
		.value = value,
		.nextPairPtr = &pairPtr[(ptrdiff_t)(keySize + valueSize)]
	};
}

size_t SizeOfVoxDictPair(const VoxDictPair pair)
{
	size_t keySize = SizeOfVoxString(pair.key);
	size_t valueSize = SizeOfVoxString(pair.value);
	return keySize + valueSize;
}



// MARK: VoxRotation

simd_float3x3 SIMDMatrixDFromVoxRotation(const VoxRotation rotation)
{
	simd_float3 matrixRow1 = { 0 }, matrixRow2 = { 0 }, matrixRow3 = { 0 };
	
	NSCParameterAssert(rotation.nonZeroInRow1Index >= 0 && rotation.nonZeroInRow1Index <= 2);
	NSCParameterAssert(rotation.nonZeroInRow2Index >= 0 && rotation.nonZeroInRow2Index <= 2);
	NSCParameterAssert(rotation.nonZeroInRow1Index != rotation.nonZeroInRow2Index);
	
	matrixRow1[rotation.nonZeroInRow1Index] = rotation.signInRow1 ? -1.0 : +1.0;
	matrixRow2[rotation.nonZeroInRow2Index] = rotation.signInRow2 ? -1.0 : +1.0;
	uint8_t nonZeroInRow3Index = 3 - (rotation.nonZeroInRow1Index + rotation.nonZeroInRow2Index);
	NSCParameterAssert(rotation.nonZeroInRow2Index >= 0 && rotation.nonZeroInRow2Index <= 2); // TODO: remove me; just a math sanity check
	matrixRow3[nonZeroInRow3Index] = rotation.signInRow3 ? -1.0 : +1.0;
	
	simd_float3x3 matrix = simd_matrix_from_rows(matrixRow1, matrixRow2, matrixRow3);
	return matrix;
}
