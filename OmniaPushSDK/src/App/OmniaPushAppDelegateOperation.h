//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushAppDelegateOperation :  NSOperation <UIApplicationDelegate>

@property (nonatomic) NSError *resultantError;

- (instancetype)initWithApplication:(UIApplication *)application
            remoteNotificationTypes:(UIRemoteNotificationType)types
                            success:(void (^)(NSData *devToken))success
                            failure:(void (^)(NSError *error))failure;

- (void)cleanup;

@end
