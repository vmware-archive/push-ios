//
//  PCFPushSecretUtil.m
//  Pods
//
//  Created by DX202 on 2017-03-06.
//
//
//

#import "PCFPushSecretStorage.h"
#import "PCFPushInMemorySecretStorage.h"
#import "PCFPushParameters.h"

@implementation PCFPushSecretUtil

static id<PCFPushSecretStorage> secretStorage;

+ (void)setStorage:(id<PCFPushSecretStorage>)storage
{
    secretStorage = storage;
}

+ (id<PCFPushSecretStorage>)getStorage
{
    if(secretStorage == nil) {
        secretStorage = [[PCFPushInMemorySecretStorage alloc] init];
    }
    
    return secretStorage;
}

@end
