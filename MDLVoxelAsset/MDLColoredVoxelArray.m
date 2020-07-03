//
//  MDLColoredVoxelArray.m
//  MDLVoxelAsset
//
//  Created by Cap'n Slipp on 7/2/20.
//  Copyright © 2020 Cap'n Slipp. All rights reserved.
//

#import "MDLColoredVoxelArray.h"



@interface MDLColoredVoxelArray () {
	/// “Hijacked” voxel array, with the last `int` component in each `MDLVoxelIndex` used for color (`MDLColoredVoxelIndex`) instead of shell level.
	MDLVoxelArray *_voxelArray;
	
	/// The size of a single voxel in world coordinate space (uniform size in all axes).
	float _voxelExtent;
}

- (void)setVoxelsForAsset:(nonnull MDLAsset*)mesh divisions:(int)divisions patchRadius:(float)patchRadius;

@end



@implementation MDLColoredVoxelArray


#pragma mark Creating a Voxel Array

- (instancetype)initWithAsset:(MDLAsset*)asset divisions:(int)divisions patchRadius:(float)patchRadius
{
	self = [super init];
	if (self == nil)
		return nil;
	
	[self setVoxelsForAsset:asset divisions:divisions patchRadius:patchRadius];
	
	return self;
}

- (instancetype)initWithData:(NSData*)voxelData boundingBox:(MDLAxisAlignedBoundingBox)boundingBox voxelExtent:(float)voxelExtent
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_voxelExtent = voxelExtent;
	_voxelArray = [[MDLVoxelArray alloc] initWithData:voxelData boundingBox:boundingBox voxelExtent:voxelExtent];
	
	return self;
}


#pragma mark Examining Voxels

- (NSUInteger)count {
	return _voxelArray.count;
}

- (MDLVoxelIndexExtent)voxelIndexExtent {
	return _voxelArray.voxelIndexExtent;
}

- (BOOL)voxelExistsAtIndex:(MDLColoredVoxelIndex)index allowAnyX:(BOOL)allowAnyX allowAnyY:(BOOL)allowAnyY allowAnyZ:(BOOL)allowAnyZ {
	return [_voxelArray voxelExistsAtIndex:index allowAnyX:allowAnyX allowAnyY:allowAnyY allowAnyZ:allowAnyZ allowAnyShell:YES];
}

- (nullable NSData *)voxelsWithinExtent:(MDLVoxelIndexExtent)extent {
	return [_voxelArray voxelsWithinExtent:extent];
}

- (nullable NSData *)voxelIndices {
	return [_voxelArray voxelIndices];
}


#pragma mark Modifying Voxels

- (void)setVoxelAtIndex:(MDLColoredVoxelIndex)index {
	[_voxelArray setVoxelAtIndex:index];
}

- (void)setVoxelsForAsset:(nonnull MDLAsset*)asset divisions:(int)divisions patchRadius:(float)patchRadius
{
}

/// Read as 3 individual floats into a new `simd_float3`— just casting to `simd_float3` could cause a bad access, since a float3 is actually a `simd_float4`.
simd_float3 readSIMDFloat3(void *address) {
	return simd_make_float3(
		*(float *)&address[sizeof(float) * 0],
		*(float *)&address[sizeof(float) * 1],
		*(float *)&address[sizeof(float) * 2]
	);
}

- (void)setVoxelsForMesh:(nonnull MDLMesh*)mesh divisions:(int)divisions patchRadius:(float)patchRadius
{
	[_voxelArray release];
	
	NSParameterAssert(divisions > 0);
	
	MDLAxisAlignedBoundingBox meshBoundingBox = mesh.boundingBox;
	simd_float3 meshBoundingBoxSize = meshBoundingBox.maxBounds - meshBoundingBox.minBounds;
	
	_voxelExtent = meshBoundingBoxSize.y / (divisions + 1);
	
	MDLVoxelIndexExtent voxelIndexExtent = (MDLVoxelIndexExtent){
		.minimumExtent = simd_make_int4(0, 0, 0, 0),
		.maximumExtent = simd_make_int4(
			(int)ceil(meshBoundingBoxSize.x / _voxelExtent),
			(int)ceil(meshBoundingBoxSize.y / _voxelExtent),
			(int)ceil(meshBoundingBoxSize.z / _voxelExtent),
			0
		)
	};
	simd_int4 voxelIndexExtentSize = voxelIndexExtent.maximumExtent - voxelIndexExtent.minimumExtent + simd_make_int4(1, 1, 1, 0);
	MDLAxisAlignedBoundingBox boundingBox = (MDLAxisAlignedBoundingBox){
		.minBounds = meshBoundingBox.minBounds,
		.maxBounds = meshBoundingBox.minBounds + ((simd_float3)(simd_make_int3(voxelIndexExtentSize)) * _voxelExtent)
	};
	
	const MDLColoredVoxelIndex kInvalidMDLColoredVoxelIndex = (MDLColoredVoxelIndex){ -1, -1, -1, 0 };
	
	int voxelIndexesCount = voxelIndexExtentSize.x * voxelIndexExtentSize.y * voxelIndexExtentSize.z;
	MDLColoredVoxelIndex *voxelIndexes = calloc(voxelIndexesCount, sizeof(MDLColoredVoxelIndex));
	for (int voxelIndexI = voxelIndexesCount - 1; voxelIndexI >= 0; --voxelIndexI) {
		voxelIndexes[voxelIndexI] = kInvalidMDLColoredVoxelIndex;
	}
	
	MDLColoredVoxelIndex (^getVoxelIndex)(int, int, int) = ^(int x, int y, int z) {
		return voxelIndexes[(x * voxelIndexExtentSize.y * voxelIndexExtentSize.z) + (y * voxelIndexExtentSize.z) + z];
	};
	void (^setVoxelIndex)(MDLColoredVoxelIndex) = ^(MDLColoredVoxelIndex voxelIndex) {
		int x = voxelIndex.x, y = voxelIndex.y, z = voxelIndex.z;
		voxelIndexes[(x * voxelIndexExtentSize.y * voxelIndexExtentSize.z) + (y * voxelIndexExtentSize.z) + z] = voxelIndex;
	};
	
	NSMutableData *voxelIndexData = [[NSMutableData alloc] initWithCapacity:(getpagesize() * 4)];
	
	NSArray<id<MDLMeshBuffer>> *meshVertexBuffers = mesh.vertexBuffers;
	NSArray<MDLSubmesh *> *meshSubmeshes = mesh.submeshes;
	
	for (MDLSubmesh *meshSubmesh in meshSubmeshes) {
		switch (meshSubmesh.geometryType) {
			case MDLGeometryTypeTriangles: {
					NSParameterAssert(meshSubmesh.indexType == MDLIndexBitDepthUInt8);
					
					uint32_t *indexBufferBytes = [meshSubmesh.indexBuffer map].bytes;
					
					NSUInteger indexCount = meshSubmesh.indexCount;
					for (NSUInteger indexI = 0; indexI < indexCount - 2; indexI += 3) {
						uint8_t triIndexA = indexBufferBytes[indexI + 0];
						uint8_t triIndexB = indexBufferBytes[indexI + 1];
						uint8_t triIndexC = indexBufferBytes[indexI + 2];
						
						MDLVertexAttributeData *vertexesPositionData = [mesh vertexAttributeDataForAttributeNamed:MDLVertexAttributePosition];
						NSParameterAssert(vertexesPositionData.format == MDLVertexFormatFloat3);
						void *vertexesPositionBytes = vertexesPositionData.dataStart;
						ptrdiff_t vertexesPositionBytesStride = vertexesPositionData.stride;
						
						MDLVertexAttributeData *vertexesColorData = [mesh vertexAttributeDataForAttributeNamed:MDLVertexAttributeColor];
						MDLVertexAttributeData *vertexesTextureCoordinateData = [mesh vertexAttributeDataForAttributeNamed:MDLVertexAttributeTextureCoordinate];
						
						
						simd_float3 triPositionA = readSIMDFloat3(&vertexesPositionBytes[triIndexA * vertexesPositionBytesStride]);
						simd_float3 triPositionB = readSIMDFloat3(&vertexesPositionBytes[triIndexB * vertexesPositionBytesStride]);
						simd_float3 triPositionC = readSIMDFloat3(&vertexesPositionBytes[triIndexC * vertexesPositionBytesStride]);
						
						MDLColoredVoxelIndex voxelIndex = (MDLColoredVoxelIndex)simd_make_int4(0, 0, 0, 0);
						setVoxelIndex(voxelIndex);
					}
				}
				break;
			
			case MDLGeometryTypeTriangleStrips:
				break;
			
			case MDLGeometryTypeQuads:
				break;
			
			default:
				NSAssert(false, @"Unsupported MDLGeometryType %ld", (long)meshSubmesh.geometryType);
		}
	}
	
	NSMutableData *voxelIndexesData = [NSMutableData new];
	for (int voxelIndexI = voxelIndexesCount - 1; voxelIndexI >= 0; --voxelIndexI) {
		MDLColoredVoxelIndex voxelIndex = voxelIndexes[voxelIndexI];
		if (!simd_equal(voxelIndex, kInvalidMDLColoredVoxelIndex))
			[voxelIndexesData appendBytes:&voxelIndex length:sizeof(MDLColoredVoxelIndex)];
	}
	
	
	_voxelArray = [[MDLVoxelArray alloc] initWithData:voxelIndexesData boundingBox:boundingBox voxelExtent:_voxelExtent];
	[voxelIndexesData release];
}


#pragma mark Performing Constructive Solid Geometry Operations

- (void)unionWithVoxels:(MDLVoxelArray*)otherVoxelArray
{
	NSMutableData *voxelIndices = [[_voxelArray voxelIndices] mutableCopy];
	
	MDLAxisAlignedBoundingBox boundingBox = (MDLAxisAlignedBoundingBox){
		.minBounds = simd_min(_voxelArray.boundingBox.minBounds, otherVoxelArray.boundingBox.minBounds),
		.maxBounds = simd_max(_voxelArray.boundingBox.maxBounds, otherVoxelArray.boundingBox.maxBounds)
	};
	
	// TODO: implement union with `otherVoxelArray`
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:voxelIndices boundingBox:boundingBox voxelExtent:_voxelExtent];
}

- (void)intersectWithVoxels:(MDLVoxelArray*)otherVoxelArray
{
	NSMutableData *voxelIndices = [[_voxelArray voxelIndices] mutableCopy];
	
	MDLAxisAlignedBoundingBox boundingBox = (MDLAxisAlignedBoundingBox){
		.minBounds = simd_max(_voxelArray.boundingBox.minBounds, otherVoxelArray.boundingBox.minBounds),
		.maxBounds = simd_min(_voxelArray.boundingBox.maxBounds, otherVoxelArray.boundingBox.maxBounds)
	};
	
	// TODO: implement intersect with `otherVoxelArray`
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:voxelIndices boundingBox:boundingBox voxelExtent:_voxelExtent];
}

- (void)differenceWithVoxels:(MDLVoxelArray*)otherVoxelArray
{
	NSMutableData *voxelIndices = [[_voxelArray voxelIndices] mutableCopy];
	
	MDLAxisAlignedBoundingBox boundingBox = _voxelArray.boundingBox; // TODO: calculate based on the resulting voxels
	
	// TODO: implement difference with `otherVoxelArray`
	
	[_voxelArray release];
	_voxelArray = [[MDLVoxelArray alloc] initWithData:voxelIndices boundingBox:boundingBox voxelExtent:_voxelExtent];
}


#pragma mark Relating Voxels to Scene Space

- (MDLAxisAlignedBoundingBox)boundingBox {
	return _voxelArray.boundingBox;
}

- (MDLColoredVoxelIndex)indexOfSpatialLocation:(vector_float3)location {
	return [_voxelArray indexOfSpatialLocation:location];
}

- (vector_float3)spatialLocationOfIndex:(MDLColoredVoxelIndex)index {
	return [_voxelArray spatialLocationOfIndex:index];
}

- (MDLAxisAlignedBoundingBox)voxelBoundingBoxAtIndex:(MDLColoredVoxelIndex)index {
	return [_voxelArray voxelBoundingBoxAtIndex:index];
}


@end
