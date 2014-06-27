//
//  MSSJSONValueTransformer.m
//  
//
//  Created by DX123-XL on 2014-04-02.
//
//

#import "MSSJSONValueTransformer.h"

@implementation MSSJSONValueTransformer

+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(NSDictionary *)value
{
    return [NSJSONSerialization dataWithJSONObject:value
                                           options:NSJSONWritingPrettyPrinted
                                             error:nil];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSJSONSerialization JSONObjectWithData:value
                                           options:NSJSONReadingMutableContainers
                                             error:nil];
}

@end
