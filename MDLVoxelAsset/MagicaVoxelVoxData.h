// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import <Foundation/Foundation.h>



#pragma mark Constants

typedef struct _MagicaVoxelVoxData_XYZDimensions {
	uint32_t const x, y, z;
} MagicaVoxelVoxData_XYZDimensions;

typedef struct _MagicaVoxelVoxData_PaletteColor {
	uint8_t const r, g, b, a;
} MagicaVoxelVoxData_PaletteColor;

typedef struct _MagicaVoxelVoxData_Voxel {
	uint8_t const x, y, z;
	uint8_t const colorIndex;
} MagicaVoxelVoxData_Voxel;



#pragma clang assume_nonnull begin


@interface MagicaVoxelVoxData : NSObject <NSCopying, NSCopying>

/// Shouldn't be necessary in normal usage, since `MagicaVoxelVoxData` implements `NSData`s API fully.  Present as a fail-safe.
@property (nonatomic, retain, readonly) NSData *nsData;

@property (nonatomic, assign, readonly, getter=isValid) BOOL valid;

@property (nonatomic, assign, readonly) uint32_t versionNumber;

@property (nonatomic, assign, readonly) MagicaVoxelVoxData_XYZDimensions dimensions;

@property (nonatomic, assign, readonly) MagicaVoxelVoxData_PaletteColor *paletteColors_array;
@property (nonatomic, assign, readonly) uint8_t paletteColors_count;

@property (nonatomic, assign, nullable) MagicaVoxelVoxData_Voxel *voxels_array;
@property (nonatomic, assign, readonly) uint32_t voxels_count;

#pragma mark NSData-Mirroring Interface

@property (readonly) NSUInteger length;

@end


#pragma mark NSData-Category-Mirroring Interfaces

@interface MagicaVoxelVoxData (ExtendedData)
@property (readonly, copy) NSString *description;
- (BOOL)isEqualToData:(NSData *)other;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;
- (BOOL)writeToFile:(NSString *)path options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr;
- (BOOL)writeToURL:(NSURL *)url options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr;
@end

@interface MagicaVoxelVoxData (DataCreation)
+ (instancetype)dataWithBytes:(nullable const void *)bytes length:(NSUInteger)length;
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length;
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b;
+ (nullable instancetype)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr;
+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr;
+ (nullable instancetype)dataWithContentsOfFile:(NSString *)path;
+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url;
- (instancetype)initWithBytes:(nullable const void *)bytes length:(NSUInteger)length;
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length;
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b;
- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length deallocator:(nullable void (^)(void *bytes, NSUInteger length))deallocator NS_AVAILABLE(10_9, 7_0);
- (nullable instancetype)initWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr;
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)readOptionsMask error:(NSError **)errorPtr;
- (nullable instancetype)initWithContentsOfFile:(NSString *)path;
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url;
- (instancetype)initWithData:(NSData *)data;
+ (instancetype)dataWithData:(NSData *)data;
@end

@interface MagicaVoxelVoxData (DataBase64Encoding)
- (nullable instancetype)initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options NS_AVAILABLE(10_9, 7_0);
- (NSString *)base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)options NS_AVAILABLE(10_9, 7_0);
- (nullable instancetype)initWithBase64EncodedData:(NSData *)base64Data options:(NSDataBase64DecodingOptions)options NS_AVAILABLE(10_9, 7_0);
- (NSData *)base64EncodedDataWithOptions:(NSDataBase64EncodingOptions)options NS_AVAILABLE(10_9, 7_0);
@end


#pragma clang assume_nonnull end
