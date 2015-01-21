//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PCFAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, copy) void (^successBlock)(void);
@property (nonatomic, copy) void (^failureBlock)(NSError *error);

@end
