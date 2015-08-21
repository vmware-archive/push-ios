#import "NSString+Version.h"

NSString *trim(NSString *s) {
    if (!s) {
        return @"0";
    } else {
        return [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    }
}

@implementation NSString(Version)

-(BOOL) isOlderVersionThan:(NSString*)otherVersion
{
	return ([trim(self) compare:trim(otherVersion) options:NSNumericSearch|NSCaseInsensitiveSearch] == NSOrderedAscending);
}

-(BOOL) isNewerOrSameVersionThan:(NSString*)otherVersion
{
    NSComparisonResult result = [trim(self) compare:trim(otherVersion) options:NSNumericSearch|NSCaseInsensitiveSearch];
    return result == NSOrderedDescending || result == NSOrderedSame;
}

@end
