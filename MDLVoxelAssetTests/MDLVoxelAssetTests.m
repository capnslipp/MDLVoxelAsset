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
