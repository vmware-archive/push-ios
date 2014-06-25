//
//  PMSSPushURLConnection.h
//
//
//  Created by DX123-XL on 2014-04-22.
//
//

#import <Foundation/Foundation.h>

@class PMSSParameters;

NSString *const kBasicAuthorizationKey;

@interface PMSSPushURLConnection : NSObject

+ (void)unregisterDeviceID:(NSString *)deviceID
                parameters:(PMSSParameters *)parameters
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure;

+ (void)registerWithParameters:(PMSSParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure;

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                            parameters:(PMSSParameters *)parameters
                           deviceToken:(NSData *)deviceToken
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSError *error))failure;

@end
