//
//  PCFPushAppDelegateProxy.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PCFPushAppDelegateProxy : NSProxy<UIApplicationDelegate>

@property (nonatomic, strong) NSObject<UIApplicationDelegate> *pushAppDelegate;
@property (nonatomic, strong) NSObject<UIApplicationDelegate> *originalAppDelegate;

- (id)init;

@end
