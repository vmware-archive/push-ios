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

+ (void)resetSharedClient
{
    _sharedPCFClientToken = 0;
    _sharedPCFClient = nil;
}

@end
