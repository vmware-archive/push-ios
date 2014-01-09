//
//  OmniaPushRegistrationFailedOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-08.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushRegistrationListener;

@interface OmniaPushRegistrationFailedOperation : NSOperation

- (instancetype) initWithApplication:(UIApplication*)application
                 applicationDelegate:(id<UIApplicationDelegate>)applicationDelegate
                            listener:(id<OmniaPushRegistrationListener>)listener
                               error:(NSError*)error;

@end
