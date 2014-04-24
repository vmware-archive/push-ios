//
//  PCFSDK.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import "PCFSDK.h"
#import "PCFClient.h"
#import "PCFAppDelegateProxy.h"
#import "PCFParameters.h"
#import "PCFPushDebug.h"

@implementation PCFSDK

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appDidFinishLaunchingNotification:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    PCFClient *pushClient = [PCFClient shared];
    
    if (![pushClient registrationParameters]) {
        PCFParameters *params = [PCFParameters defaultParameters];
        
        if (!params) {
            PCFPushLog(@"PCFPush registration parameters not set in application:didFinishLaunchingWithOptions:");
            return;
        }
        [pushClient setRegistrationParameters:params];
    }
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PCFAppDelegateProxy class]]) {
        @synchronized (application) {
            PCFAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
    
    [PCFClient resetSharedClient];
}

@end
