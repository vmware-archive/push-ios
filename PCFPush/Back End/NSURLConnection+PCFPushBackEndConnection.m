//
//  NSURLConnection+PCFPushBackEndConnection.m
//  PCFPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushErrors.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushHexUtil.h"
#import "PCFPushHardwareUtil.h"
#import "PCFPushRegistrationRequestData.h"
#import "PCFPushParameters.h"
#import "PCFPushDebug.h"

static NSString *const BACK_END_REGISTRATION_REQUEST_URL = @"http://ec2-54-234-124-123.compute-1.amazonaws.com:8090/v1/registration";
static NSInteger BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS = 60.0;

@implementation NSURLConnection (PCFPushBackEndConnection)

+ (void)cf_unregisterDeviceID:(NSString *)deviceID
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    [self cf_sendAsynchronousRequest:[self unregisterRequestForBackEndDeviceId:deviceID]
                                success:success
                                failure:failure];
}

+ (void)cf_registerWithParameters:(PCFPushParameters *)parameters
                      devToken:(NSData *)devToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    [self cf_sendAsynchronousRequest:[self registrationRequestForAPNSDeviceToken:devToken
                                                                         parameters:parameters]
                                success:success
                                failure:failure];
}

+ (void)cf_sendAsynchronousRequest:(NSURLRequest *)request
                        success:(void (^)(NSURLResponse *response, NSData *data))success
                        failure:(void (^)(NSError *error))failure
{
    if (!success) {
        [NSException raise:NSInvalidArgumentException format:@"success block may not be nil"];
    }
    
    if (!failure) {
        [NSException raise:NSInvalidArgumentException format:@"failure block may not be nil"];
    }
    
    if (!request) {
        NSError *error = [NSError errorWithDomain:PCFPushErrorDomain code:PCFPushBackEndUnregistrationFailedRequestStatusCode userInfo:nil];
        failure(error);
        return;
    }
    
    void (^handler)(NSURLResponse *response, NSData *data, NSError *connectionError) = ^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if (connectionError) {
            if (failure) {
                failure(connectionError);
            }
        } else {
            if (success) {
                success(response, data);
            }
        }
    };
    
    [self sendAsynchronousRequest:request
                            queue:[NSOperationQueue mainQueue]
                completionHandler:handler];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)registrationRequestForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                    parameters:(PCFPushParameters *)parameters
{
    if (!apnsDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }
    
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushRegistrationParameters may not be nil"];
    }
    
    NSURL *url = [NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    PCFPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding]);
    return urlRequest;
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    NSError *error = nil;
    PCFPushRegistrationRequestData *requestData = [self requestDataForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    return [requestData toJSONData:&error];
}

+ (PCFPushRegistrationRequestData *)requestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                                parameters:(PCFPushParameters *)parameters
{
    static NSString *osVersion = nil;
    if (!osVersion) {
        osVersion = [[UIDevice currentDevice] systemVersion];
    }
    
    static NSString *deviceModel = nil;
    if (!deviceModel) {
        deviceModel = [PCFPushHardwareUtil hardwareSimpleDescription];
    }
    
    PCFPushRegistrationRequestData *requestData = [[PCFPushRegistrationRequestData alloc] init];
    requestData.registrationToken = [PCFPushHexUtil hexDumpForData:apnsDeviceToken];
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

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceId:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }
    
    NSURL *url = [[NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL] URLByAppendingPathComponent:backEndDeviceUUID];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"DELETE";
    return urlRequest;
}

@end
