//
//  OmniaPushAPNSRegistrationRequestOperationSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestOperationTest.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAPNSRegistrationRequestOperationSpec)

describe(@"OmniaPushAPNSRegistrationRequestOperation", ^{
    
    __block OmniaPushAPNSRegistrationRequestOperation *operation;
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });

    context(@"contructing with invalid arguments", ^{
        
        it(@"should require parameters", ^{
            ^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:nil success:nil failure:nil];}
            should raise_exception([NSException class]);
        });

        it(@"should require an application", ^{
            ^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:helper.params.remoteNotificationTypes success:nil failure:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"constructing with valid arguments", ^{
        
        beforeEach(^{
            operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:helper.application
                                                                       remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                       success:nil
                                                                                       failure:nil];
        });
        
        it(@"should produce a valid instance", ^{
            operation should_not be_nil;
        });
        
        it(@"should retain its arguments as properties", ^{
            operation.remoteNotificationTypes should equal(helper.params.remoteNotificationTypes);
            operation.application should be_same_instance_as(helper.application);
        });
        
        context(@"registration", ^{
            
            __block NSError *testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
            
            beforeEach(^{
                [helper setupQueues];
            });
            
            afterEach(^{
                helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            });
            
            it(@"should be able to register successfully", ^{
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                helper.applicationDelegate should have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
                helper.applicationDelegate should_not have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            });
            
            it(@"should be able to register successfully", ^{
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                helper.applicationDelegate should_not have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
                helper.applicationDelegate should have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            });
        });
    });
});

SPEC_END
