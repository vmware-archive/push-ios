//
//  BackEndMessageRequest.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "BackEndMessageRequest.h"
#import "PCFPushDebug.h"

static NSString *const BACK_END_PUSH_MESSAGE_API          = @"http://push-admin.main.vchs.cfms-apps.com//v1/push";
static CGFloat BACK_END_PUSH_MESSAGE_TIMEOUT_IN_SECONDS   = 60.0;

@interface BackEndMessageRequest ()

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLConnection *urlConnection;

@end

@implementation BackEndMessageRequest

- (void) sendMessage
{
    self.urlRequest = [self getRequest];
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self];    
}

- (NSMutableURLRequest*) getRequest
{
    NSURL *url = [NSURL URLWithString:BACK_END_PUSH_MESSAGE_API];
    NSTimeInterval timeout = BACK_END_PUSH_MESSAGE_TIMEOUT_IN_SECONDS;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [self getURLRequestBodyData];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[self getAuthorizationValue] forHTTPHeaderField:@"Authorization"];
    return urlRequest;
}

- (NSData*) getURLRequestBodyData
{
    NSDictionary *requestDictionary = [self getRequestDictionary];

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&error];
    if (error) {
        PCFPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
    } else {
        return jsonData;
    }
}

- (NSDictionary*) getRequestDictionary
{
    return @{
             @"message":@{ @"body":self.messageBody },
             @"target":@{ @"platforms":self.targetPlatform, @"devices": self.targetDevices },
             };
}

- (NSString*) getAuthorizationValue
{
    NSString *encoded = [self base64String:[NSString stringWithFormat:@"%@:%@", self.envUuid, self.envSecretKey]];
    return [@"Basic " stringByAppendingString:encoded];
}


- (NSString*)base64String:(NSString *)normalString
{
    NSData *plainData = [normalString dataUsingEncoding:NSUTF8StringEncoding];
    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [plainData base64EncodedStringWithOptions:0];
        
    } else {
        return [plainData base64Encoding];
    }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    PCFPushLog(@"Got error when trying to push message via back-end server: %@", error);
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        PCFPushLog(@"Got error when trying to push message via back-end server: server response is not an NSHTTPURLResponse.");
        return;
    }
    
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse*)response;
    
    if (![self isSuccessfulResponseCode:httpURLResponse]) {
        PCFPushLog(@"Got HTTP failure status code when trying to push message via back-end server: %d", httpURLResponse.statusCode);
        return;
    }
    
    PCFPushLog(@"Back-end server has accepted message for delivery");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (BOOL) isSuccessfulResponseCode:(NSHTTPURLResponse*)response
{
    return (response.statusCode >= 200 && response.statusCode < 300);
}

@end
