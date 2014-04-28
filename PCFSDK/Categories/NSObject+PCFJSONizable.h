//
//  NSObject+PCFJsonizable.h
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (PCFJSONizable)

+ (instancetype)pcf_fromJSONData:(NSData *)JSONData error:(NSError **)error;
- (NSData *)pcf_toJSONData:(NSError **)error;

+ (instancetype)pcf_fromDictionary:(NSDictionary *)dict;
- (id)pcf_toFoundationType;

@end
