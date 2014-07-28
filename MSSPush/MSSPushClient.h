//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSSClient.h"

@class MSSAppDelegateProxy;

@interface MSSPushClient : MSSClient

@property UIRemoteNotificationType notificationTypes;

@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

@end
