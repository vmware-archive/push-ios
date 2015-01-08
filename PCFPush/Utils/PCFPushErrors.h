//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
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
     * Failed to authenticate while registering with the back-end server
     */
    PCFPushBackEndRegistrationAuthenticationError = 20,

    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    PCFPushBackEndRegistrationFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    PCFPushBackEndRegistrationEmptyResponseData = 23,

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
