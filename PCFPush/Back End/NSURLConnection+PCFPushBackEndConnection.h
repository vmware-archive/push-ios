//
//  NSURLConnection+PCFPushBackEndConnection.h
//  PCFPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

@interface NSURLConnection (PCFPushBackEndConnection)

+ (void)cf_unregisterDeviceID:(NSString *)deviceID
                      success:(void (^)(NSURLResponse *response, NSData *data))success
                      failure:(void (^)(NSError *error))failure;

+ (void)cf_registerWithParameters:(PCFPushParameters *)parameters
                         devToken:(NSData *)devToken
                          success:(void (^)(NSURLResponse *response, NSData *data))success
                          failure:(void (^)(NSError *error))failure;


+ (void)cf_syncAnalyicEvents:(NSArray *)events
                 forDeviceID:(NSString *)deviceID
                     success:(void (^)(NSURLResponse *response, NSData *data))success
                     failure:(void (^)(NSError *error))failure;
@end
