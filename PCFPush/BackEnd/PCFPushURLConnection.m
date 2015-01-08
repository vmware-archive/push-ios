//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushDebug.h"
#import "PCFParameters.h"
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

NSString *const kBasicAuthorizationKey = @"Authorization";

static NSString *const kRegistrationRequestPath = @"v1/registration";
static NSTimeInterval kRegistrationTimeout = 60.0;

@implementation PCFPushURLConnection

+ (NSURL *)baseURL
{
    PCFParameters *params = [[PCFPushClient shared] registrationParameters];
    if (!params || !params.pushAPIURL) {
        PCFPushLog(@"PCFPushURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.pushAPIURL];
}

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PCFParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Unregister with push server device ID: %@", deviceID);
    NSMutableURLRequest *request = [self unregisterRequestForBackEndDeviceID:deviceID];
    
    if (request) {
        [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];

        [NSURLConnection pcf_sendAsynchronousRequest:request
                                             success:success
                                             failure:failure];
    }
}

+ (void)registerWithParameters:(PCFParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Register with push server for device token: %@", deviceToken);
    NSMutableURLRequest *request = [self registerRequestForAPNSDeviceToken:deviceToken
                                                                parameters:parameters];

    [NSURLConnection pcf_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                                parameters:(PCFParameters *)parameters
                               deviceToken:(NSData *)deviceToken
                                   success:(void (^)(NSURLResponse *response, NSData *data))success
                                   failure:(void (^)(NSError *error))failure
{
    PCFPushLog(@"Update Registration with push server for device ID: %@", deviceID);
    NSMutableURLRequest *request = [self updateRequestForDeviceID:deviceID
                                                  APNSDeviceToken:deviceToken
                                                       parameters:parameters];
    [NSURLConnection pcf_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)updateRequestForDeviceID:(NSString *)deviceID
                                  APNSDeviceToken:(NSData *)APNSDeviceToken
                                       parameters:(PCFParameters *)parameters
{
    NSString *relativePath = [[NSString stringWithFormat:@"%@/%@", kRegistrationRequestPath, deviceID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:relativePath
                                 HTTPMethod:@"PUT"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)registerRequestForAPNSDeviceToken:(NSData *)APNSDeviceToken
                                                parameters:(PCFParameters *)parameters
{
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:kRegistrationRequestPath
                                 HTTPMethod:@"POST"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)requestWithAPNSDeviceToken:(NSData *)APNSDeviceToken
                                       relativePath:(NSString *)path
                                         HTTPMethod:(NSString *)method
                                         parameters:(PCFParameters *)parameters
{
    if (!APNSDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }
    
    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFParameters may not be nil"];
    }
    
    NSURL *registrationURL = [NSURL URLWithString:path relativeToURL:[self baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRegistrationTimeout];
    request.HTTPMethod = method;
    [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    request.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:APNSDeviceToken method:method parameters:parameters];
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
    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [plainData base64EncodedStringWithOptions:0];
        
    } else {
        return [plainData base64Encoding];
    }
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                          method:(NSString *)method
                                      parameters:(PCFParameters *)parameters
{
    NSError *error = nil;
    if ([method isEqualToString:@"POST"]) {

        PCFPushRegistrationPostRequestData *requestData = [self pushRequestDataForAPNSDeviceToken:apnsDeviceToken
                                                                                       parameters:parameters];
        return [requestData pcf_toJSONData:&error];
    } else if ([method isEqualToString:@"PUT"]) {
        
        PCFPushRegistrationPutRequestData *requestData = [self putRequestDataForAPNSDeviceToken:apnsDeviceToken
                                                                                       parameters:parameters];
        return [requestData pcf_toJSONData:&error];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Unknown method type"];
    }
    return nil;
}

+ (PCFPushRegistrationPostRequestData *)pushRequestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                       parameters:(PCFParameters *)parameters
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
                                                              parameters:(PCFParameters *)parameters
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

#pragma mark - Unregister

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceID:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }
    
    NSURL *rootURL = [NSURL URLWithString:kRegistrationRequestPath relativeToURL:[self baseURL]];
    NSURL *deviceURL = [rootURL URLByAppendingPathComponent:[backEndDeviceUUID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRegistrationTimeout];
    request.HTTPMethod = @"DELETE";
    return request;
}

@end
