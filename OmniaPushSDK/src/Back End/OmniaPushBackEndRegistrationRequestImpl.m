//
//  OmniaPushBackEndRegistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestImpl.h"
#import "OmniaPushBackEndRegistrationRequest.h"
#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushHexUtil.h"
#import "OmniaPushConst.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushDebug.h"
#import "OmniaPushHardwareUtil.h"

@interface OmniaPushBackEndRegistrationRequestImpl ()

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) OmniaPushBackEndRegistrationComplete successBlock;
@property (nonatomic, copy) OmniaPushBackEndRegistrationFailed failBlock;
@property (nonatomic) NSMutableData *responseData;
@property (nonatomic) NSError *resultantError;

@end

@implementation OmniaPushBackEndRegistrationRequestImpl

- (void) startDeviceRegistration:(NSData*)apnsDeviceToken
                      parameters:(OmniaPushRegistrationParameters*)parameters
                       onSuccess:(OmniaPushBackEndRegistrationComplete)successBlock
                       onFailure:(OmniaPushBackEndRegistrationFailed)failBlock
{
    if (apnsDeviceToken == nil) {
        [NSException raise:NSInvalidArgumentException format:@"apnsDeviceToken may not be nil"];
    }
    if (parameters == nil) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    if (successBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"successBlock may not be nil"];
    }
    if (failBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"failBlock may not be nil"];
    }

    self.responseData = nil;
    self.resultantError = nil;
    self.successBlock = successBlock;
    self.failBlock = failBlock;
    self.urlRequest = [self getRequestForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    self.urlConnection = [OmniaPushNSURLConnectionProvider getNSURLConnectionWithRequest:self.urlRequest delegate:self];
    [self.urlConnection start];
}

- (NSMutableURLRequest*) getRequestForAPNSDeviceToken:(NSData*)apnsDeviceToken
                                           parameters:(OmniaPushRegistrationParameters*)parameters
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

- (NSData*) getURLRequestBodyDataForForAPNSDeviceToken:(NSData*)apnsDeviceToken
                                              parameters:(OmniaPushRegistrationParameters*)parameters
{
    OmniaPushBackEndRegistrationRequestData *requestData = [self getRequestDataForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    return [requestData toJsonData];
}

- (OmniaPushBackEndRegistrationRequestData*) getRequestDataForAPNSDeviceToken:(NSData*)apnsDeviceToken
                                                                   parameters:(OmniaPushRegistrationParameters*)parameters
{
    static NSString *osVersion = nil;
    if (osVersion == nil) {
        osVersion = [[UIDevice currentDevice] systemVersion];
    }
    
    static NSString *deviceModel = nil;
    if (deviceModel == nil) {
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

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self returnError:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    self.responseData = [NSMutableData data];
    
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationNotHTTPResponseError localizedDescription:@"Response object is not an NSHTTPURLResponse object when attemping registration with back-end server"];
        return;
    }
    
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse*)response;
    
    if (![self isSuccessfulResponseCode:httpURLResponse]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:[NSString stringWithFormat:@"Received failure HTTP status code when attemping registration with back-end server: %ld", (long)httpURLResponse.statusCode]];
         return;
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    if (data != nil && data.length > 0) {
        [self.responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // Return previous error (i.e.: failure HTTP status code), if there is one
    if (self.resultantError != nil) {
        [self returnError];
        return;
    }
    
    // Empty
    if (self.responseData == nil || self.responseData.length <= 0) {
        [self returnError:[OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"]];
        return;
    }
    
    // Parse response data
    NSError *error = nil;
    OmniaPushBackEndRegistrationResponseData *responseData = [OmniaPushBackEndRegistrationResponseData fromJsonData:self.responseData error:&error];
    if (error != nil) {
        [self returnError:error];
        return;
    }
    
    // The server response must contain a device_uuid
    if (responseData.deviceUuid == nil || responseData.deviceUuid.length <= 0) {
        [self returnError:[OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Did not receive a device_uuid from back-end server when attempting registration"]];
        return;
    }
    
    // Return response data
    if (self.successBlock) {
        self.successBlock(responseData);
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void) returnError:(NSError*)error {
    self.resultantError = error;
    [self returnError];
}

- (void) returnError {
    if (self.failBlock) {
        self.failBlock(self.resultantError);
    }
}

- (BOOL) isSuccessfulResponseCode:(NSHTTPURLResponse*)response
{
    return (response.statusCode >= 200 && response.statusCode < 300);
}

@end
