//
//  PCFAnalyticsURLConnectionSpec.m
//  PCFPushSpec
//
//  Created by DX123-XL on 2014-04-30.
//  Copyright 2014 Pivotal. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <CoreData/CoreData.h>

#import "PCFAnalytics_TestingHeader.h"
#import "PCFAnalyticEvent.h"
#import "PCFAnalyticsURLConnection.h"
#import "PCFCoreDataManager.h"
#import "PCFClient.h"
#import "PCFParameters.h"
#import "NSURLConnection+PCFBackEndConnection.h"


SPEC_BEGIN(PCFAnalyticsURLConnectionSpec)

describe(@"PCFAnalyticsURLConnection", ^{
    
    void (^connectionResponse)(NSUInteger, NSError *) = ^(NSUInteger responseCode, NSError *error) {
        [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
            NSURLRequest *request = params[0];
            NSString *authValue = request.allHTTPHeaderFields[BACK_END_ANALYTICS_KEY_FIELD];
            [[authValue shouldNot] beNil];
            [[authValue should] equal:[PCFClient shared].registrationParameters.analyticsKey];
            
            __block NSHTTPURLResponse *newResponse;
            
            if ([request.HTTPMethod isEqualToString:@"POST"]) {
                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:responseCode HTTPVersion:nil headerFields:nil];
            }
            
            CompletionHandler handler = params[2];
            handler(newResponse, nil, error);
            return nil;
        }];
    };
    
    context(@"valid analytic object arguments", ^{
        __block PCFCoreDataManager *manager;
        __block NSUInteger expectedCount = 0;
        
        beforeEach ( ^{
            [PCFAnalytics setMinSecondsBetweenSends:0];
            manager = [PCFCoreDataManager shared];
            [[manager managedObjectContext] stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
                void (^block)() = params[0];
                [[manager managedObjectContext] performBlockAndWait:block];
                return nil;
            }];
            expectedCount = 0;
		});
        
        afterEach(^{
            NSArray *storedEvents = [[PCFCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PCFAnalyticEvent class])];
            [[theValue(storedEvents.count) should] equal:theValue(expectedCount)];
        });
        
        it(@"should have analytic key header in the request", ^{
            connectionResponse(200, nil);
            expectedCount = 0;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        });
        
        it(@"should handle a failed request", ^{
            connectionResponse(400, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnsupportedURL userInfo:nil]);
            expectedCount = 1;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        });
	});

});

SPEC_END
