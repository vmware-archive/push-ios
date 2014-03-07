//
//  OmniaPushBackEndConnection.m
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndConnection.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushHexUtil.h"
#import "OmniaPushHardwareUtil.h"
#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushDebug.h"

static NSString *const BACK_END_REGISTRATION_REQUEST_URL = @"http://ec2-54-234-124-123.compute-1.amazonaws.com:8090/v1/registration";
static NSInteger BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS = 60.0;

@implementation OmniaPushBackEndConnection

+ (void)sendUnregistrationRequestOnQueue:(NSOperationQueue *)queue
                          withDeviceID:(NSString *)deviceID
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    [self sendAsynchronousRequest:[self unregisterRequestForBackEndDeviceId:deviceID]
                            queue:queue
                          success:success
                          failure:failure];
}

+ (void)sendRegistrationRequestOnQueue:(NSOperationQueue *)queue
                        withParameters:(OmniaPushRegistrationParameters *)parameters
                              devToken:(NSData *)devToken
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    [self sendAsynchronousRequest:[self registrationRequestForAPNSDeviceToken:devToken parameters:parameters]
                            queue:queue
                          success:success
                          failure:failure];
}

+ (void)sendAsynchronousRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue *)queue
                        success:(void (^)(NSURLResponse *response, NSData *data))success
                        failure:(void (^)(NSURLResponse *response, NSError *error))failure
{
    void (^handler)(NSURLResponse *response, NSData *data, NSError *connectionError) = ^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if (connectionError) {
            if (failure) {
                failure(response, connectionError);
            }
        } else {
            if (success) {
                success(response, data);
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:handler];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)registrationRequestForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                    parameters:(OmniaPushRegistrationParameters *)parameters
{
    NSURL *url = [NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    OmniaPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding]);
    return urlRequest;
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                      parameters:(OmniaPushRegistrationParameters *)parameters
{
    OmniaPushBackEndRegistrationRequestData *requestData = [self requestDataForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    return [requestData toJSONData];
}

+ (OmniaPushBackEndRegistrationRequestData *)requestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
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
    requestData.releaseUUID = parameters.releaseUUID;
    requestData.secret = parameters.releaseSecret;
    requestData.deviceAlias = parameters.deviceAlias;
    requestData.deviceManufacturer = @"Apple";
    requestData.deviceModel = deviceModel;
    requestData.os = @"ios";
    requestData.osVersion = osVersion;
    return requestData;
}

#pragma mark - Unregister

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceId:(NSString *)backEndDeviceUuid
{
    NSURL *url = [[NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL] URLByAppendingPathComponent:backEndDeviceUuid];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"DELETE";
    return urlRequest;
}

@end
