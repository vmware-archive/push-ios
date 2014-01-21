//
//  OmniaPushJsonizable.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushJsonizable <NSObject>

- (NSData*) toJsonData;

@end