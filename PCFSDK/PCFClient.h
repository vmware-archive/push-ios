//
//  PCFClient.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <Foundation/Foundation.h>

@class PCFParameters, PCFAppDelegateProxy, PCFAppDelegate;

@interface PCFClient : NSObject

@property PCFParameters *registrationParameters;
@property PCFAppDelegateProxy *appDelegateProxy;

+ (instancetype)shared;
+ (void)resetSharedClient;

- (PCFAppDelegate *)swapAppDelegate;

@end
