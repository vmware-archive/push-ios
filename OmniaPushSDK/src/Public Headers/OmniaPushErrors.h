//
//  OmniaPushErrors.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-06.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#ifndef OmniaPushSDK_OmniaPushErrors_h
#define OmniaPushSDK_OmniaPushErrors_h

/**
 * Defines the domain for errors that are specific to the Omnia Push SDK Client
 */
OBJC_EXPORT NSString *const OmniaPushErrorDomain;

/**
 * Defines the error codes that are specific to the Omnia Push SDK Client
 */

typedef NS_ENUM(NSInteger, OmniaPushErrorCodes) {
    
    /**
     * The request for the Apple push devToken was cancelled.
     */
    OmniaPushBackEndRegistrationCancelled = 11,
    
    /**
     * iOS returned an object to the back-end registration code that was not an NSHTTPURLResponse object.
     */
    OmniaPushBackEndRegistrationNotHTTPResponseError = 21,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    OmniaPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    OmniaPushBackEndRegistrationEmptyResponseData = 23,
    
    /**
     * The back-end server returned unparseable data while attempting to register.
     */
    OmniaPushBackEndRegistrationUnparseableResponseData = 24,

    /**
     * iOS returned an object to the back-end unregistration code that was not an NSHTTPURLResponse object.
     */
    OmniaPushBackEndUnregistrationNotHTTPResponseError = 30,
    
    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to unregister.
     */
    OmniaPushBackEndUnregistrationFailedHTTPStatusCode = 31,

    /**
     * The registration request JSON data object was badly formatted.
     */
    OmniaPushBackEndRegistrationRequestDataUnparseable = 40,
    
    /**
     * The registration response JSON data object was badly formatted.
     */
    OmniaPushBackEndRegistrationResponseDataUnparseable = 41,
    
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    OmniaPushBackEndRegistrationResponseDataNoDeviceUuid = 42
    
};

#endif
