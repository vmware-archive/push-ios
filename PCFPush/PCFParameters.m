//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFParameters.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"

#ifdef DEBUG
static BOOL kInDebug = YES;
#else
static BOOL kInDebug = NO;
#endif

@implementation PCFParameters

+ (PCFParameters *)defaultParameters
{
    PCFParameters *parameters = [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[PCFParameters defaultParameterFilename] ofType:@"plist"]];
    parameters.pushTags = [PCFPushPersistentStorage tags];
    parameters.pushDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    return parameters;
}

+ (NSString*) defaultParameterFilename
{
    return @"PCFParameters";
}

+ (void) enumerateParameters:(id)parameters withBlock:(void (^)(id propertyName, id propertyValue, BOOL *stop))block
{
    static NSArray *selectors = nil;
    if (!selectors) {
        selectors = @[
                @"pushAPIURL",
                @"developmentPushVariantUUID",
                @"developmentPushVariantSecret",
                @"productionPushVariantUUID",
                @"productionPushVariantSecret"
        ];
    }
    if (block) {
        [selectors enumerateObjectsUsingBlock:^(id propertyName, NSUInteger idx, BOOL *stop) {
            id propertyValue = [parameters valueForKey:propertyName];
            block(propertyName, propertyValue, stop);
        }];
    }
}

+ (PCFParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFParameters *params = [PCFParameters parameters];
    if (path) {
        @try {
            NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
            [PCFParameters enumerateParameters:plist withBlock:^(id propertyName, id propertyValue, BOOL *stop) {
                if (propertyValue) {
                    [params setValue:propertyValue forKeyPath:propertyName];
                }
            }];
        } @catch (NSException *exception) {
            PCFPushLog(@"Exception while populating PCFParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (PCFParameters *)parameters
{
    return [[self alloc] init];
}

- (NSString *)variantUUID
{
    return kInDebug ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)variantSecret
{
    return kInDebug ? self.developmentPushVariantSecret : self.productionPushVariantSecret;
}

- (BOOL)arePushParametersValid;
{
    __block BOOL result = YES;

    [PCFParameters enumerateParameters:self withBlock:^(id propertyName, id propertyValue, BOOL *stop) {
        if (!propertyValue || ([propertyValue respondsToSelector:@selector(length)] && [propertyValue length] <= 0)) {
            PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", propertyName);
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}

@end
