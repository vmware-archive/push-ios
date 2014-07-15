//
//  MSSClient.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
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
