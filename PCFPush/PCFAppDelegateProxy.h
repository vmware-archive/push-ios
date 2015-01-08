//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PCFAppDelegateProxy : NSProxy <UIApplicationDelegate>

@property NSObject<UIApplicationDelegate> *swappedAppDelegate;
@property NSObject<UIApplicationDelegate> *originalAppDelegate;

- (id)init;

@end
