//
//  OmniaPushBackEndUnregistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndUnregistrationOperationImpl.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushConst.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

typedef NS_ENUM(NSInteger, OmniaOperationState) {
    OmniaOperationReadyState       = 1,
    OmniaOperationExecutingState   = 2,
    OmniaOperationFinishedState    = 3,
};

static inline NSString * OmniaKeyPathFromOperationState(OmniaOperationState state) {
    switch (state) {
        case OmniaOperationReadyState:
            return @"isReady";
        case OmniaOperationExecutingState:
            return @"isExecuting";
        case OmniaOperationFinishedState:
            return @"isFinished";
        default: {
            return @"state";
        }
    }
}

@interface OmniaPushBackEndUnregistrationOperation ()

@property (readwrite, nonatomic, assign) OmniaOperationState state;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) OmniaPushBackEndUnregistrationComplete successBlock;
@property (nonatomic, copy) OmniaPushBackEndUnregistrationFailed failBlock;
@property (nonatomic) NSError *resultantError;

@end

@implementation OmniaPushBackEndUnregistrationOperation

- (instancetype)initDeviceUnregistrationWithUUID:(NSString *)backEndDeviceUUID
                                       onSuccess:(OmniaPushBackEndUnregistrationComplete)successBlock
                                       onFailure:(OmniaPushBackEndUnregistrationFailed)failBlock
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (backEndDeviceUUID == nil) {
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
    self.urlRequest = [self getRequestForBackEndDeviceId:backEndDeviceUUID];
    self.urlConnection = [OmniaPushNSURLConnectionProvider connectionWithRequest:self.urlRequest delegate:self];
    
    return self;
}

- (NSMutableURLRequest *) getRequestForBackEndDeviceId:(NSString *)backEndDeviceUuid
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndUnregistrationNotHTTPResponseError localizedDescription:@"Response object is not an NSHTTPURLResponse object when attemping unregistration with back-end server"];
        return;
    }
    
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
    
    if (![self isSuccessfulResponseCode:httpURLResponse]) {
        self.resultantError = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndUnregistrationFailedHTTPStatusCode localizedDescription:[NSString stringWithFormat:@"Received failure HTTP status code when attemping unregistration with back-end server: %ld",(long) httpURLResponse.statusCode]];
        return;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Return previous error (i.e.: failure HTTP status code), if there is one
    if (self.resultantError) {
        [self returnError];
        return;
    }
    
    // Return response data
    if (self.successBlock) {
        self.successBlock();
    }
    
    [self finish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void) returnError:(NSError *)error
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
- (void)finish {
    [self.lock lock];
    self.state = OmniaOperationFinishedState;
    [self.lock unlock];
}


#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == OmniaOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == OmniaOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == OmniaOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isCancelled]) {
        NSError *error = [NSError errorWithDomain:OmniaPushErrorDomain code:OmniaPushBackEndRegistrationCancelled userInfo:nil];
        self.failBlock(error);
        
    } else if ([self isReady]) {
        self.state = OmniaOperationExecutingState;
        [self.urlConnection start];
    }
    [self.lock unlock];
}

@end
