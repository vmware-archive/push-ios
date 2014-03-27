//
//  CFAppDelegateProxy.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CFAppDelegateProxy : NSProxy<UIApplicationDelegate>

@property NSObject<UIApplicationDelegate> *cfAppDelegate;
@property NSObject<UIApplicationDelegate> *originalAppDelegate;

- (id)init;

@end
