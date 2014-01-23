//
//  OmniaPushRegistrationParameters.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushRegistrationParameters : NSObject

@property (nonatomic, readonly) UIRemoteNotificationType remoteNotificationTypes;
@property (nonatomic, readonly) NSString *releaseUuid;
@property (nonatomic, readonly) NSString *releaseSecret;
@property (nonatomic, readonly) NSString *deviceAlias;

- (instancetype) initForNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                              releaseUuid:(NSString*)releaseUuid
                            releaseSecret:(NSString*)releaseSecret
                              deviceAlias:(NSString*)deviceAlias;

@end
