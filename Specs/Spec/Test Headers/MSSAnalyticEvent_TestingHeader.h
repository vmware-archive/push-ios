//
//  MSSAnalyticEvent_TestingHeader.h
//  MSSPushSpec
//
//  Created by DX123-XL on 2014-04-03.
//
//

#import "MSSAnalyticEvent.h"

const struct EventTypes {
    MSS_STRUCT_STRING *error;
    MSS_STRUCT_STRING *active;
    MSS_STRUCT_STRING *inactive;
    MSS_STRUCT_STRING *backgrounded;
    MSS_STRUCT_STRING *foregrounded;
    MSS_STRUCT_STRING *registered;
    MSS_STRUCT_STRING *unregistered;
} EventTypes;

const struct EventRemoteAttributes {
    MSS_STRUCT_STRING *eventID;
    MSS_STRUCT_STRING *eventType;
    MSS_STRUCT_STRING *eventTime;
    MSS_STRUCT_STRING *eventData;
} EventRemoteAttributes;
