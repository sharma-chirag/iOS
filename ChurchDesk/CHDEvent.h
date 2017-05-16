//
//  CHDEvent.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 26/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDManagedModel.h"

typedef NS_ENUM(NSUInteger, CHDEventVisibility) {
    CHDEventVisibilityAllUsers = 1,
    CHDEventVisibilityPublicOnWebsite,
    CHDEventVisibilityOnlyInGroup,
    CHDEventVisibilityDraft,
};


@interface CHDEvent : CHDManagedModel

@property (nonatomic, strong) NSNumber *eventId;
@property (nonatomic, strong) NSString *siteId;
@property (nonatomic, strong) NSNumber *authorId;
@property (nonatomic, strong) NSArray *groupIds;
@property (nonatomic, strong) NSArray *eventCategoryIds;

@property (nonatomic, assign) CHDEventVisibility visibility;
@property (nonatomic, assign) BOOL allDayEvent;
@property (nonatomic, assign) BOOL allowDoubleBooking;
@property (nonatomic, assign) BOOL sendNotifications;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *eventDescription;
@property (nonatomic, strong) NSString *internalNote;
@property (nonatomic, strong) NSString *secureInformation;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *price;
@property (nonatomic, strong) NSString *contributor;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *substitute;
@property (nonatomic, strong) NSString *absenceComment;
@property (nonatomic, strong) NSURL *pictureURL;

@property (nonatomic, assign) NSString *eventResponse;
@property (nonatomic, assign) BOOL canEdit;
@property (nonatomic, assign) BOOL canDelete;

@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSArray *resourceIds;
@property (nonatomic, strong) NSArray *userIds;
@property (nonatomic, strong) NSArray *attendenceStatus;
@property (nonatomic, strong) NSDictionary *fields;

- (NSString*)localizedVisibilityString;
- (NSString*)localizedVisibilityStringForVisibility:(CHDEventVisibility) visibility;

- (NSDictionary*) dictionaryRepresentation;

- (BOOL) eventForUserWithId: (NSNumber*) userId;
- (NSString *) attendanceStatusForUserWithId: (NSNumber*) userId;

@end
