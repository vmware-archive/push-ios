//
//  OmniaPushBackEndOperation.m
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndOperation.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

static NSString * const kOmniaNetworkingLockName = @"Omnia.Networking.Operation.Lock";

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

static dispatch_queue_t omnia_request_operation_processing_queue() {
    static dispatch_queue_t af_http_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_http_request_operation_processing_queue = dispatch_queue_create("Omina.Request.Processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return af_http_request_operation_processing_queue;
}

static dispatch_group_t omnia_request_operation_completion_group() {
    static dispatch_group_t omnia_http_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        omnia_http_request_operation_completion_group = dispatch_group_create();
    });
    
    return omnia_http_request_operation_completion_group;
}


@interface OmniaPushBackEndOperation ()

@property (readwrite, nonatomic, assign) OmniaOperationState state;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@property (readwrite, nonatomic, strong) NSError *resultantError;

@property (nonatomic, strong) NSURLConnection *URLConnection;
@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) dispatch_group_t completionGroup;

@end

@implementation OmniaPushBackEndOperation

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"OmniaPushSDK"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (id)initWithRequest:(NSURLRequest *)request success:(OmniaPushBackEndSuccessBlock)success failure:(OmniaPushBackEndFailureBlock)failure {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kOmniaNetworkingLockName;
    
    self.resultantError = nil;
    [self setCompletionBlockWithSuccess:success failure:failure];
    self.request = request;
    
    self.state = OmniaOperationReadyState;
    
    return self;
}

- (void)dealloc
{
    NSLog(@"");
}

- (void)setCompletionBlockWithSuccess:(void (^)(id responseObject))success
                              failure:(void (^)(NSError *error))failure
{
    // completionBlock is manually nilled out in AFURLConnectionOperation to break the retain cycle.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
#pragma clang diagnostic ignored "-Wgnu"
    self.completionBlock = ^{
        if (self.completionGroup) {
            dispatch_group_enter(self.completionGroup);
        }
        
        dispatch_async(omnia_request_operation_processing_queue(), ^{
            if (self.resultantError) {
                if (failure) {
                    dispatch_group_async(self.completionGroup ?: omnia_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                        failure(self.resultantError);
                    });
                }
            } else {
                id responseData = self.responseData;
                if (self.resultantError) {
                    if (failure) {
                        dispatch_group_async(self.completionGroup ?: omnia_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                            failure(self.resultantError);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_group_async(self.completionGroup ?: omnia_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                            success(responseData);
                        });
                    }
                }
            }
            if (self.completionGroup) {
                dispatch_group_leave(self.completionGroup);
            }
        });
    };
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __weak __typeof(self)weakSelf = self;
        [super setCompletionBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_group_t group = strongSelf.completionGroup ?: omnia_request_operation_completion_group();
            dispatch_queue_t queue = strongSelf.completionQueue ?: dispatch_get_main_queue();
#pragma clang diagnostic pop

            dispatch_group_async(group, queue, ^{
                block();
            });
            
            dispatch_group_notify(group, omnia_request_operation_processing_queue(), ^{
                [strongSelf setCompletionBlock:nil];
            });
        }];
    }
    [self.lock unlock];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
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
    
    [self.outputStream open];
}

- (NSOutputStream *)outputStream {
    if (!_outputStream) {
        self.outputStream = [NSOutputStream outputStreamToMemory];
    }
    
    return _outputStream;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger length = [data length];
    while (YES) {
        NSInteger totalNumberOfBytesWritten = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];
            
            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < (NSInteger)length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[(NSUInteger)totalNumberOfBytesWritten] maxLength:(length - (NSUInteger)totalNumberOfBytesWritten)];
                if (numberOfBytesWritten == -1) {
                    break;
                }
                
                totalNumberOfBytesWritten += numberOfBytesWritten;
            }
            
            break;
        }
        
        if (self.outputStream.streamError) {
            [self.URLConnection cancel];
            [self returnError:self.outputStream.streamError];
            [self finish];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self.outputStream close];
    
    [self finish];
    
    self.URLConnection = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)returnError:(NSError *)error
{
    self.resultantError = error;
    
    [self.outputStream close];
    
    [self finish];
    
    self.URLConnection = nil;

}

- (BOOL)isSuccessfulResponseCode:(NSHTTPURLResponse *)response
{
    return (response.statusCode >= 200 && response.statusCode < 300);
}

- (void)finish {
    [self.lock lock];
    self.state = OmniaOperationFinishedState;
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    
    if (![self isCancelled]) {
        self.URLConnection = [NSURLConnection connectionWithRequest:self.request delegate:self];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [self.URLConnection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        [self.outputStream scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        
        [self.URLConnection start];
    }
    
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
        self.resultantError = [NSError errorWithDomain:OmniaPushErrorDomain code:OmniaPushBackEndRegistrationCancelled userInfo:nil];
        
        if (self.URLConnection) {
            [self.URLConnection cancel];
            [self.outputStream close];
            [self finish];
            self.URLConnection = nil;
            
        } else {
            [self finish];
        }
        
    } else if ([self isReady]) {
        self.state = OmniaOperationExecutingState;
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    }
    
    [self.lock unlock];
}

@end
