//
//  PMSSAnalyticEvent_TestingHeader.h
//  PMSSPushSpec
//
//  Created by DX123-XL on 2014-04-03.
//
//

#import "PMSSAnalyticEvent.h"

const struct EventTypes {
    PMSS_STRUCT_STRING *error;
    PMSS_STRUCT_STRING *active;
    PMSS_STRUCT_STRING *inactive;
    PMSS_STRUCT_STRING *backgrounded;
    PMSS_STRUCT_STRING *foregrounded;
    PMSS_STRUCT_STRING *registered;
    PMSS_STRUCT_STRING *unregistered;
} EventTypes;

const struct EventRemoteAttributes {
    PMSS_STRUCT_STRING *eventID;
    PMSS_STRUCT_STRING *eventType;
    PMSS_STRUCT_STRING *eventTime;
    PMSS_STRUCT_STRING *eventData;
} EventRemoteAttributes;
