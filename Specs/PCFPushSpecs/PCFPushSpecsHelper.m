//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import <CoreData/CoreData.h>
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushURLConnection.h"
#import "PCFPushGeofenceUpdater.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushRegistrationData.h"
#import "PCFPushPersistentStorage.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

NSString *const TEST_PUSH_API_URL_1   = @"http://test.url.com";
NSString *const TEST_VARIANT_UUID_1   = @"444-555-666-777";
NSString *const TEST_VARIANT_SECRET_1 = @"No secret is as strong as its blabbiest keeper";
NSString *const TEST_DEVICE_ALIAS_1   = @"Let's watch cat videos";

NSString *const TEST_VARIANT_UUID        = @"123-456-789";
NSString *const TEST_VARIANT_SECRET      = @"My cat's breath smells like cat food";
NSString *const TEST_DEVICE_ALIAS        = @"l33t devices of badness";
NSString *const TEST_DEVICE_MANUFACTURER = @"Commodore";
NSString *const TEST_DEVICE_MODEL        = @"64C";
NSString *const TEST_OS                  = @"BASIC";
NSString *const TEST_OS_VERSION          = @"2.0";
NSString *const TEST_REGISTRATION_TOKEN  = @"ABC-DEF-GHI";
NSString *const TEST_DEVICE_UUID         = @"L337-L337-OH-YEAH";

const int64_t TEST_GEOFENCE_ID              = 66L;
const double TEST_GEOFENCE_LATITUDE         = 53.5;
const double TEST_GEOFENCE_LONGITUDE        = -91.5;
const double TEST_GEOFENCE_RADIUS           = 120;
NSString *const TEST_GEOFENCE_LOCATION_NAME = @"robs_wizard_tacos";

@implementation PCFPushSpecsHelper

# pragma mark - Spec Helper lifecycle

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.apnsDeviceToken = [@"TEST DEVICE TOKEN 1" dataUsingEncoding:NSUTF8StringEncoding];
        self.backEndDeviceId = @"BACK END DEVICE ID 1";
        self.base64AuthString1 = @"NDQ0LTU1NS02NjYtNzc3Ok5vIHNlY3JldCBpcyBhcyBzdHJvbmcgYXMgaXRzIGJsYWJiaWVzdCBrZWVwZXI=";
        self.tags1 = [NSSet setWithArray:@[ @"tacos", @"burritos" ]];
        self.tags2 = [NSSet setWithArray:@[ @"coconuts", @"papayas" ]];
        self.testGeofenceDate = [NSDate date];
        
        [PCFPushPersistentStorage reset];
    }
    return self;
}

- (void) reset
{
    self.params = nil;
    self.apnsDeviceToken = nil;
    self.backEndDeviceId = nil;
    self.tags1 = nil;
    self.tags2 = nil;

    [PCFPushAnalyticsStorage setSharedManager:nil];
    self.analyticsStorage = nil;
}

#pragma mark - Parameters helpers

- (PCFPushParameters *)setupParameters
{
    return [self setupParametersWithGeofencesEnabled:YES];
}

- (PCFPushParameters *)setupParametersWithGeofencesEnabled:(BOOL)geofencesEnabled
{
    PCFPushParameters *params = [PCFPushParameters parameters];
    params.developmentPushVariantUUID = TEST_VARIANT_UUID_1;
    params.developmentPushVariantSecret = TEST_VARIANT_SECRET_1;
    params.productionPushVariantUUID = TEST_VARIANT_UUID_1;
    params.productionPushVariantSecret = TEST_VARIANT_SECRET_1;
    params.pushAPIURL = TEST_PUSH_API_URL_1;
    params.pushDeviceAlias = TEST_DEVICE_ALIAS_1;
    params.pushTags = self.tags1;
    params.areGeofencesEnabled = geofencesEnabled;
    self.params = params;
    return self.params;
}

- (void)setupDefaultPersistedParameters
{
    [PCFPushPersistentStorage setVariantSecret:TEST_VARIANT_SECRET_1];
    [PCFPushPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
    [PCFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
    [PCFPushPersistentStorage setAPNSDeviceToken:self.apnsDeviceToken];
    [PCFPushPersistentStorage setServerDeviceID:self.backEndDeviceId];
    [PCFPushPersistentStorage setTags:self.tags1];
}

- (void) setupDefaultPLIST
{
    [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
}

- (void) setupDefaultPLISTWithFile:(NSString*)parameterFilename
{
    [PCFPushParameters stub:NSSelectorFromString(@"defaultParameterFilename") andReturn:parameterFilename];
    [self setupDefaultPLIST];
}

#pragma mark - NSURLConnection Helpers

- (void)setupVersionRequestWithBlock:(void(^)( void(^successBlock)(NSString*), void(^oldVersionBlock)(void), void(^errorBlock)(NSError *error)))block;
{
    [PCFPushURLConnection stub:@selector(versionRequestWithParameters:success:oldVersion:failure:) withBlock:^id(NSArray *params) {

        void (^successBlock)(NSString*) = (void (^)(NSString*)) params[1];
        void (^oldVersionBlock)() = (void (^)()) params[2];
        void (^failureBlock)(NSError*) = (void (^)(NSError*)) params[3];

        if (block) {
            block(successBlock, oldVersionBlock, failureBlock);
        }

        return nil;
    }];
}

- (void)setupAsyncRequestWithBlock:(void(^)(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError))block {
    [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
        NSURLResponse *resultResponse;
        NSData *resultData;
        NSError *resultError;
        if (block) {
            NSURLRequest *request = params[0];
            block(request, &resultResponse, &resultData, &resultError);
        }

        CompletionHandler handler = params[2];
        handler(resultResponse, resultData, resultError);
        return nil;
    }];
}

- (void)setupSuccessfulAsyncRegistrationRequest
{
    [self setupSuccessfulAsyncRegistrationRequestWithBlock:nil];
}

- (void)setupSuccessfulAsyncRegistrationRequestWithBlock:(void(^)(NSURLRequest*))block
{
    [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
        if (block) {
            NSURLRequest *request = params[0];
            block(request);
        }
        __block NSData *newData;
        __block NSHTTPURLResponse *newResponse;
        newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
        NSDictionary *dict = @{
                PCFPushRegistrationAttributes.deviceOS : TEST_OS,
                PCFPushRegistrationAttributes.deviceOSVersion : TEST_OS_VERSION,
                PCFPushRegistrationAttributes.deviceAlias : TEST_DEVICE_ALIAS,
                PCFPushRegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                PCFPushRegistrationAttributes.deviceModel : TEST_DEVICE_MODEL,
                PCFPushRegistrationAttributes.variantUUID : TEST_VARIANT_UUID,
                PCFPushRegistrationAttributes.registrationToken : TEST_REGISTRATION_TOKEN,
                kPCFPushDeviceUUID : TEST_DEVICE_UUID,
        };
        newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];

        CompletionHandler handler = params[2];
        handler(newResponse, newData, nil);
        return nil;
    }];
}

- (void)setupSuccessfulDeleteAsyncRequestAndReturnStatus:(NSInteger)status
{
    [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
        NSURLRequest *request = params[0];

        __block NSHTTPURLResponse *newResponse;

        if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
            newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:status HTTPVersion:nil headerFields:nil];
        } else {
            fail(@"Request method must be DELETE");
        }

        CompletionHandler handler = params[2];
        handler(newResponse, nil, nil);
        return nil;
    }];
}

#pragma mark - Geofence Helpers

- (void)setupGeofencesForSuccessfulUpdateWithLastModifiedTime:(int64_t)lastModifiedTime
{
    [self setupGeofencesForSuccessfulUpdateWithLastModifiedTime:lastModifiedTime withBlock:nil];
}

- (void)setupGeofencesForSuccessfulUpdateWithLastModifiedTime:(int64_t)lastModifiedTime withBlock:(void(^)(NSArray *))block
{
    [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
        if (block) {
            block(params);
        }
        [PCFPushPersistentStorage setGeofenceLastModifiedTime:lastModifiedTime];
        void (^successBlock)() = params[4];
        successBlock();
        return nil;
    }];
}

- (void)setupGeofencesForFailedUpdate
{
    [self setupGeofencesForFailedUpdateWithBlock:nil];
}

- (void)setupGeofencesForFailedUpdateWithBlock:(void(^)(NSArray *))block
{
    [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
        if (block) {
            block(params);
        }
        NSError *error = [NSError errorWithDomain:@"Fake geofence update error" code:1234 userInfo:nil];
        void (^failureBlock)(NSError *) = params[5];
        failureBlock(error);
        return nil;
    }];
}

- (void)setupClearGeofencesForSuccess
{
    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
        return nil;
    }];
}

#pragma mark - Analytics Helpers

- (void)setupAnalyticsStorage
{
    self.analyticsStorage = PCFPushAnalyticsStorage.shared;
    [self.analyticsStorage.managedObjectContext stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
        void (^block)() = params[0];
        // Execute asynchronous blocks immediately for tests
        [self.analyticsStorage.managedObjectContext performBlockAndWait:block];
        return nil;
    }];
}

- (void)resetAnalyticsStorage
{
    [self.analyticsStorage resetDatabase];
    [PCFPushAnalyticsStorage setSharedManager:nil];
    self.analyticsStorage = nil;
}

@end
