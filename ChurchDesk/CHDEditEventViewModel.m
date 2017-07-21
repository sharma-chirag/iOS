//
//  CHDEditEventViewModel.m
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 06/03/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDEditEventViewModel.h"
#import "CHDEvent.h"
#import "CHDAPIClient.h"
#import "CHDEnvironment.h"
#import "CHDUser.h"
#import "NSUserDefaults+CHDDefaults.h"
#import "CHDSitePermission.h"

NSString *const CHDEventEditSectionTitle = @"CHDEventEditSectionTitle";
NSString *const CHDEventEditSectionDate = @"CHDEventEditSectionDate";
NSString *const CHDEventEditSectionRecipients = @"CHDEventEditSectionRecipients";
NSString *const CHDEventEditSectionVisibility = @"CHDEventEditSectionVisibility";
NSString *const CHDEventEditSectionBooking = @"CHDEventEditSectionBooking";
NSString *const CHDEventEditSectionInternalNote = @"CHDEventEditSectionInternalNote";
NSString *const CHDEventEditSectionSecureInformation = @"CHDEventEditSectionSecureInformation";
NSString *const CHDEventEditSectionDescription = @"CHDEventEditSectionDescription";
NSString *const CHDEventEditSectionMisc = @"CHDEventEditSectionMisc";
NSString *const CHDEventEditSectionDivider = @"CHDEventEditSectionDivider";

NSString *const CHDEventEditRowTitle = @"CHDEventEditRowTitle";
NSString *const CHDEventEditRowAllDay = @"CHDEventEditRowAllDay";
NSString *const CHDEventEditRowStartDate = @"CHDEventEditRowStartDate";
NSString *const CHDEventEditRowEndDate = @"CHDEventEditRowEndDate";
NSString *const CHDEventEditRowParish = @"CHDEventEditRowParish";
NSString *const CHDEventEditRowGroup = @"CHDEventEditRowGroup";
NSString *const CHDEventEditRowCategories = @"CHDEventEditRowCategories";
NSString *const CHDEventEditRowLocation = @"CHDEventEditRowLocation";
NSString *const CHDEventEditRowResources = @"CHDEventEditRowResources";
NSString *const CHDEventEditRowUsers = @"CHDEventEditRowUsers";
NSString *const CHDEventEditRowInternalNote = @"CHDEventEditRowInternalNote";
NSString *const CHDEventEditRowSecureInformation = @"CHDEventEditRowSecureInformation";
NSString *const CHDEventEditRowDescription = @"CHDEventEditRowDescription";
NSString *const CHDEventEditRowContributor = @"CHDEventEditRowContributor";
NSString *const CHDEventEditRowPrice = @"CHDEventEditRowPrice";
NSString *const CHDEventEditRowDoubleBooking = @"CHDEventEditRowDoubleBooking";
NSString *const CHDEventEditRowVisibility = @"CHDEventEditRowVisibility";
NSString *const CHDEventEditRowDelete = @"CHDEventEditRowDelete";

NSString *const CHDEventEditRowDivider = @"CHDEventEditRowDivider";

@interface CHDEditEventViewModel ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSDictionary *sectionRows;
@property (nonatomic, assign) BOOL newEvent;

@property (nonatomic, strong) CHDEnvironment *environment;
@property (nonatomic, strong) CHDUser *user;

@property (nonatomic, strong) RACCommand *saveCommand;
@property (nonatomic, strong) RACCommand *deleteCommand;

@end

@implementation CHDEditEventViewModel

- (instancetype)initWithEvent: (CHDEvent*) event {
    self = [super init];
    if (self) {
        _event = event ? [event copy] : [CHDEvent new];
        _event.type = kEvent;
        _newEvent = event == nil;

        if(_newEvent){
            self.event.siteId = [[NSUserDefaults standardUserDefaults] chdDefaultSiteId];
            self.event.visibility = CHDEventVisibilityOnlyInGroup;
            self.event.startDate = [NSDate date];
            NSTimeInterval secondsInOneHour = 60 * 60;
            self.event.endDate = [[NSDate date] dateByAddingTimeInterval:secondsInOneHour];
        }

        [self rac_liftSelector:@selector(setEnvironment:) withSignals:[[CHDAPIClient sharedInstance] getEnvironment], nil];
        /*RACSignal *userSignal = [[CHDAPIClient sharedInstance] getCurrentUser];
        [self rac_liftSelector:@selector(setUser:) withSignals:userSignal, nil];*/

        self.sections = @[CHDEventEditSectionTitle, CHDEventEditSectionDate, CHDEventEditSectionRecipients, CHDEventEditSectionVisibility, CHDEventEditSectionBooking, CHDEventEditSectionInternalNote, CHDEventEditSectionSecureInformation, CHDEventEditSectionMisc, CHDEventEditSectionDescription, CHDEventEditSectionDivider];
        
        self.sectionRows = @{CHDEventEditSectionTitle : @[CHDEventEditRowDivider, CHDEventEditRowTitle],
                             CHDEventEditSectionDate : @[CHDEventEditRowDivider, CHDEventEditRowAllDay, CHDEventEditRowStartDate],
                             CHDEventEditSectionRecipients : @[],
                             CHDEventEditSectionVisibility : @[],
                             CHDEventEditSectionBooking : @[],
                             CHDEventEditSectionInternalNote : @[CHDEventEditRowDivider, CHDEventEditRowInternalNote],
                             CHDEventEditSectionSecureInformation : @[],
                             CHDEventEditSectionMisc : @[CHDEventEditRowDivider, CHDEventEditRowContributor, CHDEventEditRowPrice],
                             CHDEventEditSectionDescription : @[CHDEventEditRowDivider, CHDEventEditRowDescription],
                             CHDEventEditSectionDivider : @[CHDEventEditRowDivider]};
        
        // to load the user form faster
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedObject = [defaults objectForKey:kcurrentuser];
        _user = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        [self rac_liftSelector:@selector(setupSectionsWithUser:) withSignals:[RACSignal merge:@[RACObserve(self, user),
            [RACObserve(self.event, siteId) flattenMap:^RACStream *(id value) {
                return RACObserve(self, user) ;
            }],
            [RACObserve(self.event, visibility) flattenMap:^RACStream *(id value) {
                return RACObserve(self, user);
            }],
            [RACObserve(self.event, groupIds) flattenMap:^RACStream *(id value) {
                return RACObserve(self, user);
            }]
        ]],nil];
    }
    return self;
}

-(void) setupSectionsWithUser: (CHDUser *) user{
    NSArray *recipientsRows = _newEvent && user.sites.count > 1 ? @[CHDEventEditRowDivider, CHDEventEditRowParish, CHDEventEditRowCategories] : @[CHDEventEditRowDivider, CHDEventEditRowCategories];
    NSArray *bookingRows = [user siteWithId:self.event.siteId].permissions.canDoubleBook? @[CHDEventEditRowDivider, CHDEventEditRowResources, CHDEventEditRowUsers, CHDEventEditRowDoubleBooking] : @[CHDEventEditRowDivider, CHDEventEditRowResources, CHDEventEditRowUsers];;
    NSArray *secureRows = @[CHDEventEditRowDivider, CHDEventEditRowSecureInformation];
    if(self.event.siteId == nil){
        for(CHDSite *site in user.sites){
            if(site.permissions.canCreateEvent){
                self.event.siteId = site.siteId;
                break;
            }
        }
    }

    if(!self.event.siteId){
        recipientsRows = @[CHDEventEditRowDivider, CHDEventEditRowParish];
        bookingRows = @[];
    }
    CHDSite *selectedSite = [user siteWithId:self.event.siteId];
    if (!selectedSite.permissions.canEditSensitiveInfo) {
        secureRows = @[];
    }
    if (!selectedSite.permissions.canCreateEventAndBook) {
        bookingRows = @[];
    }
    NSArray *dateRows = self.event.startDate != nil? @[CHDEventEditRowDivider, CHDEventEditRowAllDay, CHDEventEditRowStartDate, CHDEventEditRowEndDate] : @[CHDEventEditRowDivider, CHDEventEditRowAllDay, CHDEventEditRowStartDate];
    
    NSArray *visibilityRows;
    if (self.event.visibility == CHDEventVisibilityPublicOnWebsite || self.event.visibility == CHDEventVisibilityOnlyInGroup) {
        visibilityRows = @[CHDEventEditRowDivider, CHDEventEditRowVisibility, CHDEventEditRowGroup];
    }
    else{
        if (self.event.groupIds.count > 0) {
            self.event.groupIds = [[NSArray alloc] init];
        }
        visibilityRows = @[CHDEventEditRowDivider, CHDEventEditRowVisibility];
    }
    
    NSArray *deleterows;
    if (self.event.canDelete) {
        deleterows = @[CHDEventEditRowDivider, CHDEventEditRowDelete, CHDEventEditRowDivider];
    } else{
        deleterows = @[CHDEventEditRowDivider];
    }
        self.sectionRows = @{CHDEventEditSectionTitle : @[CHDEventEditRowDivider, CHDEventEditRowTitle],
                             CHDEventEditSectionDate : dateRows,
                             CHDEventEditSectionRecipients : recipientsRows,
                             CHDEventEditSectionVisibility: visibilityRows,
                             CHDEventEditSectionBooking : bookingRows,
                             CHDEventEditSectionInternalNote : @[CHDEventEditRowDivider, CHDEventEditRowInternalNote],
                             CHDEventEditSectionSecureInformation :secureRows,
                             CHDEventEditSectionMisc : @[CHDEventEditRowDivider, CHDEventEditRowContributor, CHDEventEditRowLocation, CHDEventEditRowPrice],
                             CHDEventEditSectionDescription : @[CHDEventEditRowDivider, CHDEventEditRowDescription],
                             CHDEventEditSectionDivider : deleterows};
}

- (NSArray*)rowsForSectionAtIndex: (NSInteger) section {
    return self.sectionRows[self.sections[section]];
}

- (RACSignal*) saveEvent {
    [self storeDefaults];
    if (self.event.allDayEvent) {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: self.event.endDate];
        [components setHour: 23];
        [components setMinute: 59];
        [components setSecond: 59];
        self.event.endDate = [gregorian dateFromComponents: components];
    }
    return [self.saveCommand execute:RACTuplePack(@(self.newEvent), self.event)];
}

- (RACSignal*) deleteEvent {
    [self storeDefaults];
    return [self.deleteCommand execute:RACTuplePack(@(self.newEvent), self.event)];
}

- (NSString*) formatDate: (NSDate*) date allDay: (BOOL) isAllday {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = isAllday? NSDateFormatterNoStyle : NSDateFormatterShortStyle;

    return [dateFormatter stringFromDate:date];
}

-(void) storeDefaults {
    if(self.event.siteId){
        [[NSUserDefaults standardUserDefaults] chdSetDefaultSiteId:self.event.siteId];
    }
}

#pragma mark - Lazy Initialization

- (RACCommand *)saveCommand {
    if (!_saveCommand) {
        _saveCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(RACTuple *tuple) {
            BOOL newEvent = [tuple.first boolValue];
            CHDEvent *event = tuple.second;

            if (newEvent) {
                return [[CHDAPIClient sharedInstance] createEventWithEvent:event];
            }
            else {
                return [[CHDAPIClient sharedInstance] updateEventWithEvent:event];
            }
        }];
    }
    return _saveCommand;
}

- (RACCommand *)deleteCommand {
    if (!_deleteCommand) {
        _deleteCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(RACTuple *tuple) {
            CHDEvent *event = tuple.second;
            return [[CHDAPIClient sharedInstance] deleteEventWithId:event.eventId siteId:event.siteId];
        }];
    }
    return _deleteCommand;
}

@end
