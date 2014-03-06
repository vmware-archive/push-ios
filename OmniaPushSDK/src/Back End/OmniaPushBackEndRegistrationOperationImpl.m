//
//  OmniaPushBackEndRegistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationOperationImpl.h"
#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushHardwareUtil.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushHexUtil.h"
#import "OmniaPushDebug.h"
#import "OmniaPushErrors.h"
#import "OmniaPushConst.h"

@implementation OmniaPushBackEndRegistrationOperation

- (instancetype)initDeviceRegistrationWithDevToken:(NSData *)apnsDeviceToken
                                        parameters:(OmniaPushRegistrationParameters *)parameters
                                         onSuccess:(void (^)(id responseData))successBlock
                                         onFailure:(OmniaPushBackEndFailureBlock)failBlock
{
    NSURLRequest *request = [self.class requestForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    self = [super initWithRequest:request success:successBlock failure:failBlock];
    if (self) {
    }
    return self;
}

+ (NSMutableURLRequest *)requestForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                        parameters:(OmniaPushRegistrationParameters *)parameters
{
    NSURL *url = [NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [self getURLRequestBodyDataForForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    OmniaPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding]);
    return urlRequest;
}

+ (NSData *)getURLRequestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                            parameters:(OmniaPushRegistrationParameters *)parameters
{
    OmniaPushBackEndRegistrationRequestData *requestData = [self getRequestDataForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    return [requestData toJsonData];
}

+ (OmniaPushBackEndRegistrationRequestData *)getRequestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                                   parameters:(OmniaPushRegistrationParameters *)parameters
{
    static NSString *osVersion = nil;
    if (!osVersion) {
        osVersion = [[UIDevice currentDevice] systemVersion];
    }
    
    static NSString *deviceModel = nil;
    if (!deviceModel) {
        deviceModel = [OmniaPushHardwareUtil OmniaPush_hardwareSimpleDescription];
    }
    
    OmniaPushBackEndRegistrationRequestData *requestData = [[OmniaPushBackEndRegistrationRequestData alloc] init];
    requestData.registrationToken = [OmniaPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.releaseUuid = parameters.releaseUuid;
    requestData.secret = parameters.releaseSecret;
    requestData.deviceAlias = parameters.deviceAlias;
    requestData.deviceManufacturer = @"Apple";
    requestData.deviceModel = deviceModel;
    requestData.os = @"ios";
    requestData.osVersion = osVersion;
    return requestData;
}

- (void)setResponseData:(id)responseData
{
    if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
        [self returnError:[OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"]];
        return;
    }
    
    // Parse response data
    NSError *error = nil;
    OmniaPushBackEndRegistrationResponseData *parsedData = [OmniaPushBackEndRegistrationResponseData fromJsonData:responseData error:&error];
    
    if (error) {
        [self returnError:error];
        return;
    }
    
    [super setResponseData:parsedData];
}

@end
