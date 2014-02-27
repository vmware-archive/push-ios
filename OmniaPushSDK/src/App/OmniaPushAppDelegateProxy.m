//
//  OmniaPushAppDelegateProxy.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushDebug.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushRegistrationEngine.h"
#import <objc/runtime.h>

@interface OmniaPushAppDelegateProxy ()

@property (nonatomic, readwrite) UIApplication *application;
@property (nonatomic, readwrite) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readwrite) OmniaPushRegistrationEngine *registrationEngine;

@end

@implementation OmniaPushAppDelegateProxy

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                  registrationEngine:(OmniaPushRegistrationEngine*)registrationEngine
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (originalApplicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"originalApplicationDelegate may not be nil"];
        }
        if (registrationEngine == nil) {
            [NSException raise:NSInvalidArgumentException format:@"registrationEngine may not be nil"];
        }
        self.application = application;
        self.originalApplicationDelegate = originalApplicationDelegate;
        self.registrationEngine = registrationEngine;
        [self replaceApplicationDelegate];
    }
    return self;
}

- (void) cleanup
{
    if (self.application && self.originalApplicationDelegate) {
        [self restoreApplicationDelegate];
    }
    self.application = nil;
    self.originalApplicationDelegate = nil;
}

- (void) replaceApplicationDelegate
{
    [[self getApplicationDelegateSwitcher] switchApplicationDelegate:self inApplication:self.application];
}

- (void) restoreApplicationDelegate
{
    [[self getApplicationDelegateSwitcher] switchApplicationDelegate:self.originalApplicationDelegate inApplication:self.application];
}

- (NSObject<OmniaPushApplicationDelegateSwitcher>*) getApplicationDelegateSwitcher
{
    return [OmniaPushApplicationDelegateSwitcherProvider switcher];
}

- (void)application:(UIApplication*)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    if (self.registrationEngine) {
        [self.registrationEngine apnsRegistrationSucceeded:devToken];
    }
}

- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)err
{
    if (self.registrationEngine) {
        [self.registrationEngine apnsRegistrationFailed:err];
    }
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
    return [self.originalApplicationDelegate methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
    [invocation setTarget:self.originalApplicationDelegate];
    [invocation invoke];
}

- (BOOL) respondsToSelector:(SEL)sel
{
    return [self respondsToProxySelectors:sel] || [self.originalApplicationDelegate respondsToSelector:sel];
}

- (BOOL) respondsToProxySelectors:(SEL)sel
{
    if (sel_isEqual(sel, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:))) {
        return YES;
    } else if (sel_isEqual(sel, @selector(application:didFailToRegisterForRemoteNotificationsWithError:))) {
        return YES;
    } else {
        return NO;
    }
}

@end
