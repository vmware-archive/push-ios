//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushSpecsHelper.h"
#import "PCFAppDelegate.h"
#import "JRSwizzle.h"
#import "PCFPushPersistentStorage.h"
#import "PCFParameters.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushRegistrationData.h"

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

@implementation PCFPushSpecsHelper

# pragma mark - Spec Helper lifecycle

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.apnsDeviceToken = [@"TEST DEVICE TOKEN 1" dataUsingEncoding:NSUTF8StringEncoding];
        self.backEndDeviceId = @"BACK END DEVICE ID 1";
        self.base64AuthString1 = @"NDQ0LTU1NS02NjYtNzc3Ok5vIHNlY3JldCBpcyBhcyBzdHJvbmcgYXMgaXRzIGJsYWJiaWVzdCBrZWVwZXI=";
        self.tags1 = [NSSet setWithArray:@[ @"TACOS", @"BURRITOS" ]];
        self.tags2 = [NSSet setWithArray:@[ @"COCONUTS", @"PAPAYAS" ]];
        self.application = [UIApplication sharedApplication];
        
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
    self.application = nil;
    self.applicationDelegate = nil;
}

#pragma mark - Application helpers

- (id) setupApplication
{
    self.application = [KWMock mockForClass:[UIApplication class]];
    [UIApplication stub:@selector(sharedApplication) andReturn:self.application];
    return self.application;
}

- (void)stubApplication
{
    [self.application stub:@selector(delegate) andReturn:self.applicationDelegate];
    [self.application stub:@selector(setDelegate:) withBlock:^id(NSArray *params) {
        if ([params[0] conformsToProtocol:@protocol(UIApplicationDelegate)]) {
            self.applicationDelegate = params[0];
        }
        return nil;
    }];
}

- (void) setupApplicationForSuccessfulRegistration
{
    [self setupApplicationForSuccessfulRegistrationWithNewApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationForSuccessfulRegistrationWithNewApnsDeviceToken:(NSData *)newApnsDeviceToken
{
    id (^block)(NSArray *) = ^id(NSArray *params) {
        
        if ([self.applicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
            
            [(PCFAppDelegate *) self.applicationDelegate application:self.application
                   didRegisterForRemoteNotificationsWithDeviceToken:newApnsDeviceToken];
        }
        return nil;
    };
    
    // < iOS 8.0
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:block];
    
    // iOS 8.0 +
    [self.application stub:@selector(registerForRemoteNotifications) withBlock:block];
}

- (void) setupApplicationForFailedRegistrationWithError:(NSError *)error
{
    id (^block)(NSArray *) = ^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
            [(PCFAppDelegate *)self.applicationDelegate application:self.application
                   didFailToRegisterForRemoteNotificationsWithError:error];
        }
        return nil;
    };
    
    // < iOS 8.0
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:block];
    
    // iOS 8.0 +
    [self.application stub:@selector(registerForRemoteNotifications) withBlock:block];
}

#pragma mark - App Delegate Helpers

- (id<UIApplicationDelegate>) setupApplicationDelegate
{
    self.applicationDelegate = [[PCFAppDelegate alloc] init];
    [self stubApplication];
    return self.applicationDelegate;
}

- (void) setupApplicationDelegateForSuccessfulRegistration
{
    [self setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData *)apnsDeviceToken
{
    [(id)self.applicationDelegate stub:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withArguments:self.application, apnsDeviceToken, nil];
}

- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error
{
    [(id)self.applicationDelegate stub:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) withArguments:self.application, error, nil];
}

#pragma mark - Parameters helpers

- (PCFParameters *)setupParameters
{
    PCFParameters *params = [PCFParameters parameters];
    params.developmentPushVariantUUID = TEST_VARIANT_UUID_1;
    params.developmentPushVariantSecret = TEST_VARIANT_SECRET_1;
    params.productionPushVariantUUID = TEST_VARIANT_UUID_1;
    params.productionPushVariantSecret = TEST_VARIANT_SECRET_1;
    params.pushAPIURL = TEST_PUSH_API_URL_1;
    params.pushDeviceAlias = TEST_DEVICE_ALIAS_1;
    params.pushTags = self.tags1;
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
    [PCFParameters stub:@selector(defaultParameterFilename) andReturn:parameterFilename];
    [self setupDefaultPLIST];
}

#pragma mark - NSURLConnection Helpers

- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector
                                   error:(NSError **)error
{
    return [NSURLConnection jr_swizzleClassMethod:@selector(sendAsynchronousRequest:queue:completionHandler:) withClassMethod:selector error:error];
}

- (void)setupSuccessfulAsyncRequestWithBlock:(void(^)(NSURLRequest*))block
{
    [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
        if (block) {
            NSURLRequest *request = params[0];
            block(request);
        }
        __block NSData *newData;
        __block NSHTTPURLResponse *newResponse;
        newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
        NSDictionary *dict = @{
                RegistrationAttributes.deviceOS           : TEST_OS,
                RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                kDeviceUUID                               : TEST_DEVICE_UUID,
        };
        newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];

        CompletionHandler handler = params[2];
        handler(newResponse, newData, nil);
        return nil;
    }];
}

- (void)setupSuccessfulDeleteAsyncRequestAndReturnStatus:(NSInteger)status
{
    [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
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

@end
