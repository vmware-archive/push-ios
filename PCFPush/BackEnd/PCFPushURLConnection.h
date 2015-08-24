//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

extern NSString *const kPCFPushBasicAuthorizationKey;

@interface PCFPushURLConnection : NSObject

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PCFPushParameters *)parameters
                   success:(void (^)(NSURLResponse *, NSData *))success
                   failure:(void (^)(NSError *))failure;

+ (void)registerWithParameters:(PCFPushParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *, NSData *))success
                       failure:(void (^)(NSError *))failure;

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                            parameters:(PCFPushParameters *)parameters
                           deviceToken:(NSData *)deviceToken
                               success:(void (^)(NSURLResponse *, NSData *))success
                               failure:(void (^)(NSError *))failure;

+ (void)geofenceRequestWithParameters:(PCFPushParameters *)parameters
                            timestamp:(int64_t)timestamp
                           deviceUuid:(NSString *)deviceUuid
                              success:(void (^)(NSURLResponse *, NSData *))success
                              failure:(void (^)(NSError *))failure;

+ (void)analyticsRequestWithEvents:(NSArray*)events
                        parameters:(PCFPushParameters *)parameters
                           success:(void (^)(NSURLResponse *, NSData *))success
                           failure:(void (^)(NSError *))failure;

+ (void)versionRequestWithParameters:(PCFPushParameters *)parameters
                             success:(void (^)(NSURLResponse *, NSData *))success
                          oldVersion:(void (^)())oldVersion
                    retryableFailure:(void (^)(NSError *))retryableFailure
                        fatalFailure:(void (^)(NSError *))fatalFailure;

@end
