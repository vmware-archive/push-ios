//
//  CFAppDelegateProxy.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import "CFAppDelegateProxy.h"

@implementation CFAppDelegateProxy

- (id)init
{
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *signature = [self.cfAppDelegate methodSignatureForSelector:sel];
    if (signature) {
        return signature;
    }
    
    return [self.originalAppDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (!self.originalAppDelegate) {
        [NSException raise:@"CFNilAppDelegate" format:@"CFAppDelegateProxy originalApplicationDelegate was nil."];
    }
    
    BOOL forwarded = NO;
    
    if ([self.cfAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.cfAppDelegate];
    }

    if ([self.originalAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
    
    if (!forwarded) {
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
}

- (BOOL)cfDelegateRespondsToSelector:(SEL)selector
{
    return [self.cfAppDelegate respondsToSelector:selector] &&
    ![[NSObject class] instancesRespondToSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)sel
{
    if ([NSStringFromSelector(sel) isEqualToString:@"application:didReceiveRemoteNotification:fetchCompletionHandler:"]) {
        return [self.originalAppDelegate respondsToSelector:sel];
    }
    
    return [self.originalAppDelegate respondsToSelector:sel] || [self cfDelegateRespondsToSelector:sel];
}


@end
