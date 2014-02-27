//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;
@class OmniaPushRegistrationEngine;

@interface OmniaPushAppDelegateProxy : NSObject<UIApplicationDelegate>

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, readonly) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readonly) OmniaPushRegistrationEngine *registrationEngine;

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                  registrationEngine:(OmniaPushRegistrationEngine*)registrationEngine;

- (void) cleanup;

@end
