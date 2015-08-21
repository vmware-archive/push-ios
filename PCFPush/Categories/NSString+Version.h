#import <Foundation/Foundation.h>

@interface NSString (Version)

-(BOOL) isOlderVersionThan:(NSString*)otherVersion;
-(BOOL) isNewerOrSameVersionThan:(NSString*)otherVersion;

@end

