//
//  BackEndMessageRequest.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BackEndMessageRequest : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic) NSString *envUuid;
@property (nonatomic) NSString *envSecretKey;
@property (nonatomic) NSString *messageBody;
@property (nonatomic) NSString *targetPlatform;
@property (nonatomic) NSArray *targetDevices;

- (void) sendMessage;

@end
