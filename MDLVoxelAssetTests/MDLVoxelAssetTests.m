//  MDLVoxelAssetTests.m
//  MDLVoxelAssetTests
//
//  Created by Cap'n Slipp on 5/16/16.
//  Copyright © 2016 Cap'n Slipp. All rights reserved.

#import <XCTest/XCTest.h>

#import "MagicaVoxelVoxData.h"



@interface MDLVoxelAssetTests : XCTestCase

+ (NSBundle *)testBundle;
- (NSBundle *)testBundle;
	
@end



@implementation MDLVoxelAssetTests

+ (NSBundle *)testBundle
{
	static NSBundle *sTestBundle = nil;
	if (sTestBundle == nil) {
		sTestBundle = [[NSBundle bundleForClass:self.class] retain];
	}
	
	return sTestBundle;
}
- (NSBundle *)testBundle { return self.class.testBundle; }

- (void)setUp
{
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

/// Use XCTAssert and related functions to verify your tests produce the correct results.
- (void)testVoxLoad
{
	NSString *testVoxFilePath = [self.testBundle pathForResource:@"chr_sword" ofType:@"vox"];
	
	MagicaVoxelVoxData *data = [MagicaVoxelVoxData dataWithContentsOfFile:testVoxFilePath];
	XCTAssertTrue(data.valid);
	
	XCTAssertEqual(data.versionNumber, 150);
	
	MagicaVoxelVoxData_XYZDimensions dimensions = data.dimensions;
	XCTAssertEqual(dimensions.x, 20);
	XCTAssertEqual(dimensions.y, 21);
	XCTAssertEqual(dimensions.z, 20);
	
	XCTAssertEqual(data.paletteColors_count, 256);
	MagicaVoxelVoxData_PaletteColor paletteColors_array[256];
	memcpy(paletteColors_array, data.paletteColors_array, sizeof(MagicaVoxelVoxData_PaletteColor) * 256);
	XCTAssertEqual(paletteColors_array[0].r, (uint8_t)'\xFC');
	XCTAssertEqual(paletteColors_array[0].g, (uint8_t)'\xFC');
	XCTAssertEqual(paletteColors_array[0].b, (uint8_t)'\xFC');
	XCTAssertEqual(paletteColors_array[0].a, (uint8_t)'\xFF');
	
	XCTAssertEqual(data.voxels_count, 334);
	MagicaVoxelVoxData_Voxel voxels_array[334];
	memcpy(voxels_array, data.voxels_array, sizeof(MagicaVoxelVoxData_Voxel) * 334);
	XCTAssertEqual(voxels_array[0].x, 1);
	XCTAssertEqual(voxels_array[0].y, 10);
	XCTAssertEqual(voxels_array[0].z, 2);
	XCTAssertEqual(voxels_array[0].colorIndex, 1);
	
	NSLog(@"data: %@", data.description);
}

- (void)testPerformanceExample
{
	// This is an example of a performance test case.
	[self measureBlock:^{
		// Put the code you want to measure the time of here.
	}];
}


@end
