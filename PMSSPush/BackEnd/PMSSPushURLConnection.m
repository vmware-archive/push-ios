//
//  PMSSPushURLConnection.m
//  
//
//  Created by DX123-XL on 2014-04-22.
//
//

#import "PMSSPushDebug.h"
#import "PMSSParameters.h"
#import "PMSSPushURLConnection.h"
#import "PMSSHardwareUtil.h"
#import "PMSSPushRegistrationRequestData.h"
#import "NSObject+PMSSJsonizable.h"
#import "PMSSPushClient.h"
#import "PMSSPushHexUtil.h"
#import "NSURLConnection+PMSSBackEndConnection.h"

NSString *const kBasicAuthorizationKey = @"Authorization";

static NSString *const kRegistrationRequestPath = @"registration";
static NSTimeInterval kRegistrationTimeout = 60.0;

@implementation PMSSPushURLConnection

+ (NSURL *)baseURL
{
    PMSSParameters *params = [[PMSSPushClient shared] registrationParameters];
    if (!params || !params.pushAPIURL) {
        PMSSPushLog(@"PMSSPushURLConnection baseURL is nil");
        return nil;
    }
    return [NSURL URLWithString:params.pushAPIURL];
}

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PMSSParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    PMSSPushLog(@"Unregister with push server device ID: %@", deviceID);
    NSMutableURLRequest *request = [self unregisterRequestForBackEndDeviceID:deviceID];
    
    if (request) {
        [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID releaseSecret:parameters.releaseSecret];
        
        [NSURLConnection pmss_sendAsynchronousRequest:request
                                             success:success
                                             failure:failure];
    }
}

+ (void)registerWithParameters:(PMSSParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    PMSSPushLog(@"Register with push server for device token: %@", deviceToken);
    NSMutableURLRequest *request = [self registerRequestForAPNSDeviceToken:deviceToken
                                                                parameters:parameters];
    
    [NSURLConnection pmss_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                                parameters:(PMSSParameters *)parameters
                               deviceToken:(NSData *)deviceToken
                                   success:(void (^)(NSURLResponse *response, NSData *data))success
                                   failure:(void (^)(NSError *error))failure
{
    PMSSPushLog(@"Update Registration with push server for device ID: %@", deviceID);
    NSMutableURLRequest *request = [self updateRequestForDeviceID:deviceID
                                                  APNSDeviceToken:deviceToken
                                                       parameters:parameters];
    [NSURLConnection pmss_sendAsynchronousRequest:request
                                         success:success
                                         failure:failure];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)updateRequestForDeviceID:(NSString *)deviceID
                                  APNSDeviceToken:(NSData *)APNSDeviceToken
                                       parameters:(PMSSParameters *)parameters
{
    NSString *relativePath = [[NSString stringWithFormat:@"%@/%@", kRegistrationRequestPath, deviceID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:relativePath
                                 HTTPMethod:@"PUT"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)registerRequestForAPNSDeviceToken:(NSData *)APNSDeviceToken
                                                parameters:(PMSSParameters *)parameters
{
    return [self requestWithAPNSDeviceToken:APNSDeviceToken
                               relativePath:kRegistrationRequestPath
                                 HTTPMethod:@"POST"
                                 parameters:parameters];
}

+ (NSMutableURLRequest *)requestWithAPNSDeviceToken:(NSData *)APNSDeviceToken
                                       relativePath:(NSString *)path
                                         HTTPMethod:(NSString *)method
                                         parameters:(PMSSParameters *)parameters
{
    if (!APNSDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }
    
    if (!parameters || !parameters.variantUUID || !parameters.releaseSecret) {
        [NSException raise:NSInvalidArgumentException format:@"PMSSPushRegistrationParameters may not be nil"];
    }
    
    NSURL *registrationURL = [NSURL URLWithString:path relativeToURL:[self baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRegistrationTimeout];
    request.HTTPMethod = method;
    [self addBasicAuthToURLRequest:request withVariantUUID:parameters.variantUUID releaseSecret:parameters.releaseSecret];
    request.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:APNSDeviceToken parameters:parameters];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    PMSSPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    return request;
}

+ (void)addBasicAuthToURLRequest:(NSMutableURLRequest *)request
                 withVariantUUID:(NSString *)variantUUID
                   releaseSecret:(NSString *)releaseSecret
{
    NSString *authString = [self base64String:[NSString stringWithFormat:@"%@:%@", variantUUID, releaseSecret]];
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
                                      parameters:(PMSSParameters *)parameters
{
    NSError *error = nil;
    PMSSPushRegistrationRequestData *requestData = [self requestDataForAPNSDeviceToken:apnsDeviceToken
                                                                           parameters:parameters];
    return [requestData pmss_toJSONData:&error];
}

+ (PMSSPushRegistrationRequestData *)requestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                       parameters:(PMSSParameters *)parameters
{
    PMSSPushRegistrationRequestData *requestData = [[PMSSPushRegistrationRequestData alloc] init];
    requestData.registrationToken = [PMSSPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.deviceAlias = parameters.pushDeviceAlias;
    requestData.deviceManufacturer = [PMSSHardwareUtil deviceManufacturer];
    requestData.deviceModel = [PMSSHardwareUtil deviceModel];
    requestData.os = [PMSSHardwareUtil operatingSystem];
    requestData.osVersion = [PMSSHardwareUtil operatingSystemVersion];
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
