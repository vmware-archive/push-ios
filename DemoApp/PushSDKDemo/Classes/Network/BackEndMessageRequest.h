//
//  BackEndMessageRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BackEndMessageRequest : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic) NSString *appUuid;
@property (nonatomic) NSString *appSecretKey;
@property (nonatomic) NSString *messageTitle;
@property (nonatomic) NSString *messageBody;
@property (nonatomic) NSString *targetPlatform;
@property (nonatomic) NSArray *targetDevices;

- (void) sendMessage;

@end
