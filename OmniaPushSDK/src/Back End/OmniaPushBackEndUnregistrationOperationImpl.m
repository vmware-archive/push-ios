//
//  OmniaPushBackEndUnregistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndUnregistrationOperationImpl.h"
#import "OmniaPushConst.h"

@implementation OmniaPushBackEndUnregistrationOperation

- (instancetype)initDeviceUnregistrationWithUUID:(NSString *)backEndDeviceUUID
                                       onSuccess:(OmniaPushBackEndSuccessBlock)successBlock
                                       onFailure:(OmniaPushBackEndFailureBlock)failBlock
{
    self = [super initWithRequest:[self.class getRequestForBackEndDeviceId:backEndDeviceUUID] success:successBlock failure:failBlock];
    if (!self) {
        return nil;
    }
    return self;
}

+ (NSMutableURLRequest *) getRequestForBackEndDeviceId:(NSString *)backEndDeviceUuid
{
    NSURL *url = [[NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL] URLByAppendingPathComponent:backEndDeviceUuid];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"DELETE";
    return urlRequest;
}

@end
