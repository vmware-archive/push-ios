#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAPNSRegistrationRequestOperationSpec)

describe(@"OmniaPushAPNSRegistrationRequestOperation", ^{
    
    __block OmniaPushAPNSRegistrationRequestOperation *operation;
    __block UIRemoteNotificationType testNotificationType = UIRemoteNotificationTypeBadge;
    
    context(@"contructing with invalid arguments", ^{
        it(@"should require an application", ^{
            ^{operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:testNotificationType application:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"constructing with valid arguments", ^{
        
        __block OmniaSpecHelper *helper;
        
        beforeEach(^{
            helper = [[OmniaSpecHelper alloc] init];
            [helper setupApplication];
            [helper setupApplicationDelegate];
            operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:testNotificationType application:helper.application];
        });
        
        afterEach(^{
            [helper reset];
            helper = nil;
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
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationType];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                [helper.workerQueue addOperation:operation];
                [helper.workerQueue drain];
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                helper.applicationDelegate should have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
                helper.applicationDelegate should_not have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            });
            
            it(@"should be able to register successfully", ^{
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:testNotificationType error:testError];
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
