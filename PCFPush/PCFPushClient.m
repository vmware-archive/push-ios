//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import <CoreLocation/CoreLocation.h>

#import "PCFPushDebug.h"
#import "PCFPushClient.h"
#import "PCFPushErrors.h"
#import "PCFPushAnalytics.h"
#import "PCFNotifications.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushParameters.h"
#import "PCFPushURLConnection.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushGeofenceUpdater.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceHandler.h"
#import "PCFPushApplicationUtil.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushRegistrationResponseData.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushAnalyticsEvent.h"

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

static PCFPushClient *_sharedPCFPushClient;
static dispatch_once_t _sharedPCFPushClientToken;
static NSString const* kPCFPushGeofenceUpdateAvailable = @"pivotal.push.geofence_update_available";

BOOL hasAlreadyReceivedNotification(NSString *receiptId)
{
    NSString *entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
    NSString *s = [NSString stringWithFormat:@"receiptId == '%@' AND eventType == '%@'", receiptId, PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:s];

    NSArray *events = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:predicate];
    return events.count > 0;
}

static BOOL isGeofenceUpdate(NSDictionary* userInfo)
{
    BOOL isContentAvailable = [userInfo[@"aps"][@"content-available"] intValue] == 1;
    id i = userInfo[kPCFPushGeofenceUpdateAvailable];
    BOOL isGeofenceUpdateAvailable = i != nil && (([i isKindOfClass:[NSString class]] && [i isEqualToString:@"true"])
            || ([i isKindOfClass:[NSNumber class]] && [i boolValue]));
    return isContentAvailable && isGeofenceUpdateAvailable;
}

@implementation PCFPushClient

+ (instancetype)shared
{
    dispatch_once(&_sharedPCFPushClientToken, ^{
        if (!_sharedPCFPushClient) {
            _sharedPCFPushClient = [[PCFPushClient alloc] init];
        }
    });
    return _sharedPCFPushClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.registrationParameters = [PCFPushParameters defaultParameters];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.registrar = [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:self.locationManager];
        self.store = [[PCFPushGeofencePersistentStore alloc] initWithFileManager:[NSFileManager defaultManager]];
        self.engine = [[PCFPushGeofenceEngine alloc] initWithRegistrar:self.registrar store:self.store];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)registerWithPCFPushWithDeviceToken:(NSData *)deviceToken
                                   success:(void (^)(void))successBlock
                                   failure:(void (^)(NSError *))failureBlock
{
    if (!self.registrationParameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    if (![self.registrationParameters arePushParametersValid]) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters are not valid. See log for more info."];
    }

    if (!deviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token cannot not be nil."];
    }

    if (![deviceToken isKindOfClass:[NSData class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token type does not match expected type: NSData."];
    }

    if ([PCFPushClient isClearGeofencesRequired:self.registrationParameters]) {
        [PCFPushGeofenceUpdater clearAllGeofences:self.engine];
        [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
    }

    if ([PCFPushClient updateRegistrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:self.registrationParameters
                                                                                 deviceToken:deviceToken
                                                                                     success:successBlock
                                                                                     failure:failureBlock];

        [PCFPushURLConnection updateRegistrationWithDeviceID:[PCFPushPersistentStorage serverDeviceID]
                                                  parameters:self.registrationParameters
                                                 deviceToken:deviceToken
                                                     success:registrationBlock
                                                     failure:failureBlock];

    } else if ([PCFPushClient registrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        [PCFPushClient sendRegisterRequestWithParameters:self.registrationParameters
                                             deviceToken:deviceToken
                                                 success:successBlock
                                                 failure:failureBlock];

    } else if ([PCFPushClient isGeofenceUpdateRequired:self.registrationParameters]) {

        [PCFPushClient startGeofenceUpdateWithTags:self.registrationParameters.pushTags successBlock:^{

            [PCFPushPersistentStorage setAreGeofencesEnabled:YES];

            if (successBlock) {
                successBlock();
            }

        } failure:failureBlock];

    } else {
        PCFPushLog(@"Registration with PCF Push is being bypassed (already registered).");
        if (successBlock) {
            successBlock();
        }
    }
}

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure
{
    if ([PCFPushPersistentStorage lastGeofencesModifiedTime] != PCF_NEVER_UPDATED_GEOFENCES ) {
        [PCFPushGeofenceUpdater clearAllGeofences:self.engine];
    }
    [PCFPushPersistentStorage setAreGeofencesEnabled:NO];

    NSString *deviceId = [PCFPushPersistentStorage serverDeviceID];
    if (!deviceId || deviceId.length <= 0) {
        PCFPushLog(@"Not currently registered.");
        [self handleUnregistrationSuccess:success userInfo:@{ @"Response": @"Already unregistered."}];
        return;
    }

    [PCFPushURLConnection unregisterDeviceID:deviceId
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {

                                         [self handleUnregistrationSuccess:success userInfo:@{@"URLResponse" : response}];
                                     }
                                     failure:failure];
}

- (void) handleUnregistrationSuccess:(void (^)(void))success userInfo:(NSDictionary*)userInfo
{
    [PCFPushPersistentStorage reset];
    
    if (success) {
        success();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushUnregisterNotification object:self userInfo:userInfo];
}

+ (RegistrationBlock)registrationBlockWithParameters:(PCFPushParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            PCFPushCriticalLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        PCFPushRegistrationResponseData *parsedData = [PCFPushRegistrationResponseData pcfPushFromJSONData:responseData error:&error];
        
        if (error) {
            PCFPushCriticalLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            PCFPushCriticalLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }

        BOOL areTagsTheSame = [PCFPushClient areTagsTheSame:parameters];

        PCFPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [PCFPushPersistentStorage setAPNSDeviceToken:deviceToken];
        [PCFPushPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [PCFPushPersistentStorage setVariantUUID:parameters.variantUUID];
        [PCFPushPersistentStorage setVariantSecret:parameters.variantSecret];
        [PCFPushPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        [PCFPushPersistentStorage setTags:parameters.pushTags];

        if (!parameters.areGeofencesEnabled) {
            [PCFPushPersistentStorage setAreGeofencesEnabled:NO];
        }

        if ([PCFPushClient isGeofenceUpdateRequired:parameters]) {

            [PCFPushClient startGeofenceUpdateWithTags:parameters.pushTags successBlock:^{

                [PCFPushPersistentStorage setAreGeofencesEnabled:YES];

                if (successBlock) {
                    successBlock();
                }

            } failure:failureBlock];

        } else {
            
            if (parameters.areGeofencesEnabled && !areTagsTheSame) {
                [PCFPushGeofenceHandler reregisterGeofencesWithEngine:PCFPushClient.shared.engine subscribedTags:parameters.pushTags];
            }

            if (successBlock) {
                successBlock();
            }
        }

        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:PCFPushRegistrationSuccessNotification object:self userInfo:userInfo];
    };
    
    return registrationBlock;
}

+ (void)startGeofenceUpdateWithTags:(NSSet *)subscribedTags
                       successBlock:(void (^)())successBlock
                            failure:(void (^)(NSError *))failureBlock
{
    [PCFPushGeofenceUpdater startGeofenceUpdate:PCFPushClient.shared.engine userInfo:nil timestamp:0L tags:subscribedTags success:^{

        if (successBlock) {
            successBlock();
        }

    } failure:^(NSError *error) {

        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

- (void) subscribeToTags:(NSSet *)tags deviceToken:(NSData *)deviceToken deviceUuid:(NSString *)deviceUuid success:(void (^)(void))success failure:(void (^)(NSError*))failure
{
    self.registrationParameters.pushTags = tags;

    if ([PCFPushClient isClearGeofencesRequired:self.registrationParameters]) {
        [PCFPushGeofenceUpdater clearAllGeofences:self.engine];
    }

    if ([PCFPushClient areTagsTheSame:self.registrationParameters]) {

        // No tags are updated - just check if want to update geofences
        if ([PCFPushClient isGeofenceUpdateRequired:self.registrationParameters]) {

            [PCFPushClient startGeofenceUpdateWithTags:tags successBlock:success failure:failure];

        } else if (success) {
            success();
        }

    } else {

        // Tags have been updated - a registration request to the server will be required
        RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:self.registrationParameters
                                                                                 deviceToken:deviceToken
                                                                                     success:success
                                                                                     failure:failure];

        [PCFPushURLConnection updateRegistrationWithDeviceID:deviceUuid
                                                  parameters:self.registrationParameters
                                                 deviceToken:deviceToken
                                                     success:registrationBlock
                                                     failure:failure];
    }
}

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [PCFPushClient registrationBlockWithParameters:parameters
                                                                             deviceToken:deviceToken
                                                                                 success:successBlock
                                                                                 failure:failureBlock];
    [PCFPushURLConnection registerWithParameters:parameters
                                     deviceToken:deviceToken
                                         success:registrationBlock
                                         failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PCFPushPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![PCFPushClient localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![PCFPushClient localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDeviceToken:(NSData *)deviceToken
                                parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPushPersistentStorage serverDeviceID]) {
        return YES;
    }

    if (![PCFPushClient localVariantMatchNewVariant:parameters]) {
        return YES;
    }

    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(PCFPushParameters *)parameters
{
    NSString *savedDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    if ((parameters.pushDeviceAlias == nil && savedDeviceAlias != nil) || (parameters.pushDeviceAlias != nil && ![parameters.pushDeviceAlias isEqualToString:savedDeviceAlias])) {
        PCFPushLog(@"Parameters specify a different deviceAlias. Update registration will be required.");
        return NO;
    }
    
    return [PCFPushClient areTagsTheSame:parameters];
}

+ (BOOL)localVariantMatchNewVariant:(PCFPushParameters *)parameters
{
    NSString *savedVariantUUID = [PCFPushPersistentStorage variantUUID];
    if ((parameters.variantUUID == nil && savedVariantUUID != nil) || (parameters.variantUUID != nil && ![parameters.variantUUID isEqualToString:savedVariantUUID])) {
        PCFPushLog(@"Parameters specify a different platform UUID. A new registration will be required.");
        return NO;
    }

    NSString *savedVariantSecret = [PCFPushPersistentStorage variantSecret];
    if ((parameters.variantSecret == nil && savedVariantSecret != nil) || (parameters.variantSecret != nil && ![parameters.variantSecret isEqualToString:savedVariantSecret])) {
        PCFPushLog(@"Parameters specify a different platform Secret. A new registration will be required.");
        return NO;
    }

    return YES;
}

+ (BOOL)areTagsTheSame:(PCFPushParameters *)parameters
{
    NSSet *savedTags = [PCFPushPersistentStorage tags];
    BOOL areSavedTagsNilOrEmpty = savedTags == nil || savedTags.count == 0;
    BOOL areNewTagsNilOrEmpty = parameters.pushTags == nil || parameters.pushTags.count == 0;
    if ((areNewTagsNilOrEmpty && !areSavedTagsNilOrEmpty) || (!areNewTagsNilOrEmpty && ![parameters.pushTags isEqualToSet:savedTags])) {
        PCFPushLog(@"Parameters specify a different set of tags. Update registration will be required.");
        return NO;
    }
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken
{
    if (![deviceToken isEqualToData:[PCFPushPersistentStorage APNSDeviceToken]]) {
        PCFPushLog(@"APNS returned a different APNS token. Update registration will be required.");
        return NO;
    }
    return YES;
}

+ (BOOL)isGeofenceUpdateRequired: (PCFPushParameters *)parameters
{
    return parameters.areGeofencesEnabled && ([PCFPushPersistentStorage lastGeofencesModifiedTime] == PCF_NEVER_UPDATED_GEOFENCES || ![PCFPushClient localVariantMatchNewVariant:parameters]);
}

+ (BOOL)isClearGeofencesRequired: (PCFPushParameters *)parameters
{
    return [PCFPushPersistentStorage lastGeofencesModifiedTime] != PCF_NEVER_UPDATED_GEOFENCES && (![PCFPushClient localVariantMatchNewVariant:parameters] || !parameters.areGeofencesEnabled);
}

#pragma mark - Helpers for unit tests

- (void)resetInstance
{
    self.registrationParameters = nil;
    self.locationManager = nil;
    self.registrar = nil;
    self.store = nil;
    self.engine = nil;
}

+ (void)resetSharedClient
{
    if (_sharedPCFPushClient) {
        [_sharedPCFPushClient resetInstance];
    }

    _sharedPCFPushClientToken = 0;
    _sharedPCFPushClient = nil;
}

#pragma mark - Handling remote notifications

- (void)didReceiveRemoteNotification:(NSDictionary*)userInfo
                   completionHandler:(void (^)(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error))handler
{
    if (!handler) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"handler may not be nil" userInfo:nil];
    }

    if (self.registrationParameters.areGeofencesEnabled && isGeofenceUpdate(userInfo)) {

        int64_t timestamp = [PCFPushPersistentStorage lastGeofencesModifiedTime];
        [PCFPushGeofenceUpdater startGeofenceUpdate:self.engine userInfo:userInfo timestamp:timestamp tags:self.registrationParameters.pushTags success:^{

            handler(NO, UIBackgroundFetchResultNewData, nil);

        } failure:^(NSError *error) {

            handler(NO, UIBackgroundFetchResultFailed, error);

        }];

    } else {

        NSString *receiptId = userInfo[@"receiptId"];
        
        if (receiptId) {

            UIApplicationState applicationState = PCFPushApplicationUtil.applicationState;

            if (applicationState == UIApplicationStateBackground || applicationState == UIApplicationStateActive) {

                [PCFPushAnalytics logReceivedRemoteNotification:receiptId parameters:self.registrationParameters];

            } else if (applicationState == UIApplicationStateInactive) {

                if (!hasAlreadyReceivedNotification(receiptId)) {
                    [PCFPushAnalytics logReceivedRemoteNotification:receiptId parameters:self.registrationParameters];
                }
                [PCFPushAnalytics logOpenedRemoteNotification:receiptId parameters:self.registrationParameters];
            }
        }

        handler(YES, UIBackgroundFetchResultNoData, nil);
    }
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if (!self.registrationParameters.areGeofencesEnabled) {
        return;
    }

    PCFPushLog(@"locationManager:didExitRegion %@", region.identifier);
    [PCFPushGeofenceHandler processRegion:region store:self.store engine:self.engine state:CLRegionStateOutside parameters:self.registrationParameters];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (!self.registrationParameters.areGeofencesEnabled) {
        return;
    }

    if (![manager.monitoredRegions containsObject:region]) {
        PCFPushLog(@"Location %@ is no longer being monitored. Ignoring state update.", region.identifier);
        return;
    }

    NSString *s = @"N/A";
    switch(state) {
        case CLRegionStateUnknown:
            s = @"Unknown";
            break;
        case CLRegionStateInside:
            s = @"Inside";
            break;
        case CLRegionStateOutside:
            s = @"Outside";
            break;
    }
    PCFPushLog(@"locationManager:didDetermineState (%@) forRegion: %@", s, region.identifier);

    if (state == CLRegionStateInside) {
        // Device entered geofence. Trigger notification.
        [PCFPushGeofenceHandler processRegion:region store:self.store engine:self.engine state:CLRegionStateInside parameters:self.registrationParameters];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    PCFPushCriticalLog(@"Started monitoring region '%@'. Total number of monitored geofence locations: %d", region.identifier, self.locationManager.monitoredRegions.count);
}

#pragma mark - Analytics

- (void)cleanEventsDatabase:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    [PCFPushAnalyticsStorage.shared.managedObjectContext performBlockAndWait:^{

        NSArray *postingErrorEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPostingError];
        if (postingErrorEvents && postingErrorEvents.count > 0) {
            [PCFPushAnalyticsStorage.shared setEventsStatus:postingErrorEvents status:PCFPushEventStatusNotPosted];
        }

        NSArray *postingEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosting];
        if (postingEvents && postingEvents.count > 0) {
            [PCFPushAnalyticsStorage.shared setEventsStatus:postingEvents status:PCFPushEventStatusNotPosted];
        }
    }];
}

- (void)sendEventsWithParameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    [PCFPushAnalyticsStorage.shared.managedObjectContext performBlockAndWait:^{
        
        NSArray *events = PCFPushAnalyticsStorage.shared.unpostedEvents;

        if (events && events.count > 0) {
            [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPosting];

            [PCFPushURLConnection analyticsRequestWithEvents:events parameters:parameters success:^(NSURLResponse *response, NSData *data) {

                PCFPushLog(@"Posted %d analytics events to the server successfully.", events.count);
                [PCFPushAnalyticsStorage.shared deleteManagedObjects:events];

            } failure:^(NSError *error) {

                PCFPushCriticalLog(@"Error posting %d analytics events to server: %@", events.count, error);
                [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPostingError];
            }];
        }
    }];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self cleanEventsDatabase:self.registrationParameters];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [self sendEventsWithParameters:self.registrationParameters];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

