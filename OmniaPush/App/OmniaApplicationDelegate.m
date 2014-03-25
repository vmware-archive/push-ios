//
//  OmniaApplicationDelegate.m
//  
//
//  Created by DX123-XL on 2014-03-24.
//
//

#import <objc/runtime.h>

#import "OmniaApplicationDelegate.h"
#import "OmniaPushApplicationDelegateSwitcher.h"

@interface OmniaApplicationDelegate ()

@property NSObject<UIApplicationDelegate> *originalApplicationDelegate;
@property (copy) void (^success)(NSData *devToken);
@property (copy) void (^failure)(NSError *error);

@end

static dispatch_once_t onceToken;
static OmniaApplicationDelegate *_applicationDelegate;

@implementation OmniaApplicationDelegate

+ (instancetype)omniaApplicationDelegate {
    dispatch_once(&onceToken, ^{
        if (!_applicationDelegate) {
            _applicationDelegate = [[OmniaApplicationDelegate alloc] init];
        }
    });
    return _applicationDelegate;
}

+ (void)resetApplicationDelegate
{
    _applicationDelegate = nil;
    onceToken = 0;
}

- (void)registerWithApplication:(UIApplication *)application
        remoteNotificationTypes:(UIRemoteNotificationType)types
                        success:(void (^)(NSData *devToken))success
                        failure:(void (^)(NSError *error))failure
{
    if (!application) {
        [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
    }
    
    if (!success || !failure) {
        [NSException raise:NSInvalidArgumentException format:@"success/failure blocks may not be nil"];
    }
    
    self.originalApplicationDelegate = application.delegate;
    [OmniaPushApplicationDelegateSwitcher switchApplicationDelegate:self inApplication:application];
    
    self.success = success;
    self.failure = failure;
    
    [application registerForRemoteNotificationTypes:types];
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

#pragma mark - UIApplicationDelegate Push Notification Callback

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    if (self.success) {
        self.success(devToken);
    }
    
    if ([self.originalApplicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self.originalApplicationDelegate application:app didRegisterForRemoteNotificationsWithDeviceToken:devToken];
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    if (self.failure) {
        self.failure(err);
    }
    
    if ([self.originalApplicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
        [self.originalApplicationDelegate application:app didFailToRegisterForRemoteNotificationsWithError:err];
    }
}

@end
