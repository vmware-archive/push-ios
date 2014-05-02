//
//  PCFClient.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <objc/runtime.h>

#import "PCFClient.h"
#import "PCFParameters.h"
#import "PCFAppDelegate.h"
#import "PCFAppDelegateProxy.h"

static PCFClient *_sharedPCFClient;
static dispatch_once_t _sharedPCFClientToken;

@implementation PCFClient

+ (instancetype)shared
{
    dispatch_once(&_sharedPCFClientToken, ^{
        if (!_sharedPCFClient) {
            _sharedPCFClient = [[self alloc] init];
        }
    });
    return _sharedPCFClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrationParameters = [PCFParameters defaultParameters];
        [self swapAppDelegate];
    }
    return self;
}

- (PCFAppDelegate *)swapAppDelegate
{
    UIApplication *application = [UIApplication sharedApplication];
    PCFAppDelegate *pushAppDelegate;
    
    if (application.delegate == self.appDelegateProxy) {
        pushAppDelegate = (PCFAppDelegate *)[self.appDelegateProxy swappedAppDelegate];
        
    } else {
        self.appDelegateProxy = [[PCFAppDelegateProxy alloc] init];
        
        @synchronized(application) {
            pushAppDelegate = [[PCFAppDelegate alloc] init];
            self.appDelegateProxy.originalAppDelegate = application.delegate;
            self.appDelegateProxy.swappedAppDelegate = pushAppDelegate;
            application.delegate = self.appDelegateProxy;
        }
    }
    return pushAppDelegate;
}

+ (void)resetSharedClient
{
    _sharedPCFClientToken = 0;
    _sharedPCFClient = nil;
}

@end
