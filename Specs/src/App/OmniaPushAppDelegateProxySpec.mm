//
//  OmniaPushAppDelegateProxySpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushAppDelegateProxySpec)

describe(@"OmniaPushAppDelegateProxy", ^{
    
    __block OmniaSpecHelper *helper = nil;
    __block id<UIApplicationDelegate> originalApplicationDelegate = nil;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
        [helper setupRegistrationEngine];
        UIApplication *app = (UIApplication*) helper.application;
        originalApplicationDelegate = app.delegate;
    });
    
    afterEach(^{
        originalApplicationDelegate = nil;
        [helper reset];
        helper = nil;
    });

    context(@"when init has invalid arguments", ^{
        
        afterEach(^{
            helper.applicationDelegateProxy should be_nil;
        });
        
        it(@"should require an application", ^{
            ^{helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:nil originalApplicationDelegate:helper.applicationDelegate registrationEngine:helper.registrationEngine];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require an application delegate", ^{
            ^{helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:nil registrationEngine:helper.registrationEngine];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require a registration engine", ^{
            ^{helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate registrationEngine:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"switching application delegates", ^{
        
        beforeEach(^{
            helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate registrationEngine:helper.registrationEngine];
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
            helper.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:helper.application originalApplicationDelegate:helper.applicationDelegate registrationEngine:helper.registrationEngine];
        });
        
        afterEach(^{
            helper.applicationDelegateProxy = nil;
            testError = nil;
        });
        
        it(@"should be constructed successfully", ^{
            helper.applicationDelegateProxy should_not be_nil;
        });
        
        it(@"should retain its arguments as properties", ^{
            helper.applicationDelegateProxy.application should be_same_instance_as(helper.application);
            helper.applicationDelegateProxy.originalApplicationDelegate should be_same_instance_as(originalApplicationDelegate);
            helper.applicationDelegateProxy.registrationEngine should be_same_instance_as(helper.registrationEngine);
        });
        
        it(@"should respond to its own UIApplicationDelegate selectors", ^{
            [helper.applicationDelegateProxy respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)] should be_truthy;
            [helper.applicationDelegateProxy respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)] should be_truthy;
        });
        
        it(@"should respond to the selectors of the original application delegate", ^{
            [helper.applicationDelegateProxy respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)] should be_falsy;
            helper.applicationDelegate stub_method("applicationDidReceiveMemoryWarning:").with(helper.application);
            [helper.applicationDelegateProxy respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)] should be_truthy;
        });
        
        it(@"should forward messages to the original application delegate", ^{
            __block BOOL didCallSelector = NO;
            helper.applicationDelegate stub_method("applicationDidReceiveMemoryWarning:").with(helper.application).and_do(^(NSInvocation*) {
                didCallSelector = YES;
            });
            [helper.applicationDelegateProxy performSelector:@selector(applicationDidReceiveMemoryWarning:) withObject:helper.application];
            didCallSelector should be_truthy;
        });
    });
});

SPEC_END
