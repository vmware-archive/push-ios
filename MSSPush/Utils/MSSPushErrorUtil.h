//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSSPushErrorUtil : NSObject

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription;

@end
