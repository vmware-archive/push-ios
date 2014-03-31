//
//  NSObject+PCFPushJsonizable.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (PCFPushJsonizable)

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)toJSONData:(NSError **)error;

+ (instancetype)fromDictionary:(NSDictionary *)dict;
- (id)toFoundationType;

@end
