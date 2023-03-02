// MDLVoxelAsset
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

#import "MagicaVoxelVoxData_utilities.h"



int sDebugLogParseDepth = 0;



void mvvdLog(NSString *format, ...)
{
	va_list variadicArgs;
	va_start(variadicArgs, format);
	NSString *logString = [[[NSString alloc] initWithFormat:format arguments:variadicArgs] autorelease];
	printf("%s\n", logString.UTF8String);
	va_end(variadicArgs);
}


NSString *indentationStringOfLength(int length) {
	return [@"" stringByPaddingToLength:length withString:@"\t" startingAtIndex:0];
}
