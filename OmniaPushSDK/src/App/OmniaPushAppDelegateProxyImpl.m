//
//  OmniaPushAppDelegateProxy.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushDebug.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"

@interface OmniaPushAppDelegateProxyImpl ()

@property (nonatomic, readwrite) UIApplication *application;
@property (nonatomic, readwrite) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic, readwrite) OmniaPushAPNSRegistrationRequestOperation *registrationRequest;

@property (atomic) BOOL isRegistrationCancelled;
@property (atomic) BOOL didRegistrationSucceed;
@property (atomic) BOOL didRegistrationFail;

@end


@implementation OmniaPushAppDelegateProxyImpl

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                 registrationRequest:(OmniaPushAPNSRegistrationRequestOperation*)registrationRequest
{
    if (self = [super init]) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (originalApplicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"originalApplicationDelegate may not be nil"];
        }
        if (registrationRequest == nil) {
            [NSException raise:NSInvalidArgumentException format:@"registrationRequest may not be nil"];
        }
        self.application = application;
        self.originalApplicationDelegate = originalApplicationDelegate;
        self.registrationRequest = registrationRequest;
        self.isRegistrationCancelled = NO;
        self.didRegistrationFail = NO;
        self.didRegistrationSucceed = NO;
        [self replaceApplicationDelegate];
    }
    return self;
}

- (void) dealloc {
    self.application = nil;
    self.originalApplicationDelegate = nil;
    self.registrationRequest = nil;
}

- (void) replaceApplicationDelegate
{
    @synchronized(self) {
        self.application.delegate = self;
    }
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    [[OmniaPushOperationQueueProvider operationQueue] addOperation:self.registrationRequest];
}

- (void)application:(UIApplication*)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    self.didRegistrationSucceed = YES;
    if (self.isRegistrationCancelled) return;

    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:app applicationDelegate:self.originalApplicationDelegate deviceToken:devToken];
    
    [[OmniaPushOperationQueueProvider operationQueue] addOperation:op];
}

- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)err
{
    self.didRegistrationFail = YES;
    if (self.isRegistrationCancelled) return;

    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:app applicationDelegate:self.originalApplicationDelegate error:err];

    [[OmniaPushOperationQueueProvider operationQueue] addOperation:op];
}

- (void) application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    OmniaPushLog(@"didReceiveRemoteNotification: %@", userInfo);
    // TODO - do something here?
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
    return [self.applicationDelegate methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
    // TODO - do I need to capture my own delegate methods above?
    [invocation setTarget:self.originalApplicationDelegate];
    [invocation invoke];
}

- (void) cancelRegistration
{
    self.isRegistrationCancelled = YES;
}

@end
