//
//  CFPushDictionaryizable.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CFPushDictionaryizable <NSObject>

+ (instancetype)fromDictionary:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;

@end
