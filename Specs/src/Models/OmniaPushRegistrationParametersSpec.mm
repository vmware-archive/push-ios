//
//  OmniaPushRegistrationParametersSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationParameters.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static NSInteger TEST_NOTIFICATION_TYPES = UIRemoteNotificationTypeAlert;

static NSString *const TEST_RELEASE_UUID   = @"SOS-WE-LIKE-IT-SPICY";
static NSString *const TEST_RELEASE_SECRET = @"Put sweet chili sauce on everything";
static NSString *const TEST_DEVICE_ALIAS   = @"Extreme spiciness classification";

SPEC_BEGIN(OmniaPushRegistrationParametersSpec)

describe(@"OmniaPushRegistrationParameters", ^{
    
    __block OmniaPushRegistrationParameters *model;

    afterEach(^{
        model = nil;
    });
    
    context(@"initializing with bad arguments", ^{
        
        afterEach(^{
            model should be_nil;
        });
       
        it(@"should require a non-nil releaseUuid", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:nil releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a non-empty releaseUuid", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:@"" releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a non-nil releaseSecret", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:nil deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a non-empty releaseSecret", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:@"" deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a non-nil deviceAlias", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:TEST_RELEASE_SECRET deviceAlias:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"initializing with valid arguments (empty device alias)", ^{
        
        beforeEach(^{
            model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:TEST_RELEASE_SECRET deviceAlias:@""];
        });
        
        it(@"should be initialized successfully", ^{
            model should_not be_nil;
        });
        
        it(@"should retain its arguments as properties", ^{
            model.remoteNotificationTypes should equal(TEST_NOTIFICATION_TYPES);
            model.releaseUuid should equal(TEST_RELEASE_UUID);
            model.releaseSecret should equal(TEST_RELEASE_SECRET);
            model.deviceAlias should be_empty;
        });
    });

    context(@"initializing with valid arguments (non-nil device alias)", ^{
       
        beforeEach(^{
            model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];
        });
        
        it(@"should be initialized successfully", ^{
            model should_not be_nil;
        });
        
        it(@"should retain its arguments as properties", ^{
            model.remoteNotificationTypes should equal(TEST_NOTIFICATION_TYPES);
            model.releaseUuid should equal(TEST_RELEASE_UUID);
            model.releaseSecret should equal(TEST_RELEASE_SECRET);
            model.deviceAlias should equal(TEST_DEVICE_ALIAS);
        });
    });
});

SPEC_END
