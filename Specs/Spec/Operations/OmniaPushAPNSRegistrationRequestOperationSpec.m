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
        operation = nil;
    });

    context(@"contructing with invalid arguments", ^{
        
        it(@"should require parameters", ^{
            [[theBlock(^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:0 success:nil failure:nil];})
              should] raise];
        });
        
        it(@"should require an application", ^{
            [[theBlock(^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:helper.params.remoteNotificationTypes success:nil failure:nil];})
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
                [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            });
            
            it(@"should be able to register successfully", ^{
                [[(NSObject *)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
                [[(NSObject *)helper.applicationDelegate shouldNotEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
                
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                [helper.workerQueue addOperation:operation];
                [[theValue([helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]]) should] beTrue];
            });
            
            it(@"should be able to register successfully", ^{
                [[(NSObject *)helper.applicationDelegate shouldNotEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
                [[(NSObject *)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
                
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [[theValue([helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]]) should] beTrue];

            });
        });
    });
});

SPEC_END
