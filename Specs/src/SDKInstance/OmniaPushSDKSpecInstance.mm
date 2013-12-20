#import "OmniaPushSDKInstance.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushSDKInstanceSpec)

describe(@"OmniaPushSDKInstance", ^{
    
    __block OmniaPushSDKInstance *model;
    __block UIApplication *application;
    __block NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
    
    beforeEach(^{
        application = [UIApplication sharedApplication];
        registrationRequest = [[OmniaPushAPNSRegistrationRequestImpl alloc] init];
    });
    
    context(@"when initialization arguments are invalid", ^{
       
        it(@"should require an application", ^{
            ^{model = [[OmniaPushSDKInstance alloc] initWithApplication:nil registrationRequest:registrationRequest];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a registration request", ^{
            ^{model = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:nil];}
            should raise_exception([NSException class]);
        });

    });
    
    context(@"when initialization arguments are valid", ^{
        
        beforeEach(^{
            model = [[OmniaPushSDKInstance alloc] initWithApplication:application registrationRequest:registrationRequest];
        });
        
        it(@"should be able to initialize the SDK successfully", ^{
            model should_not be_nil;
        });
        
    });

});

SPEC_END
