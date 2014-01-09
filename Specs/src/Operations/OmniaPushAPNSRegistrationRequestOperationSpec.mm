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
        
        beforeEach(^{
            setupApplication();
            setupApplicationDelegate();
            operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:testNotificationType application:getApplication()];
        });
        
        it(@"should produce a valid instance", ^{
            operation should_not be_nil;
        });
        
        context(@"registration", ^{
            
            __block NSError *testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
            
            beforeEach(^{
                setupOperationQueue();
            });
            
            afterEach(^{
                getApplication() should have_received(@selector(registerForRemoteNotificationTypes:));
            });
            
            it(@"should be able to register successfully", ^{
                setupApplicationForSuccessfulRegistration(testNotificationType);
                setupApplicationDelegateForSuccessfulRegistration();
                [getOperationQueue() addOperation:operation];
                [getOperationQueue() drain];
                [getOperationQueue() didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                getApplicationDelegate() should have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
            });
            
            it(@"should be able to register successfully", ^{
                setupApplicationForFailedRegistration(testNotificationType, testError);
                setupApplicationDelegateForFailedRegistration(testError);
                [getOperationQueue() addOperation:operation];
                [getOperationQueue() drain];
                [getOperationQueue() didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                getApplicationDelegate() should have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            });
        });
    });
});

SPEC_END
