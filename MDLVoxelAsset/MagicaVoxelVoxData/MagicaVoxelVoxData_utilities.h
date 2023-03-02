// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#pragma once

#import <Foundation/Foundation.h>



extern int sDebugLogParseDepth;



void mvvdLog(NSString *format, ...);
NSString *indentationStringOfLength(int length);
