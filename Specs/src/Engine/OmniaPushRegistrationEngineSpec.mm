#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationEngineSpec)

describe(@"OmniaPushRegistrationEngine", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"initialization with bad arguments", ^{
        
        afterEach(^{
            helper.registrationEngine should be_nil;
        });
        
        it(@"should require an application", ^{
            ^{helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:nil];}
                should raise_exception([NSException class]);
        });
    });
    
    context(@"initialization with good arguments", ^{
       
        beforeEach(^{
            helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.application];
        });
        
        it(@"should produce a valid instance", ^{
            helper.registrationEngine should_not be_nil;
        });

        it(@"should retain its arguments in properties", ^{
            helper.registrationEngine.application should be_same_instance_as(helper.application);
//            engine.parameters should be_same_instance_as(helper.params);
        });
        
        it(@"should initialize all the state properties to false", ^{
            helper.registrationEngine.didStartRegistration should_not be_truthy;
            helper.registrationEngine.didStartAPNSRegistration should_not be_truthy;
            helper.registrationEngine.didFinishAPNSRegistration should_not be_truthy;
            helper.registrationEngine.didStartBackendUnregistration should_not be_truthy;
            helper.registrationEngine.didFinishBackendUnregistration should_not be_truthy;
            helper.registrationEngine.didStartBackendRegistration should_not be_truthy;
            helper.registrationEngine.didFinishBackendRegistration should_not be_truthy;
            helper.registrationEngine.didRegistrationSucceed should_not be_truthy;
            helper.registrationEngine.didRegistrationFail should_not be_truthy;
        });
        
    });
});

SPEC_END
