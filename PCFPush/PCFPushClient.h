//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFAppDelegate;
@class PCFPushParameters;

@interface PCFPushClient : NSObject

@property PCFPushParameters *registrationParameters;
@property UIRemoteNotificationType notificationTypes;
@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

+ (instancetype)shared;
+ (void)resetSharedClient;

- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

@end
