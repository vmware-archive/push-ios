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
    }
    return self;
}

+ (void)resetSharedClient
{
    _sharedPCFClientToken = 0;
    _sharedPCFClient = nil;
}

@end
