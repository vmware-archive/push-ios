//
//  OmniaPushJsonizable.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushJsonizable <NSObject>

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)toJSONData;

@end
