//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushDebug.h"
#import "PCFPushParameters.h"
#import "PCFPushURLConnection.h"
#import "PCFHardwareUtil.h"
#import "PCFPushRegistrationPostRequestData.h"
#import "PCFPushRegistrationPutRequestData.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushClient.h"
#import "PCFPushHexUtil.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFTagsHelper.h"
#import "PCFPushPersistentStorage.h"

NSString *const kPCFPushBasicAuthorizationKey = @"Authorization";

static NSString *const kRegistrationRequestPath = @"v1/registration";
static NSString *const kGeofencesRequestPath = @"v1/geofences";
static NSString *const kTimestampParam = @"timestamp";
static NSString *const kDeviceUuidParam = @"device_uuid";
static NSString *const kPlatformParam = @"platform=ios";
static NSTimeInterval kRequestTimeout = 60.0;

@implementation NSURL (Additions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }

    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
    return [NSURL URLWithString:URLString];
}

@end

@implementation PCFPushURLConnection

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PCFPushParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Unregister with push server device ID: %@", deviceID);
    NSMutableURLRequest *request = [PCFPushURLConnection unregisterRequestForBackEndDeviceID:deviceID];

    if (request) {
        [PCFPushURLConnection addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];

        [NSURLConnection pcfPushSendAsynchronousRequest:request
                                                success:success
                                                failure:failure];
    }
}

+ (void)registerWithParameters:(PCFPushParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Register with push server for device token: %@", deviceToken);
    NSMutableURLRequest *request = [PCFPushURLConnection registerRequestForAPNSDeviceToken:deviceToken
                                                                                parameters:parameters];

    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:failure];
}

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                                parameters:(PCFPushParameters *)parameters
                               deviceToken:(NSData *)deviceToken
                                   success:(void (^)(NSURLResponse *response, NSData *data))success
                                   failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Update Registration with push server for device ID: %@", deviceID);
    NSMutableURLRequest *request = [PCFPushURLConnection updateRequestForDeviceID:deviceID
                                                                  APNSDeviceToken:deviceToken
                                                                       parameters:parameters];
    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:failure];
}

+ (void)geofenceRequestWithParameters:(PCFPushParameters *)parameters
                            timestamp:(int64_t)timestamp
                           deviceUuid:(NSString *)deviceUuid
                              success:(void (^)(NSURLResponse *response, NSData *data))success
                              failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Geofence update request with push server with timestamp %lld", timestamp);
    NSURLRequest *request = [PCFPushURLConnection geofenceRequestWithTimestamp:timestamp parameters:parameters deviceUuid:deviceUuid];

    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:failure];
}

#pragma mark - Registration Request

+ (NSMutableURLRequest *)updateRequestForDeviceID:(NSString *)deviceID
                                  APNSDeviceToken:(NSData *)APNSDeviceToken
                                       parameters:(PCFPushParameters *)parameters
{
    NSString *relativePath = [[NSString stringWithFormat:@"%@/%@", kRegistrationRequestPath, deviceID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [PCFPushURLConnection requestWithAPNSDeviceToken:APNSDeviceToken
                                               relativePath:relativePath
                                                 HTTPMethod:@"PUT"
                                                 parameters:parameters];
}

+ (NSMutableURLRequest *)registerRequestForAPNSDeviceToken:(NSData *)APNSDeviceToken
                                                parameters:(PCFPushParameters *)parameters
{
    return [PCFPushURLConnection requestWithAPNSDeviceToken:APNSDeviceToken
                                               relativePath:kRegistrationRequestPath
                                                 HTTPMethod:@"POST"
                                                 parameters:parameters];
}

+ (NSMutableURLRequest *)requestWithAPNSDeviceToken:(NSData *)APNSDeviceToken
                                       relativePath:(NSString *)path
                                         HTTPMethod:(NSString *)method
                                         parameters:(PCFPushParameters *)parameters
{
    if (!APNSDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }

    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushParameters may not be nil"];
    }

    NSURL *registrationURL = [NSURL URLWithString:path relativeToURL:[PCFPushURLConnection baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    request.HTTPMethod = method;
    [PCFPushURLConnection addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    request.HTTPBody = [PCFPushURLConnection requestBodyDataForForAPNSDeviceToken:APNSDeviceToken method:method parameters:parameters];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    PCFPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    return request;
}

+ (void)addBasicAuthToURLRequest:(NSMutableURLRequest *)request
                 withVariantUUID:(NSString *)variantUUID
                   variantSecret:(NSString *)variantSecret
{
    NSString *authString = [self base64String:[NSString stringWithFormat:@"%@:%@", variantUUID, variantSecret]];
    NSString *authToken = [NSString stringWithFormat:@"Basic  %@", authString];
    [request setValue:authToken forHTTPHeaderField:@"Authorization"];
}

+ (NSString *)base64String:(NSString *)normalString
{
    NSData *plainData = [normalString dataUsingEncoding:NSUTF8StringEncoding];
    return [plainData base64EncodedStringWithOptions:0]; // iOS 7.0+
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                          method:(NSString *)method
                                      parameters:(PCFPushParameters *)parameters
{
    NSError *error = nil;
    if ([method isEqualToString:@"POST"]) {

        PCFPushRegistrationPostRequestData *requestData = [PCFPushURLConnection pushRequestDataForAPNSDeviceToken:apnsDeviceToken
                                                                                       parameters:parameters];
        return [requestData pcfPushToJSONData:&error];
    } else if ([method isEqualToString:@"PUT"]) {

        PCFPushRegistrationPutRequestData *requestData = [PCFPushURLConnection putRequestDataForAPNSDeviceToken:apnsDeviceToken
                                                                                       parameters:parameters];
        return [requestData pcfPushToJSONData:&error];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Unknown method type"];
    }
    return nil;
}

+ (PCFPushRegistrationPostRequestData *)pushRequestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                       parameters:(PCFPushParameters *)parameters
{
    PCFPushRegistrationPostRequestData *requestData = [[PCFPushRegistrationPostRequestData alloc] init];
    requestData.registrationToken = [PCFPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.deviceAlias = parameters.pushDeviceAlias;
    requestData.deviceManufacturer = [PCFHardwareUtil deviceManufacturer];
    requestData.deviceModel = [PCFHardwareUtil deviceModel];
    requestData.os = [PCFHardwareUtil operatingSystem];
    requestData.osVersion = [PCFHardwareUtil operatingSystemVersion];
    if (parameters.pushTags && parameters.pushTags.count > 0) {
        requestData.tags = parameters.pushTags.allObjects;
    }
    return requestData;
}

+ (PCFPushRegistrationPutRequestData *)putRequestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                              parameters:(PCFPushParameters *)parameters
{
    PCFPushRegistrationPutRequestData *requestData = [[PCFPushRegistrationPutRequestData alloc] init];
    requestData.registrationToken = [PCFPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.deviceAlias = parameters.pushDeviceAlias;
    requestData.deviceManufacturer = [PCFHardwareUtil deviceManufacturer];
    requestData.deviceModel = [PCFHardwareUtil deviceModel];
    requestData.os = [PCFHardwareUtil operatingSystem];
    requestData.osVersion = [PCFHardwareUtil operatingSystemVersion];

    NSSet *savedTags = [PCFPushPersistentStorage tags];
    PCFTagsHelper *tagsHelper = [PCFTagsHelper tagsHelperWithSavedTags:savedTags newTags:parameters.pushTags];
    if (tagsHelper.subscribeTags && tagsHelper.subscribeTags.count > 0) {
        requestData.subscribeTags = tagsHelper.subscribeTags.allObjects;
    }
    if (tagsHelper.unsubscribeTags && tagsHelper.unsubscribeTags.count > 0) {
        requestData.unsubscribeTags = tagsHelper.unsubscribeTags.allObjects;
    }
    return requestData;
}

#pragma mark - Unregister Request

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceID:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }

    NSURL *rootURL = [NSURL URLWithString:kRegistrationRequestPath relativeToURL:[PCFPushURLConnection baseURL]];
    NSURL *deviceURL = [rootURL URLByAppendingPathComponent:[backEndDeviceUUID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    request.HTTPMethod = @"DELETE";
    return request;
}

#pragma mark - Geofence Request

+ (NSURLRequest *)geofenceRequestWithTimestamp:(int64_t)timestamp
                                    parameters:(PCFPushParameters *)parameters
                                    deviceUuid:(NSString *)deviceUuid
{
    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushParameters may not be nil"];
    }

    if (!deviceUuid) {
        [NSException raise:NSInvalidArgumentException format:@"Device UUID may not be nil"];
    }

    NSURL *requestURL = [[NSURL URLWithString:kGeofencesRequestPath relativeToURL:[PCFPushURLConnection baseURL]] URLByAppendingQueryString:[NSString stringWithFormat:@"%@=%lld&%@=%@&%@", kTimestampParam, timestamp, kDeviceUuidParam, deviceUuid, kPlatformParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    [PCFPushURLConnection addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    return request;
}

#pragma mark - Helpers

+ (NSURL *)baseURL
{
    PCFPushParameters *params = [[PCFPushClient shared] registrationParameters];
    if (!params || !params.pushAPIURL) {
        PCFPushCriticalLog(@"PCFPushURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.pushAPIURL];
}

@end
