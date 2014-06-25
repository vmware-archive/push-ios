//
//  PMSSAppDelegateProxy.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PMSSAppDelegateProxy : NSProxy <UIApplicationDelegate>

@property NSObject<UIApplicationDelegate> *swappedAppDelegate;
@property NSObject<UIApplicationDelegate> *originalAppDelegate;

- (id)init;

@end
