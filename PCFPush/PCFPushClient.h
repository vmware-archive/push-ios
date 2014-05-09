//
//  PCFPushClient.h
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <Foundation/Foundation.h>
#import "PCFClient.h"

@class PCFAppDelegateProxy;

@interface PCFPushClient : PCFClient

@property UIRemoteNotificationType notificationTypes;

@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure;

@end
