//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFParameters;
@class PCFAppDelegateProxy;
@class PCFAppDelegate;

@interface PCFPushClient : NSObject

@property PCFParameters *registrationParameters;
@property PCFAppDelegateProxy *appDelegateProxy;
@property UIRemoteNotificationType notificationTypes;
@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

+ (instancetype)shared;
+ (void)resetSharedClient;

- (PCFAppDelegate *)swapAppDelegate;
- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

@end
