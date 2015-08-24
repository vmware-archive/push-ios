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
     * The connection returned both nil error and response data. This shouldn't happen.
     */
    PCFPushBackEndConnectionEmptyErrorAndResponse = 18,

    /**
     * The back-end server returned a response that was not an HTTP response object
     */
    PCFPushBackEndRegistrationNotHTTPResponseError = 19,

    /**
     * Failed to authenticate while communicating with the back-end server. Can happen if the platform_uuid/platform_secret parameters are wrong.
     */
    PCFPushBackEndAuthenticationError = 20,

    /**
     * The back-end server returned a failure (i.e.: < 200 or >= 300) HTTP status code while attempting to register.
     */
    PCFPushBackEndConnectionFailedHTTPStatusCode = 22,
    
    /**
     * The back-end server returned an empty response while attempting to register.
     */
    PCFPushBackEndRegistrationEmptyResponseData = 23,

    /**
     * Failed to build a valid unregistration request.
     */
    PCFPushBackEndInvalidRequestStatusCode = 32,

    /**
     * The registration request JSON data object was badly formatted.
     */
    PCFPushBackEndDataUnparseable = 40,
    
    /**
     * The back-end server did not return a device_uuid after attempting to register.
     */
    PCFPushBackEndRegistrationResponseDataNoDeviceUuid = 42,

    /**
     * Tried to subscribe to tags when not already registered.
     */
    PCFPushNotRegistered = 50,
};

#endif
