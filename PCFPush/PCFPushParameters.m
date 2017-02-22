//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFHardwareUtil.h"
#import "NSString+Version.h"

#define SERVER_ANALYTICS_VERSION @"1.3.2"

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
    parameters.pushCustomUserId = [PCFPushPersistentStorage customUserId];
    parameters.pushDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    parameters.areGeofencesEnabled = [PCFPushPersistentStorage areGeofencesEnabled];
    return parameters;
}

+ (NSString*) defaultParameterFilename
{
    return @"Pivotal";
}

+ (PCFPushParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFPushParameters *params = [PCFPushParameters parameters];
    
    NSMutableDictionary *platformInfo = [[NSMutableDictionary alloc] init];
    [platformInfo setValue:[PCFPushPersistentStorage pushApiUrl] forKey:@"pushAPIURL"];
    [platformInfo setValue:[PCFPushPersistentStorage productionPushPlatformUuid] forKey:@"productionPushPlatformUUID"];
    [platformInfo setValue:[PCFPushPersistentStorage productionPushPlatformSecret] forKey:@"productionPushPlatformSecret"];
    [platformInfo setValue:[PCFPushPersistentStorage developmentPushPlatformUuid] forKey:@"developmentPushPlatformUUID"];
    [platformInfo setValue:[PCFPushPersistentStorage developmentPushPlatformSecret] forKey:@"developmentPushPlatformSecret"];
    
    if (path) {
        @try {
            NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
            
            // Scan through all of the properties defined in the PCFPushParameters class
            [PCFPushParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
                id propertyValue = [plist valueForKey:plistPropertyName];
                
                // Check if the NSUserDefaults contains an overriding property value.
                // e.g.: if the parameter is "pivotal.push.serviceUrl" then the override property name is "override.pivotal.push.serviceUrl".
                // These property overrides can also be set at runtime using the command line arguments.
                NSString *overridePropertyName = [@"override." stringByAppendingString:(NSString*)plistPropertyName];
                NSString *overridePropertyValue = [[NSUserDefaults standardUserDefaults] valueForKey:overridePropertyName];
                
                if (propertyName && [propertyName isEqualToString:@"sslCertValidationMode"]) {
                    
                    if (overridePropertyValue) {
                        PCFPushLog(@"Using override value %@ for parameter %@", overridePropertyValue, overridePropertyName);
                        propertyValue = overridePropertyValue;
                    }

                   if (!propertyValue || ![propertyValue isKindOfClass:NSString.class] || [propertyValue length] == 0 || [[propertyValue lowercaseString] isEqualToString:@"default"]) {
                       params.sslCertValidationMode = PCFPushSslCertValidationModeSystemDefault;
                   } else if ([[propertyValue lowercaseString] isEqualToString:@"trustall"] || [[propertyValue lowercaseString] isEqualToString:@"trust_all"]) {
                       params.sslCertValidationMode = PCFPushSslCertValidationModeTrustAll;
                   } else if ([[propertyValue lowercaseString] isEqualToString:@"pinned"]) {
                       params.sslCertValidationMode = PCFPushSslCertValidationModePinned;
                   } else if ([[propertyValue lowercaseString] isEqualToString:@"callback"]) {
                       params.sslCertValidationMode = PCFPushSslCertValidationModeCustomCallback;
                   } else {
                       [NSException raise:NSInvalidArgumentException format:@"invalid sslCertValidationMode"];
                   }

                } else if ([propertyName isEqualToString:@"areAnalyticsEnabled"] && (overridePropertyValue || plist[@"pivotal.push.areAnalyticsEnabled"])) {
                    
                    if (overridePropertyValue) {
                        PCFPushLog(@"Using override value %@ for parameter %@", overridePropertyValue, overridePropertyName);
                        params.areAnalyticsEnabled = [overridePropertyValue boolValue];
                    } else {
                        params.areAnalyticsEnabled = [plist[@"pivotal.push.areAnalyticsEnabled"] boolValue];
                    }
                } else {

                    id propertyValue;
                    if (overridePropertyValue) {
                        PCFPushLog(@"Using override value %@ for parameter %@", overridePropertyValue, overridePropertyName);
                        propertyValue = overridePropertyValue;
                    } else {
                        if (platformInfo[propertyName]) {
                            propertyValue = platformInfo[propertyName];
                        } else {
                            propertyValue = plist[plistPropertyName];
                        }
                    }
                    
                    if (propertyValue) {
                        if ([propertyName isEqualToString:@"pinnedSslCertificateNames"] && overridePropertyValue) {
                            PCFPushLog(@"Using override value %@ for parameter %@", overridePropertyValue, overridePropertyName);
                            propertyValue = [overridePropertyValue componentsSeparatedByString:@" "];
                        }

                        if ([propertyValue isKindOfClass:[NSString class]]) {
                            [params setValue:[propertyValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKeyPath:propertyName];

                        } else if ([propertyValue isKindOfClass:[NSArray class]]) {
                            NSArray *inputArray = (NSArray *) propertyValue;
                            NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:inputArray.count];
                            for (NSString *s in inputArray) {
                                [resultArray addObject:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                            }
                            [params setValue:[NSArray arrayWithArray:resultArray] forKeyPath:propertyName];

                        } else {
                            [params setValue:propertyValue forKeyPath:propertyName];
                        }
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
    PCFPushParameters *parameters = [[PCFPushParameters alloc] init];
    parameters.areAnalyticsEnabled = YES;
    return parameters;
}

- (NSString *)variantUUID
{
    return pcfPushIsAPNSSandbox() ? self.developmentPushPlatformUUID : self.productionPushPlatformUUID;
}

- (NSString *)variantSecret
{
    return pcfPushIsAPNSSandbox() ? self.developmentPushPlatformSecret : self.productionPushPlatformSecret;
}

- (BOOL)arePushParametersValid;
{
    __block BOOL result = YES;

    [PCFPushParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {

        if ([propertyName isEqualToString:@"pinnedSslCertificateNames"]) {
            id propertyValue = [self valueForKeyPath:propertyName];
            if (!propertyValue || [propertyValue isKindOfClass:[NSArray class]]) {
                return;
            }
            PCFPushCriticalLog(@"pinnedSslCertificateNames must be an array, if present");
            result = NO;
            *stop = YES;
            return;
        }

        id propertyValue = [self valueForKeyPath:propertyName];
        if (!propertyValue || ([propertyValue respondsToSelector:@selector(length)] && [propertyValue length] <= 0)) {
            PCFPushCriticalLog(@"PCFPushParameters failed validation caused by an invalid parameter %@.", propertyName);
            result = NO;
            *stop = YES;
        }
    }];

    if (!result) {
        return result;
    }

    if (self.sslCertValidationMode == PCFPushSslCertValidationModePinned && (!self.pinnedSslCertificateNames || [self.pinnedSslCertificateNames count] == 0)) {
        PCFPushCriticalLog(@"Error: could not find any pinned SSL certificate filenames in the settings. Please provide them in your pivotal.plist file.");
        return NO;
    }

    if (self.pushCustomUserId && self.pushCustomUserId.length > 255) {
        PCFPushCriticalLog(@"pushCustomUserId must have a length of fewer than or equal to 255, if present");
        return NO;
    }

    return YES;
}

+ (void) enumerateParametersWithBlock:(void (^)(id plistPropertyName, id propertyName, BOOL *stop))block
{
    static NSDictionary *keys = nil;
    if (!keys) {

        // List of all parameters in the Pivotal.plist file only.

        keys = @{
                @"pivotal.push.serviceUrl" : @"pushAPIURL",
                @"pivotal.push.platformUuidProduction" : @"productionPushPlatformUUID",
                @"pivotal.push.platformSecretProduction" : @"productionPushPlatformSecret",
                @"pivotal.push.platformUuidDevelopment" : @"developmentPushPlatformUUID",
                @"pivotal.push.platformSecretDevelopment" : @"developmentPushPlatformSecret",
                @"pivotal.push.areAnalyticsEnabled" : @"areAnalyticsEnabled",
                @"pivotal.push.sslCertValidationMode" : @"sslCertValidationMode",
                @"pivotal.push.pinnedSslCertificateNames" : @"pinnedSslCertificateNames"
        };
    }
    if (block) {
        [keys enumerateKeysAndObjectsUsingBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
            block(plistPropertyName, propertyName, stop);
        }];
    }
}

- (BOOL) areAnalyticsEnabledAndAvailable
{
    if (!self.areAnalyticsEnabled) {
        return NO;
    }

    NSString *serverVersion = [PCFPushPersistentStorage serverVersion];
    if (!serverVersion) {
        return NO;
    }

    return [serverVersion isNewerOrSameVersionThan:SERVER_ANALYTICS_VERSION];
}

@end
