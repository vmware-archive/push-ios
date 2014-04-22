//
//  PCFPushClient.h
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <Foundation/Foundation.h>

@class PCFPushParameters, PCFPushAppDelegateProxy;

@interface PCFPushClient : NSObject

@property UIRemoteNotificationType notificationTypes;
@property PCFPushParameters *registrationParameters;
@property PCFPushAppDelegateProxy *appDelegateProxy;

@property (copy) void (^successBlock)(void);
@property (copy) void (^failureBlock)(NSError *error);

+ (instancetype)shared;
+ (void)resetSharedPushClient;

- (void)APNSRegistrationSuccess:(NSData *)deviceToken;
- (void)registerForRemoteNotifications;

@end
