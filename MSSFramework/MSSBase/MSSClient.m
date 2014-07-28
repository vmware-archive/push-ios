//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "MSSClient.h"
#import "MSSParameters.h"
#import "MSSAppDelegate.h"
#import "MSSAppDelegateProxy.h"

static MSSClient *_sharedMSSClient;
static dispatch_once_t _sharedMSSClientToken;

@implementation MSSClient

+ (instancetype)shared
{
    dispatch_once(&_sharedMSSClientToken, ^{
        if (!_sharedMSSClient) {
            _sharedMSSClient = [[self alloc] init];
        }
    });
    return _sharedMSSClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrationParameters = [MSSParameters defaultParameters];
        [self swapAppDelegate];
    }
    return self;
}

- (MSSAppDelegate *)swapAppDelegate
{
    UIApplication *application = [UIApplication sharedApplication];
    MSSAppDelegate *pushAppDelegate;
    
    if (application.delegate == self.appDelegateProxy) {
        pushAppDelegate = (MSSAppDelegate *)[self.appDelegateProxy swappedAppDelegate];
        
    } else {
        self.appDelegateProxy = [[MSSAppDelegateProxy alloc] init];
        
        @synchronized(application) {
            pushAppDelegate = [[MSSAppDelegate alloc] init];
            self.appDelegateProxy.originalAppDelegate = application.delegate;
            self.appDelegateProxy.swappedAppDelegate = pushAppDelegate;
            application.delegate = self.appDelegateProxy;
        }
    }
    return pushAppDelegate;
}

+ (void)resetSharedClient
{
    _sharedMSSClientToken = 0;
    _sharedMSSClient = nil;
}

@end
