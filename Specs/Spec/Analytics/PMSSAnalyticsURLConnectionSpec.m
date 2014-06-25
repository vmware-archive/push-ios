//
//  PMSSAnalyticsURLConnectionSpec.m
//  PMSSPushSpec
//
//  Created by DX123-XL on 2014-04-30.
//  Copyright 2014 Pivotal. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <CoreData/CoreData.h>

#import "PMSSAnalytics_TestingHeader.h"
#import "PMSSAnalyticEvent.h"
#import "PMSSAnalyticsURLConnection.h"
#import "PMSSCoreDataManager.h"
#import "PMSSClient.h"
#import "PMSSParameters.h"
#import "NSURLConnection+PMSSBackEndConnection.h"


SPEC_BEGIN(PMSSAnalyticsURLConnectionSpec)

describe(@"PMSSAnalyticsURLConnection", ^{
    
    void (^connectionResponse)(NSUInteger, NSError *) = ^(NSUInteger responseCode, NSError *error) {
        [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
            NSURLRequest *request = params[0];
            NSString *authValue = request.allHTTPHeaderFields[BACK_END_ANALYTICS_KEY_FIELD];
            [[authValue shouldNot] beNil];
            [[authValue should] equal:[PMSSClient shared].registrationParameters.analyticsKey];
            
            NSError *JSONError;
            [[[NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&JSONError] should] beNonNil];
            [[JSONError should] beNil];
            
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
        __block PMSSCoreDataManager *manager;
        __block NSUInteger expectedCount = 0;
        
        beforeEach ( ^{
            [[PMSSCoreDataManager shared] flushDatabase];
            
            [PMSSAnalytics setMinSecondsBetweenSends:0];
            manager = [PMSSCoreDataManager shared];
            [[manager managedObjectContext] stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
                void (^block)() = params[0];
                [[manager managedObjectContext] performBlockAndWait:block];
                return nil;
            }];
            expectedCount = 0;
		});
        
        afterEach(^{
            NSArray *storedEvents = [[PMSSCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PMSSAnalyticEvent class])];
            [[theValue(storedEvents.count) should] equal:theValue(expectedCount)];
        });
        
        it(@"should have analytic key header in the request", ^{
            NSArray *storedEvents = [[PMSSCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PMSSAnalyticEvent class])];
            [[theValue(storedEvents.count) should] beZero];
            
            connectionResponse(200, nil);
            expectedCount = 0;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        });
        
        it(@"should handle a failed request", ^{
            NSArray *storedEvents = [[PMSSCoreDataManager shared] managedObjectsWithEntityName:NSStringFromClass([PMSSAnalyticEvent class])];
            [[theValue(storedEvents.count) should] beZero];
            
            connectionResponse(400, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnsupportedURL userInfo:nil]);
            expectedCount = 1;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        });
	});

});

SPEC_END
