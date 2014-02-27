//
//  OmniaPushJsonizable.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushJsonizable <NSObject>

+ (instancetype) fromJsonData:(NSData*)jsonData error:(NSError**)error;
- (NSData*) toJsonData;

@end
