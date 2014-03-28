//
//  pushAppDelegateProxy.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import "PCFPushAppDelegateProxy.h"

@implementation PCFPushAppDelegateProxy

- (id)init
{
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *signature = [self.pushAppDelegate methodSignatureForSelector:sel];
    if (signature) {
        return signature;
    }
    
    return [self.originalAppDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (!self.originalAppDelegate) {
        [NSException raise:@"PCFNilAppDelegate" format:@"PpushAppDelegateProxy originalApplicationDelegate was nil."];
    }
    
    BOOL forwarded = NO;
    
    if ([self.pushAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.pushAppDelegate];
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
    return [self.pushAppDelegate respondsToSelector:selector] && ![[NSObject class] instancesRespondToSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)sel
{
    if ([NSStringFromSelector(sel) isEqualToString:@"application:didReceiveRemoteNotification:fetchCompletionHandler:"]) {
        return [self.originalAppDelegate respondsToSelector:sel];
    }
    
    return [self.originalAppDelegate respondsToSelector:sel] || [self pushDelegateRespondsToSelector:sel];
}


@end
