//
//  OmniaPushBackEndUnregistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndUnregistrationRequestImpl.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushConst.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

@interface OmniaPushBackEndUnregistrationRequestImpl ()

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) OmniaPushBackEndUnregistrationComplete successBlock;
@property (nonatomic, copy) OmniaPushBackEndUnregistrationFailed failBlock;
@property (nonatomic) NSError *resultantError;

@end

@implementation OmniaPushBackEndUnregistrationRequestImpl

- (void) startDeviceUnregistration:(NSString*)backEndDeviceUuid
                         onSuccess:(OmniaPushBackEndUnregistrationComplete)successBlock
                         onFailure:(OmniaPushBackEndUnregistrationFailed)failBlock
{
    if (backEndDeviceUuid == nil) {
        [NSException raise:NSInvalidArgumentException format:@"backEndDeviceUuid may not be nil"];
    }
    if (successBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"successBlock may not be nil"];
    }
    if (failBlock == nil) {
        [NSException raise:NSInvalidArgumentException format:@"failBlock may not be nil"];
    }
    self.resultantError = nil;
    self.successBlock = successBlock;
    self.failBlock = failBlock;
    self.urlRequest = [self getRequestForBackEndDeviceId:backEndDeviceUuid];
    self.urlConnection = [OmniaPushNSURLConnectionProvider getNSURLConnectionWithRequest:self.urlRequest delegate:self];
    [self.urlConnection start];
}

- (NSMutableURLRequest*) getRequestForBackEndDeviceId:(NSString*)backEndDeviceUuid
{
    NSURL *url = [[NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL] URLByAppendingPathComponent:backEndDeviceUuid];
    NSTimeInterval timeout = BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"DELETE";
    return urlRequest;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self returnError:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndUnregistrationNotHTTPResponseError localizedDescription:@"Response object is not an NSHTTPURLResponse object when attemping unregistration with back-end server"];
        return;
    }
    
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse*)response;
    
    if (![self isSuccessfulResponseCode:httpURLResponse]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndUnregistrationFailedHTTPStatusCode localizedDescription:[NSString stringWithFormat:@"Received failure HTTP status code when attemping unregistration with back-end server: %ld",(long) httpURLResponse.statusCode]];
        return;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // Return previous error (i.e.: failure HTTP status code), if there is one
    if (self.resultantError != nil) {
        [self returnError];
        return;
    }
    
    // Return response data
    if (self.successBlock) {
        self.successBlock();
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void) returnError:(NSError*)error
{
    self.resultantError = error;
    [self returnError];
}

- (void) returnError
{
    if (self.failBlock) {
        self.failBlock(self.resultantError);
    }
}

- (BOOL) isSuccessfulResponseCode:(NSHTTPURLResponse*)response
{
    return (response.statusCode >= 200 && response.statusCode < 300);
}

@end
