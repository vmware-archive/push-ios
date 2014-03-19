//
//  OmniaPushAPNSRegistrationRequestOperation.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushApplicationDelegateSwitcherImpl.h"
#import "OmniaPushErrors.h"
#import "OmniaPushDebug.h"
#import "OmniaPushApplicationDelegateSwitcherImpl.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, OmniaState) {
    OmniaReadyState       = 1,
    OmniaExecutingState   = 2,
    OmniaFinishedState    = 3,
};

static inline NSString *OmniaKeyPathFromOperationState(OmniaState state) {
    switch (state) {
        case OmniaReadyState:
            return @"isReady";
        case OmniaExecutingState:
            return @"isExecuting";
        case OmniaFinishedState:
            return @"isFinished";
        default: {
            return @"state";
        }
    }
}

static NSString * const kOmniaOperationLockName = @"OmniaPushOperation.Operation.Lock";

@interface OmniaPushAPNSRegistrationRequestOperation ()

@property (nonatomic, weak) UIApplication *application;

@property (nonatomic) OmniaState state;
@property (nonatomic) NSData *devToken;
@property (nonatomic) NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (nonatomic) UIRemoteNotificationType remoteNotificationTypes;
@property (nonatomic) NSRecursiveLock *lock;

@end

@implementation OmniaPushAPNSRegistrationRequestOperation

- (instancetype)initWithApplication:(UIApplication *)application
            remoteNotificationTypes:(UIRemoteNotificationType)types
                            success:(void (^)(NSData *devToken))success
                            failure:(void (^)(NSError *error))failure
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (!application) {
        [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
    }
    
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kOmniaOperationLockName;
    
    [self setCompletionBlockWithSuccess:success failure:failure];
    
    self.application = application;
    self.originalApplicationDelegate = application.delegate;
    self.remoteNotificationTypes = types;
    [self replaceApplicationDelegate];
    
    self.state = OmniaReadyState;
    
    return self;
}

- (void)cleanup
{
    if (self.application && self.originalApplicationDelegate) {
        [self restoreApplicationDelegate];
    }
    self.application = nil;
    self.originalApplicationDelegate = nil;
}

- (void)replaceApplicationDelegate
{
    [OmniaPushApplicationDelegateSwitcherImpl switchApplicationDelegate:self inApplication:self.application];
}

- (void)restoreApplicationDelegate
{
    [OmniaPushApplicationDelegateSwitcherImpl switchApplicationDelegate:self.originalApplicationDelegate inApplication:self.application];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.originalApplicationDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.originalApplicationDelegate];
}

- (BOOL)respondsToSelector:(SEL)sel
{
    return [self respondsToProxySelectors:sel] || [self.originalApplicationDelegate respondsToSelector:sel];
}

- (BOOL)respondsToProxySelectors:(SEL)sel
{
    if (sel_isEqual(sel, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:))) {
        return YES;
        
    } else if (sel_isEqual(sel, @selector(application:didFailToRegisterForRemoteNotificationsWithError:))) {
        return YES;
        
    } else {
        return NO;
    }
}

- (void)setState:(OmniaState)state
{
    [self.lock lock];
    NSString *oldStateKey = OmniaKeyPathFromOperationState(self.state);
    NSString *newStateKey = OmniaKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (void)finish
{
    [self restoreApplicationDelegate];
    
    [self.lock lock];
    self.state = OmniaFinishedState;
    [self.lock unlock];
}

#pragma mark - UIApplicationDelegate Push Notification Callback

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    self.devToken = devToken;
    
    if ([self.originalApplicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self.originalApplicationDelegate application:app didRegisterForRemoteNotificationsWithDeviceToken:devToken];
    }
    [self finish];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    if ([self.originalApplicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
        [self.originalApplicationDelegate application:app didFailToRegisterForRemoteNotificationsWithError:err];
    }
    
    [self.lock lock];
    self.resultantError = err;
    [self.lock unlock];
    
    [self finish];
}

- (void)setCompletionBlockWithSuccess:(void (^)(NSData *devToken))success
                              failure:(void (^)(NSError *error))failure
{
    // completionBlock is manually nilled out in AFURLConnectionOperation to break the retain cycle.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
#pragma clang diagnostic ignored "-Wgnu"
    self.completionBlock = ^{
        if (self.resultantError) {
            if (failure) {
                failure(self.resultantError);
            }
        } else {
            NSData *devToken = self.devToken;
            
            if (success) {
                success(devToken);
            }
        }
    };
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __weak __typeof(self)weakSelf = self;
        [super setCompletionBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            block();
            
            [strongSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}

#pragma mark - NSOperation

- (void)start
{
    [self.lock lock];
    
    if ([self isCancelled]) {
        self.resultantError = [NSError errorWithDomain:OmniaPushErrorDomain code:OmniaPushBackEndRegistrationCancelled userInfo:nil];
        [self finish];
        
    } else if ([self isReady]) {
        self.state = OmniaExecutingState;
        OmniaPushCriticalLog(@"Registering for remote notifications with APNS.");
        [self.application registerForRemoteNotificationTypes:self.remoteNotificationTypes];
    }
    [self.lock unlock];
}

- (BOOL)isReady {
    return self.state == OmniaReadyState && [super isReady];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.state == OmniaFinishedState;
}

- (BOOL)isExecuting {
    return self.state == OmniaExecutingState;
}

@end
