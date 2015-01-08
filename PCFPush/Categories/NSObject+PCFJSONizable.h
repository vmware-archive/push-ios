//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PCFJSONizable)

+ (instancetype)pcf_fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)pcf_toJSONData:(NSError **)error;

+ (instancetype)pcf_fromDictionary:(NSDictionary *)dict;
- (id)pcf_toFoundationType;

@end
