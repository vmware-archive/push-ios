//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#ifndef MSSPush_MSSPushErrors_h
#define MSSPush_MSSPushErrors_h

/**
 * Defines the domain for errors that are specific to the CF Push SDK Client
 */
OBJC_EXPORT NSString *const MSSPushErrorDomain;

/**
 * Defines the error codes that are specific to the CF Push SDK Client
 */

typedef NS_ENUM(NSInteger, MSSPushErrorCodes) {
    
    /**
     * The request for the Apple push deviceToken was cancelled.
     */
    MSSPushBackEndRegistrationCancelled = 11,
    
    /**
     * iOS returned an object to the back-end registration code that was not an NSHTTPURLResponse object.
     */
    MSSPushBackEndRegistrationNotHTTPResponseError = 21,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    MSSPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    MSSPushBackEndRegistrationEmptyResponseData = 23,
    
    /**
     * The back-end server returned unparseable data while attempting to register.
     */
    MSSPushBackEndRegistrationUnparseableResponseData = 24,

    /**
     * iOS returned an object to the back-end unregistration code that was not an NSHTTPURLResponse object.
     */
    MSSPushBackEndUnregistrationNotHTTPResponseError = 30,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to unregister.
     */
    MSSPushBackEndUnregistrationFailedHTTPStatusCode = 31,
    
    /**
     * Failed to build a valid unregistration request.
     */
    MSSPushBackEndUnregistrationFailedRequestStatusCode = 32,

    /**
     * The registration request JSON data object was badly formatted.
     */
    MSSPushBackEndRegistrationDataUnparseable = 40,
    
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    MSSPushBackEndRegistrationResponseDataNoDeviceUuid = 42
    
};

#endif
