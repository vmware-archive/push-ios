//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushErrors.h"
#import "OmniaPushRegistrationParameters.h"

@protocol OmniaPushRegistrationListener;

@interface OmniaPushSDK : NSObject

+ (OmniaPushSDK*) registerWithParameters:(OmniaPushRegistrationParameters*)parameters;
+ (OmniaPushSDK*) registerWithParameters:(OmniaPushRegistrationParameters*)parameters listener:(id<OmniaPushRegistrationListener>)listener;

@end
