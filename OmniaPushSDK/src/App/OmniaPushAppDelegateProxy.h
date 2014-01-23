//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;

@interface OmniaPushAppDelegateProxy : NSObject<UIApplicationDelegate>

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate;
- (void) registerWithParameters:(OmniaPushRegistrationParameters*)parameters;
- (void) cleanup;

@end
