//
//  OmniaPushErrors.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-06.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#ifndef OmniaPushSDK_OmniaPushErrors_h
#define OmniaPushSDK_OmniaPushErrors_h

OBJC_EXPORT NSString *const OmniaPushErrorDomain;

enum {
    OmniaPushRegistrationTimeoutError = 10,
    
    OmniaPushBackEndRegistrationNotHTTPResponseError = 21,
    OmniaPushBackEndRegistrationFailedHTTPStatusCode = 22,
    OmniaPushBackEndRegistrationEmptyResponseData = 23,
    OmniaPushBackEndRegistrationUnparseableResponseData = 24,

    OmniaPushBackEndUnregistrationNotHTTPResponseError = 30,
    OmniaPushBackEndUnregistrationFailedHTTPStatusCode = 31,

    OmniaPushBackEndRegistrationRequestDataUnparseable = 40,
    OmniaPushBackEndRegistrationResponseDataUnparseable = 41,
    OmniaPushBackEndRegistrationResponseDataNoDeviceUuid = 42
};

#endif
