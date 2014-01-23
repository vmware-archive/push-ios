#import "OmniaPushRegistrationParameters.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define TEST_NOTIFICATION_TYPES  UIRemoteNotificationTypeAlert
#define TEST_RELEASE_UUID        @"SOS-WE-LIKE-IT-SPICY"
#define TEST_RELEASE_SECRET      @"Put sweet chili sauce on everything"
#define TEST_DEVICE_ALIAS        @"Extreme spiciness classification"

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
       
        it(@"should require a releaseUuid", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:nil releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a releaseSecret", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:nil deviceAlias:TEST_DEVICE_ALIAS];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a deviceAlias", ^{
            ^{model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:TEST_RELEASE_SECRET deviceAlias:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"initializing with valid arguments", ^{
       
        beforeEach(^{
            model = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:TEST_NOTIFICATION_TYPES releaseUuid:TEST_RELEASE_UUID releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];
        });
        
        it(@"should be initialized successfully", ^{
            model should_not be_nil;
        });
    });
});

SPEC_END
