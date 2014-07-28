//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MSSJSONizable)

+ (instancetype)mss_fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)mss_toJSONData:(NSError **)error;

+ (instancetype)mss_fromDictionary:(NSDictionary *)dict;
- (id)mss_toFoundationType;

@end
