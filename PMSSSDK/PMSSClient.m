//
//  PMSSClient.m
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <objc/runtime.h>

#import "PMSSClient.h"
#import "PMSSParameters.h"
#import "PMSSAppDelegate.h"
#import "PMSSAppDelegateProxy.h"

static PMSSClient *_sharedPMSSClient;
static dispatch_once_t _sharedPMSSClientToken;

@implementation PMSSClient

+ (instancetype)shared
{
    dispatch_once(&_sharedPMSSClientToken, ^{
        if (!_sharedPMSSClient) {
            _sharedPMSSClient = [[self alloc] init];
        }
    });
    return _sharedPMSSClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrationParameters = [PMSSParameters defaultParameters];
        [self swapAppDelegate];
    }
    return self;
}

- (PMSSAppDelegate *)swapAppDelegate
{
    UIApplication *application = [UIApplication sharedApplication];
    PMSSAppDelegate *pushAppDelegate;
    
    if (application.delegate == self.appDelegateProxy) {
        pushAppDelegate = (PMSSAppDelegate *)[self.appDelegateProxy swappedAppDelegate];
        
    } else {
        self.appDelegateProxy = [[PMSSAppDelegateProxy alloc] init];
        
        @synchronized(application) {
            pushAppDelegate = [[PMSSAppDelegate alloc] init];
            self.appDelegateProxy.originalAppDelegate = application.delegate;
            self.appDelegateProxy.swappedAppDelegate = pushAppDelegate;
            application.delegate = self.appDelegateProxy;
        }
    }
    return pushAppDelegate;
}

+ (void)resetSharedClient
{
    _sharedPMSSClientToken = 0;
    _sharedPMSSClient = nil;
}

@end
