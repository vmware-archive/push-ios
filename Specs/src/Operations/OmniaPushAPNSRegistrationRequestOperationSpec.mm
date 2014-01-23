#import "OmniaPushAPNSRegistrationRequestOperation.h"
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
            ^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithParameters:nil application:helper.application];}
            should raise_exception([NSException class]);
        });

        it(@"should require an application", ^{
            ^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithParameters:helper.params application:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"constructing with valid arguments", ^{
        
        beforeEach(^{
            operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithParameters:helper.params application:helper.application];
        });
        
        it(@"should produce a valid instance", ^{
            operation should_not be_nil;
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
