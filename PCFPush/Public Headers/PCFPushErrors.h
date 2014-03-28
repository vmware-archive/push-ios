//
//  PCFPushErrors.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-06.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#ifndef PCFPushSDK_PCFPushErrors_h
#define PCFPushSDK_PCFPushErrors_h

/**
 * Defines the domain for errors that are specific to the CF Push SDK Client
 */
OBJC_EXPORT NSString *const PCFPushErrorDomain;

/**
 * Defines the error codes that are specific to the CF Push SDK Client
 */

typedef NS_ENUM(NSInteger, PCFPushErrorCodes) {
    
    /**
     * The request for the Apple push devToken was cancelled.
     */
    PCFPushBackEndRegistrationCancelled = 11,
    
    /**
     * iOS returned an object to the back-end registration code that was not an NSHTTPURLResponse object.
     */
    PCFPushBackEndRegistrationNotHTTPResponseError = 21,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    PCFPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    PCFPushBackEndRegistrationEmptyResponseData = 23,
    
    /**
     * The back-end server returned unparseable data while attempting to register.
     */
    PCFPushBackEndRegistrationUnparseableResponseData = 24,

    /**
     * iOS returned an object to the back-end unregistration code that was not an NSHTTPURLResponse object.
     */
    PCFPushBackEndUnregistrationNotHTTPResponseError = 30,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to unregister.
     */
    PCFPushBackEndUnregistrationFailedHTTPStatusCode = 31,
    
    /**
     * Failed to build a valid unregistration request.
     */
    PCFPushBackEndUnregistrationFailedRequestStatusCode = 32,

    /**
     * The registration request JSON data object was badly formatted.
     */
    PCFPushBackEndRegistrationDataUnparseable = 40,
    
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    PCFPushBackEndRegistrationResponseDataNoDeviceUuid = 42
    
};

#endif
