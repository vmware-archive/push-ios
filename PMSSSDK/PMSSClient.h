//
//  PMSSClient.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <Foundation/Foundation.h>

@class PMSSParameters, PMSSAppDelegateProxy, PMSSAppDelegate;

@interface PMSSClient : NSObject

@property PMSSParameters *registrationParameters;
@property PMSSAppDelegateProxy *appDelegateProxy;

+ (instancetype)shared;
+ (void)resetSharedClient;

- (PMSSAppDelegate *)swapAppDelegate;

@end
