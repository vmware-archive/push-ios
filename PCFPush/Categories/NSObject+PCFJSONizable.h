//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PCFJSONizable)

+ (instancetype)pcfPushFromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)pcfPushToJSONData:(NSError **)error;

+ (instancetype)pcfPushFromDictionary:(NSDictionary *)dict;
- (id)pcfPushToFoundationType;

@end
