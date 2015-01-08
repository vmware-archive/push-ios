//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFParameters;

NSString *const kBasicAuthorizationKey;

@interface PCFPushURLConnection : NSObject

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PCFParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure;

+ (void)registerWithParameters:(PCFParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure;

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                            parameters:(PCFParameters *)parameters
                           deviceToken:(NSData *)deviceToken
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSError *error))failure;

@end
