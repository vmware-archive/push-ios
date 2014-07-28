//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MSSAppDelegate : NSObject <UIApplicationDelegate>

- (void)setPushRegistrationBlockWithSuccess:(void (^)(NSData *deviceToken))success
                                    failure:(void (^)(NSError *error))failure;
@end
