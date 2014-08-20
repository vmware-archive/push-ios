//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSSParameters;
@class MSSAppDelegateProxy;
@class MSSAppDelegate;

@interface MSSPushClient : NSObject

@property MSSParameters *registrationParameters;
@property MSSAppDelegateProxy *appDelegateProxy;
@property UIRemoteNotificationType notificationTypes;
@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

+ (instancetype)shared;
+ (void)resetSharedClient;

- (MSSAppDelegate *)swapAppDelegate;
- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

@end
