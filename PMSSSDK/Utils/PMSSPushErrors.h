//
//  PMSSPushErrors.h
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-06.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#ifndef PMSSPushSDK_PMSSPushErrors_h
#define PMSSPushSDK_PMSSPushErrors_h

/**
 * Defines the domain for errors that are specific to the CF Push SDK Client
 */
OBJC_EXPORT NSString *const PMSSPushErrorDomain;

/**
 * Defines the error codes that are specific to the CF Push SDK Client
 */

typedef NS_ENUM(NSInteger, PMSSPushErrorCodes) {
    
    /**
     * The request for the Apple push deviceToken was cancelled.
     */
    PMSSPushBackEndRegistrationCancelled = 11,
    
    /**
     * iOS returned an object to the back-end registration code that was not an NSHTTPURLResponse object.
     */
    PMSSPushBackEndRegistrationNotHTTPResponseError = 21,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    PMSSPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    PMSSPushBackEndRegistrationEmptyResponseData = 23,
    
    /**
     * The back-end server returned unparseable data while attempting to register.
     */
    PMSSPushBackEndRegistrationUnparseableResponseData = 24,

    /**
     * iOS returned an object to the back-end unregistration code that was not an NSHTTPURLResponse object.
     */
    PMSSPushBackEndUnregistrationNotHTTPResponseError = 30,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to unregister.
     */
    PMSSPushBackEndUnregistrationFailedHTTPStatusCode = 31,
    
    /**
     * Failed to build a valid unregistration request.
     */
    PMSSPushBackEndUnregistrationFailedRequestStatusCode = 32,

    /**
     * The registration request JSON data object was badly formatted.
     */
    PMSSPushBackEndRegistrationDataUnparseable = 40,
    
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    PMSSPushBackEndRegistrationResponseDataNoDeviceUuid = 42
    
};

#endif
