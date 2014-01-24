#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaSpecHelper.h"
#import "OmniaFakeOperationQueue.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationCompleteOperationSpec)

describe(@"OmniaPushRegistrationCompleteOperation", ^{
    
    __block OmniaPushRegistrationCompleteOperation *operation;
    __block OmniaSpecHelper *helper;
    
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
        
        it(@"should require an application", ^{
            ^{operation = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:nil applicationDelegate:helper.applicationDelegate deviceToken:helper.deviceToken];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require an application delegate", ^{
            ^{operation = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:helper.application applicationDelegate:nil deviceToken:helper.deviceToken];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a device token", ^{
            ^{operation = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:helper.application applicationDelegate:helper.applicationDelegate deviceToken:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"constructing with valid arguments", ^{
        
        beforeEach(^{
            [helper setupQueues];
            operation = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:helper.application applicationDelegate:helper.applicationDelegate deviceToken:helper.deviceToken];
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
            operation.deviceToken should be_same_instance_as(helper.deviceToken);
            operation.application should be_same_instance_as(helper.application);
            operation.applicationDelegate should be_same_instance_as(helper.applicationDelegate);
        });
        
        it(@"should run correctly on the queue", ^{
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper.workerQueue addOperation:operation];
            [helper.workerQueue drain];
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
            helper.applicationDelegate should have_received(@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
            helper.applicationDelegate should_not have_received(@selector(application:didFailToRegisterForRemoteNotificationsWithError:));
        });
    });
});
SPEC_END
