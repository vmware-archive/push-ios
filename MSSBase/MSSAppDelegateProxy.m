//
//  MSSAppDelegateProxy.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <objc/runtime.h>
#import "MSSAppDelegateProxy.h"

typedef void (^CompletionHandler)(UIBackgroundFetchResult);

static NSUInteger expectedResultsCount = 2;
NSUInteger fetchResult = UIBackgroundFetchResultNoData;


@implementation MSSAppDelegateProxy

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

- (void)fetchCompletionHandler:(UIBackgroundFetchResult)result original:(CompletionHandler)originalCompletionHandler
{
    @synchronized(self) {
        expectedResultsCount--;
        fetchResult = [MSSAppDelegateProxy mergeNewBackgroundFetchResult:result withOldFetchResult:fetchResult];
        
        if (expectedResultsCount == 0) {
            originalCompletionHandler(fetchResult);
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (!self.originalAppDelegate) {
        [NSException raise:@"MSSNilAppDelegate" format:@"MSSAppDelegateProxy originalApplicationDelegate was nil."];
    }
    
    BOOL forwarded = NO;
    
    //Handle multiple appDelegates calling the completionHandler block.
    SEL pushSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    if (sel_isEqual(invocation.selector, pushSelector) &&
        [self.swappedAppDelegate respondsToSelector:pushSelector] &&
        [self.originalAppDelegate respondsToSelector:pushSelector])
    {
        @synchronized(self) {
            //Reset results counter
            expectedResultsCount = 2;
            fetchResult = UIBackgroundFetchResultNoData;
            CompletionHandler originalCompletionHandler = nil;
            [invocation getArgument:&originalCompletionHandler atIndex:4];
            
            if (originalCompletionHandler) {
                CompletionHandler swappedCompletionHandler = ^(UIBackgroundFetchResult result) {
                    [self fetchCompletionHandler:result original:originalCompletionHandler];
                };
                [invocation setArgument:&swappedCompletionHandler atIndex:4];
                [invocation retainArguments];
            }
        }
    }
    
    if ([self.swappedAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.swappedAppDelegate];
    }

    if ([self.originalAppDelegate respondsToSelector:invocation.selector]) {
        forwarded = YES;
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
    
    //If no appDelegate responds to the selector, crash in the originalAppDelegate instead of the swappedAppDelegate
    if (!forwarded) {
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
}

+ (UIBackgroundFetchResult)mergeNewBackgroundFetchResult:(UIBackgroundFetchResult)newResult
                                      withOldFetchResult:(UIBackgroundFetchResult)oldResult
{
    if (oldResult == UIBackgroundFetchResultNewData || newResult == UIBackgroundFetchResultNewData) {
        return UIBackgroundFetchResultNewData;
        
    } else if (oldResult == UIBackgroundFetchResultFailed || newResult == UIBackgroundFetchResultFailed) {
        return UIBackgroundFetchResultFailed;
        
    } else {
        return oldResult;
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
