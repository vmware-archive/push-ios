//
//  pushAppDelegateProxy.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <objc/runtime.h>
#import "PCFAppDelegateProxy.h"

@implementation PCFAppDelegateProxy

- (id)init
{
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *signature = [self.swappedAppDelegate methodSignatureForSelector:sel];
    if (signature) {
        return signature;
    }
    
    return [self.originalAppDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (!self.originalAppDelegate) {
        [NSException raise:@"PCFNilAppDelegate" format:@"PCFAppDelegateProxy originalApplicationDelegate was nil."];
    }
    
    BOOL forwarded = NO;
    
    if ([self.swappedAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.swappedAppDelegate];
    }

    if ([self.originalAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
    
    if (!forwarded) {
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
}

- (BOOL)pushDelegateRespondsToSelector:(SEL)selector
{
    return [self.swappedAppDelegate respondsToSelector:selector] && ![[NSObject class] instancesRespondToSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)sel
{
    if (sel_isEqual(sel, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:))) {
        BOOL remoteNotificationSupported = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"] containsObject:@"remote-notification"];
        BOOL iOS7orGreater = floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1;
        return remoteNotificationSupported && iOS7orGreater;
    }
    
    return [self.originalAppDelegate respondsToSelector:sel] || [self pushDelegateRespondsToSelector:sel];
}


@end
