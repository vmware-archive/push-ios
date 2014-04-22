//
//  PCFPushURLConnection.h
//
//
//  Created by DX123-XL on 2014-04-22.
//
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

@interface PCFPushURLConnection : NSObject

+ (void)unregisterDeviceID:(NSString *)deviceID
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure;

+ (void)registerWithParameters:(PCFPushParameters *)parameters
                   deviceToken:(NSData *)deviceToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure;

+ (void)updateRegistrationWithDeviceID:(NSString *)deviceID
                            parameters:(PCFPushParameters *)parameters
                           deviceToken:(NSData *)deviceToken
                               success:(void (^)(NSURLResponse *response, NSData *data))success
                               failure:(void (^)(NSError *error))failure;

@end
