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
#import "PCFPushErrors.h"
#import "PCFPushErrorUtil.h"

NSString *const kPCFPushBasicAuthorizationKey = @"Authorization";
NSString *const kPCFPushContentTypeKey = @"Content-Type";
NSString *const kPCFPushVersionRequestPath = @"v1/version";
static NSString *const kRegistrationRequestPath = @"v1/registration";
static NSString *const kGeofencesRequestPath = @"v1/geofences";
static NSString *const kAnalyticsRequestPath = @"v1/analytics";
static NSString *const kTimestampParam = @"timestamp";
static NSString *const kDeviceUuidParam = @"device_uuid";
static NSString *const kPlatformParam = @"platform=ios";
static NSTimeInterval kRequestTimeout = 60.0;

@implementation NSURL (Additions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString
{
    if (![queryString length]) {
        return self;
    }

    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
    return [NSURL URLWithString:URLString];
}

@end

void addCustomHeaders(NSMutableURLRequest *request, NSDictionary *dictionary)
{
    if (dictionary) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id headerName, id headerValue, BOOL *stop) {
            if (!headerName || ![headerName isKindOfClass:NSString.class]) {
                return;
            }
            if (!headerValue || ![headerValue isKindOfClass:NSString.class]) {
                return;
            }
            if ([headerName isEqualToString:kPCFPushBasicAuthorizationKey] || [headerName isEqualToString:kPCFPushContentTypeKey]) {
                return;
            }
            [request setValue:headerValue forHTTPHeaderField:headerName];
        }];
    }
}

@implementation PCFPushURLConnection

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PCFPushParameters *)parameters
                   success:(void (^)(NSURLResponse *, NSData *))success
                   failure:(void (^)(NSError *))failure
{
    PCFPushLog(@"Unregister with push server device ID: %@", deviceID);
    NSMutableURLRequest *request = [PCFPushURLConnection unregisterRequestForBackEndDeviceID:deviceID parameters:parameters];

    if (request) {
        [NSURLConnection pcfPushSendAsynchronousRequest:request
                                                success:success
                                                failure:^(NSURLResponse *response, NSError *error) {
                                                    if (failure) {
                                                        failure(error);
                                                    }
                                                }];
    }
}

+ (void)registerWithParameters:(PCFPushParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *, NSData *))success
                       failure:(void (^)(NSError *))failure
{
    PCFPushLog(@"Register with push server for device token: %@", deviceToken);
    NSMutableURLRequest *request = [PCFPushURLConnection registerRequestForAPNSDeviceToken:deviceToken
                                                                                parameters:parameters];

    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:^(NSURLResponse *response, NSError *error) {
                                                if (failure) {
                                                    failure(error);
                                                }
                                            }];
}

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                                parameters:(PCFPushParameters *)parameters
                               deviceToken:(NSData *)deviceToken
                                   success:(void (^)(NSURLResponse *, NSData *))success
                                   failure:(void (^)(NSError *))failure
{
    PCFPushLog(@"Update Registration with push server for device ID: %@", deviceID);
    NSMutableURLRequest *request = [PCFPushURLConnection updateRequestForDeviceID:deviceID
                                                                  APNSDeviceToken:deviceToken
                                                                       parameters:parameters];
    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:^(NSURLResponse *response, NSError *error) {
                                                if (failure) {
                                                    failure(error);
                                                }
                                            }];
}

+ (void)geofenceRequestWithParameters:(PCFPushParameters *)parameters
                            timestamp:(int64_t)timestamp
                           deviceUuid:(NSString *)deviceUuid
                              success:(void (^)(NSURLResponse *, NSData *))success
                              failure:(void (^)(NSError *))failure
{
    PCFPushLog(@"Geofence update request with push server with timestamp %lld", timestamp);
    NSURLRequest *request = [PCFPushURLConnection geofenceRequestWithTimestamp:timestamp parameters:parameters deviceUuid:deviceUuid];

    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:^(NSURLResponse *response, NSError *error) {
                                                if (failure) {
                                                    failure(error);
                                                }
                                            }];
}

+ (void)analyticsRequestWithEvents:(NSArray*)events
                        parameters:(PCFPushParameters *)parameters
                           success:(void (^)(NSURLResponse *, NSData *))success
                           failure:(void (^)(NSError *))failure
{
    if (!events) {
        [NSException raise:NSInvalidArgumentException format:@"events may not be nil"];
    }

    if (events.count == 0) {
      [NSException raise:NSInvalidArgumentException format:@"events may not be empty"];
    }

    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushParameters may not be nil"];
    }

    NSURLRequest *request = [PCFPushURLConnection analyticsPostRequestWithEvents:events parameters:parameters];
    
    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:^(NSURLResponse *response, NSError *error) {
                                                if (failure) {
                                                    failure(error);
                                                }
                                            }];
}

+ (void)versionRequestWithParameters:(PCFPushParameters *)parameters
                             success:(void (^)(NSURLResponse *, NSData *))success
                          oldVersion:(void (^)())oldVersion
                    retryableFailure:(void (^)(NSError *))retryableFailure
                        fatalFailure:(void (^)(NSError *))fatalFailure
{
    PCFPushLog(@"Requesting current back-end server version...");
    NSURLRequest *request = [PCFPushURLConnection versionRequestWithParameters:parameters];

    [NSURLConnection pcfPushSendAsynchronousRequest:request
                                            success:success
                                            failure:^(NSURLResponse *response, NSError *error) {

                                                if (response) {

                                                    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                                                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

                                                        if (httpResponse.statusCode == 404) {
                                                            if (oldVersion) {
                                                                oldVersion();
                                                            }
                                                        } else if (httpResponse.statusCode >= 400 && httpResponse.statusCode < 500) {
                                                            if (fatalFailure) {
                                                                fatalFailure(error);
                                                            }
                                                        } else if (retryableFailure) {
                                                            retryableFailure(error);
                                                        }
                                                    }

                                                } else if (error && [error.domain isEqualToString:PCFPushErrorDomain] && (error.code == PCFPushBackEndAuthenticationError)) {
                                                    if (fatalFailure) {
                                                        fatalFailure(error);
                                                    }

                                                } else if (retryableFailure) {
                                                    retryableFailure(error);
                                                }
                                            }];
}

// Retries up to three times with a pause in between each attempt
+ (void)versionRequestWithParameters:(PCFPushParameters *)parameters
                             success:(void (^)(NSString *))success
                          oldVersion:(void (^)())oldVersion
                             failure:(void (^)(NSError *))failure
{
    __block int attemptNumber = 0;

    __block void (^makeRequestBlock)();

    void (^successBlock)(NSURLResponse *, NSData *) = ^(NSURLResponse *response, NSData *data) {
        if (success) {
            NSError *error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (json && json[@"version"]) {
                success(json[@"version"]);
            } else if (failure) {
                failure([PCFPushErrorUtil errorWithCode:PCFPushBackEndDataUnparseable localizedDescription:@"Could not parse server version response data"]);
            }
        }
    };

    void (^oldVersionBlock)() = ^{
        if(oldVersion) {
            oldVersion();
        }
    };

    void (^fatalFailureBlock)(NSError *) = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    void (^retryableFailureBlock)(NSError *) = ^(NSError *error) {
        if (attemptNumber >= 2) {
            if (failure) {
                failure(error);
            }
        } else {
            attemptNumber += 1;
            makeRequestBlock();
        }
    };

    makeRequestBlock = ^{
        [PCFPushURLConnection versionRequestWithParameters:parameters
                                                   success:successBlock
                                                oldVersion:oldVersionBlock
                                          retryableFailure:retryableFailureBlock
                                              fatalFailure:fatalFailureBlock];
    };

    makeRequestBlock();
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
    [request setValue:@"application/json" forHTTPHeaderField:kPCFPushContentTypeKey];
    addCustomHeaders(request, PCFPushPersistentStorage.requestHeaders);
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
    if (!parameters.pushCustomUserId) {
        requestData.customUserId = @"";
    } else {
        requestData.customUserId = parameters.pushCustomUserId;
    }
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
    if (!parameters.pushCustomUserId) {
        requestData.customUserId = @"";
    } else {
        requestData.customUserId = parameters.pushCustomUserId;
    }
    requestData.deviceAlias = parameters.pushDeviceAlias;
    requestData.deviceManufacturer = [PCFHardwareUtil deviceManufacturer];
    requestData.deviceModel = [PCFHardwareUtil deviceModel];
    requestData.os = [PCFHardwareUtil operatingSystem];
    requestData.osVersion = [PCFHardwareUtil operatingSystemVersion];

    NSSet<NSString*> *savedTags = [PCFPushPersistentStorage tags];
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
                                                  parameters:(PCFPushParameters *)parameters
{
    if (!backEndDeviceUUID) {
        return nil;
    }

    NSURL *rootURL = [NSURL URLWithString:kRegistrationRequestPath relativeToURL:[PCFPushURLConnection baseURL]];
    NSURL *deviceURL = [rootURL URLByAppendingPathComponent:[backEndDeviceUUID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    [PCFPushURLConnection addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    request.HTTPMethod = @"DELETE";
    addCustomHeaders(request, PCFPushPersistentStorage.requestHeaders);
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
    addCustomHeaders(request, PCFPushPersistentStorage.requestHeaders);
    return request;
}

#pragma mark - Analytics

+ (NSURLRequest *)analyticsPostRequestWithEvents:(NSArray*)events
                                      parameters:(PCFPushParameters *)parameters
{

    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushParameters may not be nil"];
    }

    NSURL *requestURL = [NSURL URLWithString:kAnalyticsRequestPath relativeToURL:[PCFPushURLConnection baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [PCFPushURLConnection requestBodyForEvents:events];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [PCFPushURLConnection addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID variantSecret:parameters.variantSecret];
    addCustomHeaders(request, PCFPushPersistentStorage.requestHeaders);
    return request;
}

+ (NSData *)requestBodyForEvents:(NSArray*)events
{
    NSDictionary *payloadDictionary = @{
            @"events" : events,
    };
    NSError *error;
    NSData *bodyData = [payloadDictionary pcfPushToJSONData:&error];
    if (!bodyData) {
        PCFPushCriticalLog(@"Error while converting analytics event to JSON: %@ %@", error, error.userInfo);
        return nil;
    }

    return bodyData;
}

#pragma mark - Version Request

+ (NSURLRequest *)versionRequestWithParameters:(PCFPushParameters *)parameters
{
    if (!parameters || !parameters.variantUUID || !parameters.variantSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushParameters may not be nil"];
    }

    NSURL *requestURL = [NSURL URLWithString:kPCFPushVersionRequestPath relativeToURL:[PCFPushURLConnection baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    request.HTTPMethod = @"GET";
    addCustomHeaders(request, PCFPushPersistentStorage.requestHeaders);
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
