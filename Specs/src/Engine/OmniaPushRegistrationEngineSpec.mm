//
//  OmniaPushRegistrationEngineSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushRegistrationEngine.h"
#import "OmniaSpecHelper.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaRegistrationSpecHelper.h"
#import "OmniaPushPersistentStorage.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushRegistrationEngineSpec)

describe(@"OmniaPushRegistrationEngine", ^{
    
    __block OmniaRegistrationSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaRegistrationSpecHelper alloc] initWithSpecHelper:[[OmniaSpecHelper alloc] init]];
        [helper setup];
        [helper saveAPNSDeviceToken:nil];
        [helper saveBackEndDeviceID:nil];
        [helper saveReleaseUuid:nil];
        [helper saveReleaseSecret:nil];
        [helper saveDeviceAlias:nil];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"initialization with bad arguments", ^{
        
        afterEach(^{
            helper.helper.registrationEngine should be_nil;
        });

        it(@"should require an application", ^{
            ^{helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:nil originalApplicationDelegate:helper.helper.applicationDelegate listener:nil];}
                should raise_exception([NSException class]);
        });
        
        it(@"should require the original application delegate", ^{
            ^{helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.helper.application originalApplicationDelegate:nil listener:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"initialization with good arguments", ^{
       
        beforeEach(^{
            helper.helper.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:helper.helper.application originalApplicationDelegate:helper.helper.applicationDelegate listener:nil];
        });
        
        it(@"should produce a valid instance", ^{
            helper.helper.registrationEngine should_not be_nil;
        });

        it(@"should retain its arguments in properties", ^{
            helper.helper.registrationEngine.application should be_same_instance_as(helper.helper.application);
        });
        
        it(@"should initialize all the state properties to false", ^{
            
            [helper verifyDidStartRegistration:BE_FALSE didStartAPNSRegistration:BE_FALSE
                     didFinishAPNSRegistration:BE_FALSE didAPNSRegistrationSucceed:BE_FALSE
                 didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
               didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_FALSE
                  didFinishBackendRegistration:BE_FALSE didBackendRegistrationSucceed:BE_FALSE
                        didRegistrationSucceed:BE_FALSE resultError:nil];
        });
        
        context(@"when registering", ^{
            
            __block NSError *testError;
            __block NSError *testError2;
            
            beforeEach(^{
                [helper.helper setupQueues];
                [helper.helper setupAppDelegateProxy];
                testError = [NSError errorWithDomain:@"Some dumb error" code:0 userInfo:nil];
                testError2 = [NSError errorWithDomain:@"Some exciting error" code:0 userInfo:nil];
            });
            
            it(@"should require parameters", ^{
                ^{[helper.helper.registrationEngine startRegistration:nil];}
                    should raise_exception([NSException class]);
            });
            
            it(@"should retain its parameters", ^{
                [helper.helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                [helper startRegistration];
                helper.helper.registrationEngine.parameters should equal(helper.helper.params);
                helper.helper.registrationEngine.parameters should_not be_nil;
            });
            
            context(@"successful registration", ^{
                
                beforeEach(^{
                    [helper.applicationDelegateMessages addObject:@"application:didRegisterForRemoteNotificationsWithDeviceToken:"];
                });
                
                afterEach(^{
                    [helper verifyMessages];
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationCompleteOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationFailedOperation class]]];
                });
                
                context(@"receiving the regular device token from APNS", ^{
                    
                    beforeEach(^{
                        [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
                        [helper.helper setupApplicationDelegateForSuccessfulRegistration];
                    });
                    
                    afterEach(^{
                        [helper apnsDeviceToken] should equal(helper.helper.apnsDeviceToken);
                        [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId);
                        [helper releaseUuid] should equal(TEST_RELEASE_UUID);
                        [helper releaseSecret] should equal(TEST_RELEASE_SECRET);
                        [helper deviceAlias] should equal(TEST_DEVICE_ALIAS);
                    });
                    
                    context(@"when not already registered with APNS", ^{
                        
                        beforeEach(^{
                            [helper setupBackEndForSuccessfulRegistration];
                        });
                        
                        it(@"should register with APNS and then with the back-end", ^{

                            [helper startRegistration];
                            
                            [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                     didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                 didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                               didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                  didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                        didRegistrationSucceed:BE_TRUE  resultError:nil];
                        });
                    });
                    
                    context(@"already registered with APNS", ^{
                        
                        beforeEach(^{
                            [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken];
                        });
                        
                        context(@"not already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper setupBackEndForSuccessfulRegistration];
                            });

                            it(@"should still register with APNS and then the back-end", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });

                        context(@"already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                            });
                            
                            it(@"should still register with APNS but skip the back-end registration", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_FALSE
                                      didFinishBackendRegistration:BE_FALSE didBackendRegistrationSucceed:BE_FALSE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });
                    });
                });
                
                context(@"already registered with APNS",^{
                    
                    beforeEach(^{
                        [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES withNewApnsDeviceToken:helper.helper.apnsDeviceToken2];
                        [helper.helper setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:helper.helper.apnsDeviceToken2];
                        [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken];
                    });
                    
                    afterEach(^{
                        [helper apnsDeviceToken] should equal(helper.helper.apnsDeviceToken2);
                    });
                    
                    context(@"receiving a different device token from APNS", ^{
                        
                        beforeEach(^{
                            [helper setupBackEndForSuccessfulRegistrationWithNewBackEndDeviceId:helper.helper.backEndDeviceId2];
                        });
                        
                        afterEach(^{
                            [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId2);
                            [helper releaseUuid] should equal(TEST_RELEASE_UUID);
                            [helper releaseSecret] should equal(TEST_RELEASE_SECRET);
                            [helper deviceAlias] should equal(TEST_DEVICE_ALIAS);
                        });
                        
                        context(@"not registered with back-end yet", ^{
                            
                            it(@"should skip unregistration with the back-end and then register with the back-end", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });
                        
                        context(@"already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                            });
                            
                            context(@"unregistration is successful", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForSuccessfulUnregistration];
                                });
                                
                                it(@"should unregister with the back-end and then register anew with the back-end", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                    
                                });
                            });
                            
                            context(@"unregistration fails", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForFailedUnregistrationWithError:testError];
                                });
                                
                                it(@"should register anew with the back-end even after unregistration fails", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                });
                            });
                        });
                    });
                    
                    context(@"receiving a new release uuid in the parameters", ^{
                        
                        beforeEach(^{
                            [helper setupBackEndForSuccessfulRegistration];
                            [helper.helper changeReleaseUuidInParameters:TEST_RELEASE_UUID_2];
                        });
                        
                        afterEach(^{
                            [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId);
                            [helper releaseUuid] should equal(TEST_RELEASE_UUID_2);
                            [helper releaseSecret] should equal(TEST_RELEASE_SECRET);
                            [helper deviceAlias] should equal(TEST_DEVICE_ALIAS);
                        });
                        
                        context(@"not registered with back-end yet", ^{
                            
                            it(@"should skip unregistration with the back-end and then register with the back-end", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });
                        
                        context(@"already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                            });
                            
                            context(@"unregistration is successful", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForSuccessfulUnregistration];
                                });
                                
                                it(@"should unregister with the back-end and then register anew with the back-end", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                    
                                });
                            });
                            
                            context(@"unregistration fails", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForFailedUnregistrationWithError:testError];
                                });
                                
                                it(@"should register anew with the back-end even after unregistration fails", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                });
                            });
                        });
                    });
                    
                    context(@"receiving a new release secret in the parameters", ^{
                        
                        beforeEach(^{
                            [helper setupBackEndForSuccessfulRegistration];
                            [helper.helper changeReleaseSecretInParameters:TEST_RELEASE_SECRET_2];
                        });
                        
                        afterEach(^{
                            [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId);
                            [helper releaseUuid] should equal(TEST_RELEASE_UUID);
                            [helper releaseSecret] should equal(TEST_RELEASE_SECRET_2);
                            [helper deviceAlias] should equal(TEST_DEVICE_ALIAS);
                        });
                        
                        context(@"not registered with back-end yet", ^{
                            
                            it(@"should skip unregistration with the back-end and then register with the back-end", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });
                        
                        context(@"already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                            });
                            
                            context(@"unregistration is successful", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForSuccessfulUnregistration];
                                });
                                
                                it(@"should unregister with the back-end and then register anew with the back-end", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                    
                                });
                            });
                            
                            context(@"unregistration fails", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForFailedUnregistrationWithError:testError];
                                });
                                
                                it(@"should register anew with the back-end even after unregistration fails", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                });
                            });
                        });
                    });
                    
                    context(@"receiving a new device alias in the parameters", ^{
                        
                        beforeEach(^{
                            [helper setupBackEndForSuccessfulRegistration];
                            [helper.helper changeDeviceAliasInParameters:TEST_DEVICE_ALIAS_2];
                        });
                        
                        afterEach(^{
                            [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId);
                            [helper releaseUuid] should equal(TEST_RELEASE_UUID);
                            [helper releaseSecret] should equal(TEST_RELEASE_SECRET);
                            [helper deviceAlias] should equal(TEST_DEVICE_ALIAS_2);
                        });
                        
                        context(@"not registered with back-end yet", ^{
                            
                            it(@"should skip unregistration with the back-end and then register with the back-end", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                            didRegistrationSucceed:BE_TRUE  resultError:nil];
                            });
                        });
                        
                        context(@"already registered with the back-end", ^{
                            
                            beforeEach(^{
                                [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                            });
                            
                            context(@"unregistration is successful", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForSuccessfulUnregistration];
                                });
                                
                                it(@"should unregister with the back-end and then register anew with the back-end", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                    
                                });
                            });
                            
                            context(@"unregistration fails", ^{
                                
                                beforeEach(^{
                                    [helper setupBackEndForFailedUnregistrationWithError:testError];
                                });
                                
                                it(@"should register anew with the back-end even after unregistration fails", ^{
                                    
                                    [helper startRegistration];
                                    
                                    [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                             didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                         didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                       didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                          didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_TRUE
                                                didRegistrationSucceed:BE_TRUE  resultError:nil];
                                });
                            });
                        });
                    });
                });
            });
            
            context(@"failed registration", ^{
                
                beforeEach(^{
                    [helper.applicationDelegateMessages addObject:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
                    [helper.helper setupApplicationDelegateForFailedRegistrationWithError:testError];
                });
                
                afterEach(^{
                    [helper verifyMessages];
                    [helper verifyQueueCompletedOperations:@[[OmniaPushAPNSRegistrationRequestOperation class], [OmniaPushRegistrationFailedOperation class]]
                                    notCompletedOperations:@[[OmniaPushRegistrationCompleteOperation class]]];
                });
                
                context(@"APNS registration fails", ^{
                    
                    beforeEach(^{
                        [helper.helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
                    });
                    
                    context(@"not previously registered with the back-end", ^{
                        
                        afterEach(^{
                            [helper apnsDeviceToken] should be_nil;
                            [helper backEndDeviceID] should be_nil;
                            [helper releaseUuid] should be_nil;
                            [helper releaseSecret] should be_nil;
                            [helper deviceAlias] should be_nil;

                        });
                        
                        context(@"after a fresh install", ^{
                            
                            it(@"it should attempt to register with APNS and stop after that", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_FALSE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_FALSE
                                      didFinishBackendRegistration:BE_FALSE didBackendRegistrationSucceed:BE_FALSE
                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                            });
                        });
                        
                        context(@"after already registered with APNS", ^{
                            
                            beforeEach(^{
                                [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken];
                            });
                            
                            it(@"it should attempt to register anew with APNS and stop after that", ^{

                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_FALSE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_FALSE
                                      didFinishBackendRegistration:BE_FALSE didBackendRegistrationSucceed:BE_FALSE
                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                            });
                        });
                    });
                    
                    context(@"previously registered with the back-end", ^{
                        
                        beforeEach(^{
                            [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken];
                            [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                            [helper saveReleaseUuid:TEST_RELEASE_UUID];
                            [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                            [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                        });
                        
                        afterEach(^{
                            [helper apnsDeviceToken] should be_nil;
                            [helper backEndDeviceID] should equal(helper.helper.backEndDeviceId);
                            [helper releaseUuid] should equal(TEST_RELEASE_UUID);
                            [helper releaseSecret] should equal(TEST_RELEASE_SECRET);
                            [helper deviceAlias] should equal(TEST_DEVICE_ALIAS);
                        });

                        context(@"after already registered with APNS and the back-end", ^{
                            
                            it(@"it should attempt to register anew with APNS and stop after that. the backEndDeviceId from before should be retained.", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_FALSE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_FALSE
                                      didFinishBackendRegistration:BE_FALSE didBackendRegistrationSucceed:BE_FALSE
                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                            });
                        });
                    });
                });

                context(@"APNS registration succeeds", ^{
                    
                    context(@"back-end registration fails", ^{
                        
                        beforeEach(^{
                            [helper.helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES withNewApnsDeviceToken:helper.helper.apnsDeviceToken2];
                            [helper setupBackEndForFailedRegistrationWithError:testError];
                        });
                        
                        context(@"previously not registered with APNS", ^{
                            
                            afterEach(^{
                                [helper apnsDeviceToken] should equal(helper.helper.apnsDeviceToken2);
                                [helper backEndDeviceID] should be_nil;
                                [helper releaseUuid] should be_nil;
                                [helper releaseSecret] should be_nil;
                                [helper deviceAlias] should be_nil;
                            });

                            it(@"it should save the APNS device token, attempt to register with the back-end, and stop after that fails", ^{
                                
                                [helper startRegistration];
                                
                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                     didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                            });
                        });
                        
                        context(@"previously registered with APNS", ^{
                            
                            context(@"APNS returns the same device token as before", ^{
                                
                                beforeEach(^{
                                    [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken2];
                                });
                                
                                afterEach(^{
                                    [helper apnsDeviceToken] should equal(helper.helper.apnsDeviceToken2);
                                    [helper backEndDeviceID] should be_nil;
                                    [helper releaseUuid] should be_nil;
                                    [helper releaseSecret] should be_nil;
                                    [helper deviceAlias] should be_nil;
                                });

                                context(@"previously not registered with back-end", ^{

                                    it(@"it should attempt to register with the back-end and stop after that fails", ^{
                                        
                                        [helper startRegistration];
                                        
                                        [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                 didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                             didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                           didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                              didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                    didRegistrationSucceed:BE_FALSE resultError:testError];
                                    });
                                    
                                });
                                
                                context(@"previously registered with back-end", ^{
                                    
                                    beforeEach(^{
                                        [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                        [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                        [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                        [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                                    });
                                   
                                    context(@"different release uuid in the parameters",^{
                                        
                                        beforeEach(^{
                                            [helper.helper changeReleaseUuidInParameters:TEST_RELEASE_UUID_2];
                                        });
                                        
                                        context(@"unregistration succeeds", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForSuccessfulUnregistration];
                                            });
                                            
                                            it(@"it should unregister successfully and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                        
                                        context(@"unregistration fails", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForFailedUnregistrationWithError:testError2];
                                            });
                                            
                                            it(@"should fail the unregistration and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                    });
                                    
                                    context(@"different release secret in the parameters",^{
                                        
                                        beforeEach(^{
                                            [helper.helper changeReleaseSecretInParameters:TEST_RELEASE_SECRET_2];
                                        });
                                        
                                        context(@"unregistration succeeds", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForSuccessfulUnregistration];
                                            });
                                            
                                            it(@"it should unregister successfully and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                        
                                        context(@"unregistration fails", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForFailedUnregistrationWithError:testError2];
                                            });
                                            
                                            it(@"should fail the unregistration and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                    });
                                    
                                    context(@"different device alias in the parameters",^{
                                        
                                        beforeEach(^{
                                            [helper.helper changeDeviceAliasInParameters:TEST_DEVICE_ALIAS_2];
                                        });
                                        
                                        context(@"unregistration succeeds", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForSuccessfulUnregistration];
                                            });
                                            
                                            it(@"it should unregister successfully and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                        
                                        context(@"unregistration fails", ^{
                                            
                                            beforeEach(^{
                                                [helper setupBackEndForFailedUnregistrationWithError:testError2];
                                            });
                                            
                                            it(@"should fail the unregistration and then attempt to register with the back-end and stop after that fails", ^{
                                                
                                                [helper startRegistration];
                                                
                                                [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                         didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                     didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                                   didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                                      didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                            didRegistrationSucceed:BE_FALSE resultError:testError];
                                            });
                                        });
                                    });
                                    
                                    // NOTE - context back-end registration fails/previously registered with APNS/previously registered with back-end/registration parameters all the same
                                    // does not need a test here since back-end registration is skipped entirely in this scenario (and hence would be considered a success)
                               
                                });
                            });
                            
                            context(@"APNS returns a new device token", ^{

                                beforeEach(^{
                                    [helper saveAPNSDeviceToken:helper.helper.apnsDeviceToken];
                                });
                                
                                afterEach(^{
                                    [helper apnsDeviceToken] should equal(helper.helper.apnsDeviceToken2);
                                });

                                context(@"previously not registered with back-end", ^{
                                    
                                    afterEach(^{
                                        [helper backEndDeviceID] should be_nil;
                                        [helper releaseUuid] should be_nil;
                                        [helper releaseSecret] should be_nil;
                                        [helper deviceAlias] should be_nil;
                                    });
                                    
                                    it(@"it should attempt to register with the back-end and stop after that fails", ^{
                                        
                                        [helper startRegistration];
                                        
                                        [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                 didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                             didStartBackendUnregistration:BE_FALSE didFinishBackendUnregistration:BE_FALSE
                                           didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                              didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                    didRegistrationSucceed:BE_FALSE resultError:testError];
                                    });
                                });
                                
                                context(@"previously registered with back-end", ^{
                                    
                                    beforeEach(^{
                                        [helper saveBackEndDeviceID:helper.helper.backEndDeviceId];
                                        [helper saveReleaseUuid:TEST_RELEASE_UUID];
                                        [helper saveReleaseSecret:TEST_RELEASE_SECRET];
                                        [helper saveDeviceAlias:TEST_DEVICE_ALIAS];
                                    });
                                    
                                    afterEach(^{
                                        [helper backEndDeviceID] should be_nil;
                                        [helper releaseUuid] should be_nil;
                                        [helper releaseSecret] should be_nil;
                                        [helper deviceAlias] should be_nil;
                                    });

                                    context(@"unregistration fails", ^{
                                        
                                        beforeEach(^{
                                            [helper setupBackEndForFailedUnregistrationWithError:testError2];
                                        });
                                        
                                        it(@"should save the new device token, unregister, watch that fail, start back-end registration anew, and stop after that fails", ^{
                                            
                                            [helper startRegistration];
                                            
                                            [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                     didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                 didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                               didBackEndUnregistrationSucceed:BE_FALSE didStartBackendRegistration:BE_TRUE
                                                  didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                        didRegistrationSucceed:BE_FALSE resultError:testError];
                                        });
                                    });
                                    
                                    context(@"unregistration succeeds", ^{
                                        
                                        beforeEach(^{
                                            [helper setupBackEndForSuccessfulUnregistration];
                                        });
                                        
                                        it(@"should save the new device token, unregister, start back-end registration anew, and stop after that fails", ^{
                                            
                                            [helper startRegistration];
                                            
                                            [helper verifyDidStartRegistration:BE_TRUE  didStartAPNSRegistration:BE_TRUE
                                                     didFinishAPNSRegistration:BE_TRUE  didAPNSRegistrationSucceed:BE_TRUE
                                                 didStartBackendUnregistration:BE_TRUE  didFinishBackendUnregistration:BE_TRUE
                                               didBackEndUnregistrationSucceed:BE_TRUE  didStartBackendRegistration:BE_TRUE
                                                  didFinishBackendRegistration:BE_TRUE  didBackendRegistrationSucceed:BE_FALSE
                                                        didRegistrationSucceed:BE_FALSE resultError:testError];
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});

SPEC_END
