//
//  NSURLConnection+OmniaPushBackEndConnection.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaPushRegistrationParameters;

@interface NSURLConnection (OmniaPushBackEndConnection)

+ (void)omnia_unregisterDeviceID:(NSString *)deviceID
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure;

+ (void)omnia_registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                      devToken:(NSData *)devToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure;


@end
