//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushDebug.h"
#import "MSSParameters.h"
#import "MSSPushURLConnection.h"
#import "MSSHardwareUtil.h"
#import "MSSPushRegistrationRequestData.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushClient.h"
#import "MSSPushHexUtil.h"
#import "NSURLConnection+MSSBackEndConnection.h"

NSString *const kBasicAuthorizationKey = @"Authorization";

static NSString *const kRegistrationRequestPath = @"v1/registration";
static NSTimeInterval kRegistrationTimeout = 60.0;

@implementation MSSPushURLConnection

+ (NSURL *)baseURL
{
    MSSParameters *params = [[MSSPushClient shared] registrationParameters];
    if (!params || !params.pushAPIURL) {
        MSSPushLog(@"MSSPushURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.pushAPIURL];
}

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(MSSParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    MSSPushLog(@"Unregister with push server device ID: %@", deviceID);
    NSMutableURLRequest *request = [self unregisterRequestForBackEndDeviceID:deviceID];
    
    if (request) {
        [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
        
        [NSURLConnection mss_sendAsynchronousRequest:request
                                             success:success
                                             failure:failure];
    }
}

+ (void)registerWithParameters:(MSSParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    MSSPushLog(@"Register with push server for device token: %@", deviceToken);
    NSMutableURLRequest *request = [self registerRequestForAPNSDeviceToken:deviceToken
                                                                parameters:parameters];
    
    [NSURLConnection mss_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                                parameters:(MSSParameters *)parameters
                               deviceToken:(NSData *)deviceToken
                                   success:(void (^)(NSURLResponse *response, NSData *data))success
                                   failure:(void (^)(NSError *error))failure
{
    MSSPushLog(@"Update Registration with push server for device ID: %@", deviceID);
    NSMutableURLRequest *request = [self updateRequestForDeviceID:deviceID
                                                  APNSDeviceToken:deviceToken
                                                       parameters:parameters];
    [NSURLConnection mss_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)updateRequestForDeviceID:(NSString *)deviceID
                                  APNSDeviceToken:(NSData *)APNSDeviceToken
                                       parameters:(MSSParameters *)parameters
{
    NSString *relativePath = [[NSString stringWithFormat:@"%@/%@", kRegistrationRequestPath, deviceID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:relativePath
                                 HTTPMethod:@"PUT"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)registerRequestForAPNSDeviceToken:(NSData *)APNSDeviceToken
                                                parameters:(MSSParameters *)parameters
{
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:kRegistrationRequestPath
                                 HTTPMethod:@"POST"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)requestWithAPNSDeviceToken:(NSData *)APNSDeviceToken
                                       relativePath:(NSString *)path
                                         HTTPMethod:(NSString *)method
                                         parameters:(MSSParameters *)parameters
{
    if (!APNSDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }
    
    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"MSSPushRegistrationParameters may not be nil"];
    }
    
    NSURL *registrationURL = [NSURL URLWithString:path relativeToURL:[self baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRegistrationTimeout];
    request.HTTPMethod = method;
    [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    request.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:APNSDeviceToken parameters:parameters];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    MSSPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    return request;
}

+ (void)addBasicAuthToURLRequest:(NSMutableURLRequest *)request
                 withVariantUUID:(NSString *)variantUUID
                   variantSecret:(NSString *)variantSecret
{
    NSString *authString = [self base64String:[NSString stringWithFormat:@"%@:%@", variantUUID, variantSecret]];
    [request setValue:[NSString stringWithFormat:@"Basic  %@", authString] forHTTPHeaderField:@"Authorization"];
}

+ (NSString *)base64String:(NSString *)normalString
{
    NSData *plainData = [normalString dataUsingEncoding:NSUTF8StringEncoding];
    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [plainData base64EncodedStringWithOptions:0];
        
    } else {
        return [plainData base64Encoding];
    }
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                      parameters:(MSSParameters *)parameters
{
    NSError *error = nil;
    MSSPushRegistrationRequestData *requestData = [self requestDataForAPNSDeviceToken:apnsDeviceToken
                                                                           parameters:parameters];
    return [requestData mss_toJSONData:&error];
}

+ (MSSPushRegistrationRequestData *)requestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                       parameters:(MSSParameters *)parameters
{
    MSSPushRegistrationRequestData *requestData = [[MSSPushRegistrationRequestData alloc] init];
    requestData.registrationToken = [MSSPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.deviceAlias = parameters.pushDeviceAlias;
    requestData.deviceManufacturer = [MSSHardwareUtil deviceManufacturer];
    requestData.deviceModel = [MSSHardwareUtil deviceModel];
    requestData.os = [MSSHardwareUtil operatingSystem];
    requestData.osVersion = [MSSHardwareUtil operatingSystemVersion];
    requestData.tags = parameters.tags;
    return requestData;
}

#pragma mark - Unregister

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceID:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }
    
    NSURL *rootURL = [NSURL URLWithString:kRegistrationRequestPath relativeToURL:[self baseURL]];
    NSURL *deviceURL = [NSURL URLWithString:[backEndDeviceUUID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] relativeToURL:rootURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRegistrationTimeout];
    request.HTTPMethod = @"DELETE";
    return request;
}

@end
