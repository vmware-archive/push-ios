//
// Created by DX173-XL on 15-06-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushURLConnectionDelegate.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushErrors.h"
#import "PCFPushParameters.h"
#import "PCFPushDebug.h"

typedef void (^CompletionHandler)(NSURLResponse*, NSData*, NSError*);

@interface PCFPushURLConnectionDelegate ()

@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic, copy) CompletionHandler handler;
@property (nonatomic) NSMutableData *responseData;
@property (nonatomic) NSError *resultantError;
@property (nonatomic) NSURLResponse *response;

@end

@implementation PCFPushURLConnectionDelegate

- (instancetype)initWithRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue *)queue
              completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    self = [super init];
    if (self) {
        self.request = request;
        self.queue = queue;
        self.handler = handler;
        self.responseData = nil;
        self.resultantError = nil;
        self.response = nil;
    }
    return self;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self returnError:error];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    self.responseData = [NSMutableData data];
    self.response = response;

    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.resultantError = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationNotHTTPResponseError localizedDescription:@"Response object is not an NSHTTPURLResponse object when attemping registration with back-end server"];
        return;
    }

    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse*)response;

    if (![self isSuccessfulResponseCode:httpURLResponse]) {
        self.resultantError = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:[NSString stringWithFormat:@"Received failure HTTP status code when attemping registration with back-end server: %ld", (long)httpURLResponse.statusCode]];
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

    if (self.queue && self.handler) {
        [self.queue addOperationWithBlock:^{
            self.handler(self.response, self.responseData, nil);
        }];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connection:(NSURLConnection *)connection
        willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([PCFPushParameters defaultParameters].trustAllSslCertificates) {
        PCFPushCriticalLog(@"Note: We trust all SSL certifications in PCF Push.");
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (void) returnError:(NSError*)error
{
    self.resultantError = error;
    [self returnError];
}

- (void) returnError
{
    if (self.queue && self.handler) {
        [self.queue addOperationWithBlock:^{
            self.handler(self.response, self.responseData, self.resultantError);
        }];
    }
}

- (BOOL) isSuccessfulResponseCode:(NSHTTPURLResponse*)response
{
    return (response.statusCode >= 200 && response.statusCode < 300);
}

@end