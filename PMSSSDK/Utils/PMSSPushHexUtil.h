//
//  PMSSPushHexUtil.h
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMSSPushHexUtil : NSObject

+ (NSString *)hexDumpForData:(NSData *)data;

@end
