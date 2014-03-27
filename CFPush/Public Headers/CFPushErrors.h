//
//  CFPushErrors.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-06.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#ifndef CFPushSDK_CFPushErrors_h
#define CFPushSDK_CFPushErrors_h

/**
 * Defines the domain for errors that are specific to the Omnia Push SDK Client
 */
OBJC_EXPORT NSString *const CFPushErrorDomain;

/**
 * Defines the error codes that are specific to the Omnia Push SDK Client
 */

typedef NS_ENUM(NSInteger, CFPushErrorCodes) {
    
    /**
     * The request for the Apple push devToken was cancelled.
     */
    CFPushBackEndRegistrationCancelled = 11,
    
    /**
     * iOS returned an object to the back-end registration code that was not an NSHTTPURLResponse object.
     */
    CFPushBackEndRegistrationNotHTTPResponseError = 21,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    CFPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    CFPushBackEndRegistrationEmptyResponseData = 23,
    
    /**
     * The back-end server returned unparseable data while attempting to register.
     */
    CFPushBackEndRegistrationUnparseableResponseData = 24,

    /**
     * iOS returned an object to the back-end unregistration code that was not an NSHTTPURLResponse object.
     */
    CFPushBackEndUnregistrationNotHTTPResponseError = 30,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to unregister.
     */
    CFPushBackEndUnregistrationFailedHTTPStatusCode = 31,
    
    /**
     * Failed to build a valid unregistration request.
     */
    CFPushBackEndUnregistrationFailedRequestStatusCode = 32,

    /**
     * The registration request JSON data object was badly formatted.
     */
    CFPushBackEndRegistrationDataUnparseable = 40,
    
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    CFPushBackEndRegistrationResponseDataNoDeviceUuid = 42
    
};

#endif
