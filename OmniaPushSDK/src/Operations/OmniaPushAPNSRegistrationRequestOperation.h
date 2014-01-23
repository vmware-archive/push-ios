//
//  OmniaPushAPNSRegistrationRequestOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-19.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;

@interface OmniaPushAPNSRegistrationRequestOperation : NSOperation

@property (nonatomic, readonly) OmniaPushRegistrationParameters *parameters;
@property (nonatomic, readonly) UIApplication *application;

- (instancetype) initWithParameters:(OmniaPushRegistrationParameters*)parameters
                        application:(UIApplication*)application;

@end
