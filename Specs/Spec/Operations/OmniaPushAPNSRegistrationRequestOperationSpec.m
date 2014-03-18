//
//  OmniaPushAPNSRegistrationRequestOperationSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Kiwi.h"

#import "OmniaPushAPNSRegistrationRequestOperationTest.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"

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
            [[^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:0 success:nil failure:nil];}
              should] raise];
        });
        
        it(@"should require an application", ^{
            [[^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:helper.params.remoteNotificationTypes success:nil failure:nil];}
              should] raise];
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
            [[operation shouldNot] beNil];
        });
        
        it(@"should retain its arguments as properties", ^{
            [[theValue(operation.remoteNotificationTypes) should] equal:theValue(helper.params.remoteNotificationTypes)];
            [[operation.application should] beIdenticalTo:helper.application];
        });
        
        context(@"registration", ^{
            
            __block NSError *testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
            
            beforeEach(^{
                [helper setupQueues];
            });
            
            afterEach(^{
                [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            });
            
            it(@"should be able to register successfully", ^{
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [[theValue([helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]]) should] beTrue];
                [[(NSObject *)helper.applicationDelegate should] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
                [[(NSObject *)helper.applicationDelegate shouldNot] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            });
            
            it(@"should be able to register successfully", ^{
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [[theValue([helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]]) should] beTrue];
                [[(NSObject *)helper.applicationDelegate shouldNot] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
                [[(NSObject *)helper.applicationDelegate should] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            });
        });
    });
});

SPEC_END
