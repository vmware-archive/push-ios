//
//  OmniaPushRegistrationFailedOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushRegistrationListener;

@interface OmniaPushRegistrationFailedOperation : NSOperation

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, weak, readonly) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic, readonly) NSError *error;

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                               error:(NSError*)error;

@end
