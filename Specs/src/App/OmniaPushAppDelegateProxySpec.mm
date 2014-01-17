#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAppDelegateProxySpec)

describe(@"OmniaPushAppDelegateProxy", ^{
    
    __block OmniaSpecHelper *helper = nil;
    __block UIRemoteNotificationType testNotificationTypes = UIRemoteNotificationTypeAlert;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });

    context(@"when init has invalid arguments", ^{
        
        afterEach(^{
            helper.applicationDelegateProxy should be_nil;
        });
        
        it(@"should require an application", ^{
            ^{helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:nil originalApplicationDelegate:helper.applicationDelegate];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require an application delegate", ^{
            ^{helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"switching application delegates", ^{
        
        __block id<UIApplicationDelegate> originalApplicationDelegate = nil;
        
        beforeEach(^{
            UIApplication *app = (UIApplication*) helper.application;
            originalApplicationDelegate = app.delegate;
            helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate];
        });
        
        afterEach(^{
            originalApplicationDelegate = nil;
        });
        
        it(@"should switch the application delegate after initialization", ^{
            UIApplication *app = (UIApplication*) helper.application;
            app.delegate should be_same_instance_as(helper.applicationDelegateProxy);
        });
        
        it(@"should restore the application delegate after teardown", ^{
            [helper.applicationDelegateProxy cleanup];
            UIApplication *app = (UIApplication*) helper.application;
            app.delegate should be_same_instance_as(originalApplicationDelegate);
        });
    });

    context(@"when it has valid arguments", ^{
        
        __block NSError *testError;
        
        beforeEach(^{
            [helper setupQueues];
            testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
            helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate];
        });
        
        afterEach(^{
            helper.applicationDelegateProxy = nil;
            testError = nil;
        });
        
        it(@"should be constructed successfully", ^{
            helper.applicationDelegateProxy should_not be_nil;
        });
        
        it(@"should forward messages to the original application delegate", ^{
            __block BOOL didCallSelector = NO;
            helper.applicationDelegate stub_method("applicationDidReceiveMemoryWarning:").with(helper.application).and_do(^(NSInvocation*) {
                didCallSelector = YES;
            });
            [helper.applicationDelegateProxy performSelector:@selector(applicationDidReceiveMemoryWarning:) withObject:helper.application];
            didCallSelector should be_truthy;
        });
    
        context(@"when registering", ^{
            
            it(@"should have make a registration request with the same notification type", ^{
                [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                
                [helper.applicationDelegateProxy registerForRemoteNotificationTypes:testNotificationTypes];
                [helper.workerQueue drain];
                
                helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
                helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should_not be_truthy;
            });
            
            it(@"should call didFailToRegisterForRemoteNotificationsWithError on the appDelegate after a failed registration request", ^{
                [helper setupApplicationForFailedRegistrationWithNotificationTypes:testNotificationTypes error:testError];
                [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                
                [helper.applicationDelegateProxy registerForRemoteNotificationTypes:testNotificationTypes];
                [helper.workerQueue drain];
                
                helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
                helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
                [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should_not be_truthy;
                [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            });
        });
    });
});

SPEC_END
