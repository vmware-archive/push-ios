//
//  OmniaPushRegistrationCompleteOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushRegistrationListener;

@interface OmniaPushRegistrationCompleteOperation : NSOperation

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, weak, readonly) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, readonly) NSData *deviceToken;

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                         deviceToken:(NSData*)deviceToken;

@end
