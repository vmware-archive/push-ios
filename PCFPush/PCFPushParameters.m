//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFHardwareUtil.h"

static dispatch_once_t onceToken;

BOOL pcfPushIsAPNSSandbox() {
    static BOOL didLoadFile = NO;
    static BOOL isAPNSSandbox = NO;
    dispatch_once(&onceToken, ^{
        @try {

            if ([PCFHardwareUtil isSimulator]) {
                didLoadFile = YES;
                isAPNSSandbox = YES;
                PCFPushCriticalLog(@"WARNING: pcfPushIsAPNSSandbox: running on simulator! push notifications will probably not work.");
                return;
            }

            // **IMPORTANT** There is no provisioning profile in AppStore Apps.
            NSData *data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]];
            if (data) {
                const char *bytes = [data bytes];
                NSMutableString *profile = [[NSMutableString alloc] initWithCapacity:data.length];
                for (NSUInteger i = 0; i < data.length; i++) {
                    [profile appendFormat:@"%c", bytes[i]];
                }
                // Look for debug value, if detected we're a development build.
                NSString *cleared = [[profile componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
                isAPNSSandbox = [cleared rangeOfString:@"<key>aps-environment</key><string>development</string>"].length > 0;
                didLoadFile = YES;
            }
            PCFPushLog(@"pcfPushIsAPNSSandbox: %d.", isAPNSSandbox);
        }
        @finally
        {
            // If some other kind of crash happened then something crazy must have happened.  Let's assume
            // that crazy things usually happen to people in production.
            if (!didLoadFile) {
                PCFPushLog(@"WARNING: Did not load provisioning file correctly. Assuming production build.");
                isAPNSSandbox = NO;
            }
        }
    });
    return isAPNSSandbox;
}

void pcfPushResetOnceToken() {
    onceToken = 0;
}

@implementation PCFPushParameters

+ (PCFPushParameters *)defaultParameters
{
    PCFPushParameters *parameters = [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[PCFPushParameters defaultParameterFilename] ofType:@"plist"]];
    parameters.pushTags = [PCFPushPersistentStorage tags];
    parameters.pushDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    return parameters;
}

+ (NSString*) defaultParameterFilename
{
    return @"Pivotal";
}

+ (PCFPushParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFPushParameters *params = [PCFPushParameters parameters];
    if (path) {
        @try {
            NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
            [PCFPushParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
                id propertyValue = [plist valueForKey:plistPropertyName];
                if (propertyValue) {

                    if ([propertyValue isKindOfClass:[NSString class]]) {
                        [params setValue:[propertyValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKeyPath:propertyName];

                    } else if ([propertyValue isKindOfClass:[NSArray class]]) {
                        NSArray *inputArray = (NSArray*) propertyValue;
                        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:inputArray.count];
                        for (NSString *s in inputArray) {
                            [resultArray addObject:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                        }
                        [params setValue:[NSArray arrayWithArray:resultArray] forKeyPath:propertyName];

                    } else {
                        [params setValue:propertyValue forKeyPath:propertyName];
                    }

                }
            }];
        } @catch (NSException *exception) {
            PCFPushCriticalLog(@"Exception while populating PCFPushParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (PCFPushParameters *)parameters
{
    return [[self alloc] init];
}

- (NSString *)variantUUID
{
    return pcfPushIsAPNSSandbox() ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)variantSecret
{
    return pcfPushIsAPNSSandbox() ? self.developmentPushVariantSecret : self.productionPushVariantSecret;
}

- (BOOL)arePushParametersValid;
{
    __block BOOL result = YES;

    [PCFPushParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {

        if ([propertyName isEqualToString:@"pinnedSSLCertificateNames"]) {
            id propertyValue = [self valueForKeyPath:propertyName];
            if (!propertyValue || [propertyValue isKindOfClass:[NSArray class]]) {
                return;
            }
            PCFPushCriticalLog(@"pinnedSSLCertificateNames must be an array, if present");
            result = NO;
            *stop = YES;
            return;
        }

        if ([propertyName isEqualToString:@"trustAllSSLCertificates"]) {
            return;
        }

        id propertyValue = [self valueForKeyPath:propertyName];
        if (!propertyValue || ([propertyValue respondsToSelector:@selector(length)] && [propertyValue length] <= 0)) {
            PCFPushCriticalLog(@"PCFPushParameters failed validation caused by an invalid parameter %@.", propertyName);
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}

+ (void) enumerateParametersWithBlock:(void (^)(id plistPropertyName, id propertyName, BOOL *stop))block
{
    static NSDictionary *keys = nil;
    if (!keys) {
        keys = @{
                @"pivotal.push.serviceUrl" : @"pushAPIURL",
                @"pivotal.push.platformUuidProduction" : @"productionPushVariantUUID",
                @"pivotal.push.platformSecretProduction" : @"productionPushVariantSecret",
                @"pivotal.push.platformUuidDevelopment" : @"developmentPushVariantUUID",
                @"pivotal.push.platformSecretDevelopment" : @"developmentPushVariantSecret",
                @"pivotal.push.geofencesEnabled" : @"areGeofencesEnabled",
                @"pivotal.push.trustAllSSLCertificates" : @"trustAllSSLCertificates",
                @"pivotal.push.pinnedSSLCertificateNames" : @"pinnedSSLCertificateNames"
        };
    }
    if (block) {
        [keys enumerateKeysAndObjectsUsingBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
            block(plistPropertyName, propertyName, stop);
        }];
    }
}

@end
