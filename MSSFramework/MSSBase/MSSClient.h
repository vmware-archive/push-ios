//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSSParameters, MSSAppDelegateProxy, MSSAppDelegate;

@interface MSSClient : NSObject

@property MSSParameters *registrationParameters;
@property MSSAppDelegateProxy *appDelegateProxy;

+ (instancetype)shared;
+ (void)resetSharedClient;

- (MSSAppDelegate *)swapAppDelegate;

@end
