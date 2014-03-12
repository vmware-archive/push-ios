//
//  OmniaPushAPNSRegistrationRequestOperationTest.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestOperation.h"

@interface OmniaPushAPNSRegistrationRequestOperation (TestingHeader)

@property (nonatomic, weak) UIApplication *application;

@property (nonatomic) NSData *devToken;
@property (nonatomic) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic) UIRemoteNotificationType remoteNotificationTypes;
@property (nonatomic) NSRecursiveLock *lock;

- (void)cleanup;

@end

