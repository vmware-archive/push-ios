#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaSpecHelper.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushRegistrationListener.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationFailedOperationSpec)

describe(@"OmniaPushRegistrationFailedOperation", ^{
    
    __block OmniaPushRegistrationFailedOperation *operation;
    __block OmniaSpecHelper *helper;
    __block NSError *testError;
    __block id listener;

    beforeEach(^{
        listener = fake_for(@protocol(OmniaPushRegistrationListener));
        testError = [NSError errorWithDomain:@"More frightening error ever" code:0 userInfo:nil];
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
    });
    
    afterEach(^{
        listener = nil;
        testError = nil;
        [helper reset];
        helper = nil;
    });
    
    context(@"when init has invalid arguments", ^{
        
        it(@"should require an application", ^{
            ^{operation = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:nil
                                                                        applicationDelegate:helper.applicationDelegate
                                                                                      error:testError
                                                                                   listener:listener];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require an application delegate", ^{
            ^{operation = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:helper.application
                                                                        applicationDelegate:nil
                                                                                      error:testError
                                                                                   listener:listener];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require an error", ^{
            ^{operation = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:helper.application
                                                                        applicationDelegate:helper.applicationDelegate
                                                                                      error:nil
                                                                                   listener:listener];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"constructing with valid arguments", ^{
        
        beforeEach(^{
            [helper setupQueues];
            operation = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:helper.application
                                                                      applicationDelegate:helper.applicationDelegate
                                                                                    error:testError
                                                                                 listener:nil];
        });
        
        afterEach(^{
            operation = nil;
            [helper reset];
            helper = nil;
        });
        
        it(@"should produce a valid instance", ^{
            operation should_not be_nil;
        });
        
        it(@"should retain its arguments as properties", ^{
            operation.application should be_same_instance_as(helper.application);
            operation.applicationDelegate should be_same_instance_as(helper.applicationDelegate);
            operation.error should be_same_instance_as(testError);
            operation.listener should be_nil;
        });
        
        it(@"should run correctly on the queue", ^{
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper.workerQueue addOperation:operation];
            [helper.workerQueue drain];
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            helper.applicationDelegate should_not have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
            helper.applicationDelegate should have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
        });
    });
    
    context(@"using a listener", ^{
        
        it(@"should call the listener after registration fails", ^{
            [helper setupQueues];
            
            listener stub_method("registrationFailedWithError:").with(testError);
            
            operation = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:helper.application
                                                                      applicationDelegate:helper.applicationDelegate
                                                                                    error:testError
                                                                                 listener:listener];
            
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper.workerQueue addOperation:operation];
            [helper.workerQueue drain];
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            helper.applicationDelegate should_not have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
            helper.applicationDelegate should have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            listener should have_received("registrationFailedWithError:");

            operation = nil;
            [helper reset];
            helper = nil;
        });
    });
});
SPEC_END
