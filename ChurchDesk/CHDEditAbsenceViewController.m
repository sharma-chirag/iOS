//
//  CHDEditAbsenceViewController.m
//  ChurchDesk
//
//  Created by Chirag Sharma on 22/12/15.
//  Copyright © 2015 Shape A/S. All rights reserved.
//

#import "CHDEditAbsenceViewController.h"
#import <SHPNetworking/SHPAPIManager+ReactiveExtension.h>
#import "CHDEditAbsenceViewModel.h"
#import "CHDDividerTableViewCell.h"
#import "CHDEventTextFieldCell.h"
#import "CHDEventValueTableViewCell.h"
#import "CHDEvent.h"
#import "CHDUser.h"
#import "CHDEnvironment.h"
#import "CHDEventTextViewTableViewCell.h"
#import "SHPKeyboardAwareness.h"
#import "CHDListSelectorViewController.h"
#import "CHDGroup.h"
#import "CHDEventCategory.h"
#import "CHDEventSwitchTableViewCell.h"
#import "CHDDatePickerViewController.h"
#import "CHDEventAlertView.h"
#import "CHDAnalyticsManager.h"
#import "CHDStatusView.h"
#import "CHDSitePermission.h"
#import "UIImage+FontAwesome.h"

@interface CHDEditAbsenceViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) CHDEvent *event;
@property (nonatomic, strong) CHDEditAbsenceViewModel *viewModel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) CHDStatusView *statusView;

@end


@implementation CHDEditAbsenceViewController

- (instancetype)initWithEvent: (CHDEvent*) event {
    self = [super init];
    if (self) {
        _event = event;
        self.viewModel = [[CHDEditAbsenceViewModel alloc] initWithEvent: event];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.viewModel.newEvent ? NSLocalizedString(@"New Absence", @"") : NSLocalizedString(@"Edit Absence", @"");
    self.tableView.backgroundColor = [UIColor chd_lightGreyColor];
    
    [self setupSubviews];
    [self makeConstraints];
    [self setupBindings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[CHDAnalyticsManager sharedInstance] trackVisitToScreen: self.viewModel.newEvent? @"new event" :@"edit event"];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self didChangeSendingStatus:CHDStatusViewHidden];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) setupSubviews {
    [self.view addSubview:self.tableView];
    
    self.statusView = [[CHDStatusView alloc] init];
    self.statusView.successText = NSLocalizedString(@"The absence was saved", @"");
    self.statusView.processingText = NSLocalizedString(@"Saving absence..", @"");
    self.statusView.deletingText = @"...";
    self.statusView.deleteSuccessText = NSLocalizedString(@"Absence deleted successfully..", @"");
    self.statusView.autoHideOnSuccessAfterTime = 0;
    self.statusView.autoHideOnErrorAfterTime = 0;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStylePlain target:self action:@selector(saveAction:)];
    [saveButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    [saveButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor chd_menuDarkBlue],  NSForegroundColorAttributeName,nil] forState:UIControlStateDisabled];
    self.navigationItem.rightBarButtonItem = saveButtonItem;
}

- (void) makeConstraints {
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void) setupBindings {
   // [self shprac_liftSelector:@selector(titleAsFirstResponder) withSignal:[[self rac_signalForSelector:@selector(viewDidAppear:)] take:1]];
    
    [self.tableView shprac_liftSelector:@selector(reloadData) withSignal:[[RACSignal merge:@[RACObserve(self.viewModel, environment), RACObserve(self.viewModel, user), RACObserve(self.viewModel.event, siteId), RACObserve(self.viewModel.event, groupIds), RACObserve(self.viewModel.event, eventCategoryIds), RACObserve(self.viewModel.event, userIds), RACObserve(self.viewModel.event, startDate), RACObserve(self.viewModel.event, endDate), RACObserve(self.viewModel, sectionRows)]] ignore:nil]];
    
    [self rac_liftSelector:@selector(handleKeyboardEvent:) withSignals:[self shp_keyboardAwarenessSignal], nil];
    
    [self.navigationItem.leftBarButtonItem rac_liftSelector:@selector(setEnabled:) withSignals:[self.viewModel.saveCommand.executing not], nil];
    
    //Required -> Site, Group, title, startDate, endDate
    RACSignal *canSendSignal = [[RACSignal combineLatest:@[RACObserve(self.viewModel.event, siteId), RACObserve(self.viewModel.event, groupIds), RACObserve(self.viewModel.event, eventCategoryIds), RACObserve(self.viewModel.event, userIds), RACObserve(self.viewModel.event, startDate), RACObserve(self.viewModel.event, endDate), self.viewModel.saveCommand.executing]] map:^id(RACTuple *tuple) {
        RACTupleUnpack(NSString *siteId, NSArray *groupIds, NSArray *categoryIds, NSDate *startDate, NSDate *endDate) = tuple;
        
        return @(![siteId isEqualToString:@""] && groupIds != nil && (groupIds.count == 1) && categoryIds.count > 0 && startDate != nil && endDate != nil);
    }];
    [self.navigationItem.rightBarButtonItem rac_liftSelector:@selector(setEnabled:) withSignals:canSendSignal, nil];
}

#pragma mark - Actions

- (void) cancelAction: (id) sender {
    [Heap track:@"Cancel clicked from edit absence view"];
    [self.view endEditing:YES];
    [[CHDAnalyticsManager sharedInstance] trackEventWithCategory:self.viewModel.newEvent ? ANALYTICS_CATEGORY_NEW_EVENT : ANALYTICS_CATEGORY_EDIT_EVENT action:ANALYTICS_ACTION_BUTTON label:ANALYTICS_LABEL_CANCEL];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) saveAction: (id) sender {
    [self.view endEditing:YES];
    
    [[CHDAnalyticsManager sharedInstance] trackEventWithCategory:self.viewModel.newEvent ? ANALYTICS_CATEGORY_NEW_EVENT : ANALYTICS_CATEGORY_EDIT_EVENT action:ANALYTICS_ACTION_BUTTON label:ANALYTICS_LABEL_CREATE];
    if (self.viewModel.event.userIds.count > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Send Notifications?", @"") message:NSLocalizedString(@"Would you like to send notifications to the booked users?", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"No, just save", @"") otherButtonTitles:NSLocalizedString(@"Yes, save and send", @""), nil];
        alertView.tag = 111;
        alertView.delegate = self;
        [alertView show];
    } else{
        self.viewModel.event.sendNotifications = false;
        [self saveEvent];
    }
}

-(void) saveEvent{
    CHDEditAbsenceViewModel *viewModel = self.viewModel;
    [self didChangeSendingStatus:CHDStatusViewProcessing];
    [Heap track:@"Save absence submit"];
    @weakify(self)
    [[[self.viewModel saveEvent] catch:^RACSignal *(NSError *error) {
        //Handle double booking responses from the server
        @strongify(self)
        SHPHTTPResponse *response = error.userInfo[SHPAPIManagerReactiveExtensionErrorResponseKey];
        if (response.statusCode == 409) {
            [Heap track:@"Double booking conflict"];
            if ([response.body isKindOfClass:[NSDictionary class]]) {
                NSDictionary *result = response.body;
                NSString *htmlString = [result valueForKey:@"conflictHtml"];
                NSLog(@"html string %@", htmlString);
                BOOL permissionToDoubleBook = [viewModel.user siteWithId:viewModel.event.siteId].permissions.canDoubleBook;
                
                if(htmlString && permissionToDoubleBook) {
                    CHDEventAlertView *alertView = [[CHDEventAlertView alloc] initWithHtml:htmlString];
                    alertView.tag = 1020;
                    alertView.show = YES;
                    
                    RACSignal *statusSignal = [RACObserve(alertView, status) filter:^BOOL(NSNumber *iStatus) {
                        return iStatus.unsignedIntegerValue != CHDEventAlertStatusNone;
                    }];
                    
                    RAC(alertView, show) = [[statusSignal map:^id(id value) {
                        return @(NO);
                    }] takeUntil:alertView.rac_willDeallocSignal];
                    
                    return [statusSignal flattenMap:^RACStream *(NSNumber *iStatus) {
                        if (iStatus.unsignedIntegerValue == CHDEventAlertStatusCancel) {
                            [self didChangeSendingStatus:CHDStatusViewHidden];
                            return [RACSignal empty];
                        }
                        viewModel.event.allowDoubleBooking = YES;
                        return [viewModel saveEvent];
                    }];
                }
                else if(htmlString && !permissionToDoubleBook){
                    [self didChangeSendingStatus:CHDStatusViewHidden];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Doublebooking not allowed", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    return [RACSignal empty];
                }
                else {
                    [self didChangeSendingStatus:CHDStatusViewHidden];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:htmlString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    
                    return [RACSignal empty];
                }
            }
        }
        [[CHDAnalyticsManager sharedInstance] trackEventWithCategory:self.viewModel.newEvent ? ANALYTICS_CATEGORY_NEW_EVENT : ANALYTICS_CATEGORY_EDIT_EVENT action:ANALYTICS_ACTION_SENDING label:ANALYTICS_LABEL_ERROR];
        [self didChangeSendingStatus:CHDStatusViewHidden];
        return [RACSignal empty];
    }] subscribeNext:^(id x) {
        [self.view endEditing:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSavedEventBool];
        [self didChangeSendingStatus:CHDStatusViewSuccess];
    } error:^(NSError *error) {
        //Handle error after the initial error handling is done (Them it's something we don't know how to handle)
        [self didChangeSendingStatus:CHDStatusViewHidden];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:@"Please contact system administrator" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } completed:^{
        NSLog(@"Event done");
    }];
}

-(void) deleteEvent{
    [self didChangeSendingStatus:CHDStatusViewDeleting];
    @weakify(self)
    [[[self.viewModel deleteEvent] catch:^RACSignal *(NSError *error) {
        //Handle double booking responses from the server
        @strongify(self)
        SHPHTTPResponse *response = error.userInfo[SHPAPIManagerReactiveExtensionErrorResponseKey];
        [self didChangeSendingStatus:CHDStatusViewHidden];
        NSDictionary *result = response.body;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:[result objectForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        //        [[CHDAnalyticsManager sharedInstance] trackEventWithCategory:self.viewModel.newEvent ? ANALYTICS_CATEGORY_NEW_EVENT : ANALYTICS_CATEGORY_EDIT_EVENT action:ANALYTICS_ACTION_SENDING label:ANALYTICS_LABEL_ERROR];
        //        [self didChangeSendingStatus:CHDStatusViewHidden];
        return [RACSignal empty];
    }] subscribeNext:^(id x) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeleteEventBool];
        [self didChangeSendingStatus:CHDStatusViewDelete];
    } error:^(NSError *error) {
        //Handle error after the initial error handling is done (Them it's something we don't know how to handle)
        [self didChangeSendingStatus:CHDStatusViewHidden];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:@"Please contact system administrator" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } completed:^{
        NSLog(@"Event done");
    }];
}

- (void) handleKeyboardEvent: (SHPKeyboardEvent*) event {
    
    if (event.keyboardEventType == SHPKeyboardEventTypeShow) {
        event.originalOffset = self.tableView.contentOffset.y;
    }
    
    [UIView animateWithDuration:event.keyboardAnimationDuration delay:0 options:event.keyboardAnimationOptionCurve animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, event.keyboardFrame.size.height, 0);
        self.tableView.contentOffset = CGPointMake(0, event.keyboardEventType == SHPKeyboardEventTypeShow ? self.tableView.contentOffset.y - event.requiredViewOffset : event.originalOffset);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    } completion:nil];
}

-(void) didChangeSendingStatus: (CHDStatusViewStatus) status {
    self.statusView.currentStatus = status;
    
    if(status == CHDStatusViewProcessing || status == CHDStatusViewDeleting){
        self.statusView.show = YES;
        return;
    }
    if(status == CHDStatusViewSuccess){
        [self.view endEditing:YES];
        self.statusView.show = YES;
        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.statusView.show = NO;
            //View will be dissmissed when the event is set
            [self setEvent:self.viewModel.event];
        });
        return;
    }
    if(status == CHDStatusViewDelete){
        self.statusView.show = YES;
        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.statusView.show = NO;
            //View will be dissmissed when the event is set
            [self setEvent:self.viewModel.event];
        });
        return;
    }
    if(status == CHDStatusViewError){
        self.statusView.show = YES;
        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.statusView.show = NO;
        });
        return;
    }
    if(status == CHDStatusViewHidden){
        self.statusView.show = NO;
        return;
    }
}

-(void) titleAsFirstResponder {
    NSUInteger section = [self.viewModel.sections indexOfObject:CHDAbsenceEditSectionDate];
    NSUInteger row = [self.viewModel.sectionRows[CHDAbsenceEditSectionDate] indexOfObject:CHDAbsenceEditRowAllDay];
    
    if(section != NSNotFound && row != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        CHDEventTextFieldCell *cell = (CHDEventTextFieldCell*)[self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *row = [self.viewModel rowsForSectionAtIndex:indexPath.section][indexPath.row];
    if ([row isEqualToString:CHDAbsenceEditRowDivider]) {
        return 36;
    }
    return 49;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *row = [self.viewModel rowsForSectionAtIndex:indexPath.section][indexPath.row];
    CHDEvent *event = self.viewModel.event;
    CHDEnvironment *environment = self.viewModel.environment;
    CHDUser *user = self.viewModel.user;
    
    NSMutableArray *items = [NSMutableArray new];
    NSString *title = nil;
    BOOL selectMultiple = NO;
    [self.view endEditing:YES];
    if ([row isEqualToString:CHDAbsenceEditRowDelete]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete", @"") message:NSLocalizedString(@"Are you sure you want to delete this? This action cannot be undone.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Delete", @""), nil];
        alertView.tag = 222;
        alertView.delegate = self;
        [alertView show];
        return;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowParish]) {
        title = NSLocalizedString(@"Select Parish", @"");
        for (CHDSite *site in user.sites) {
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:site.name color:nil selected:(event.siteId.integerValue == site.siteId.integerValue) refObject:site.siteId]];
        }
    }
    else if ([row isEqualToString:CHDAbsenceEditRowGroup]) {
        title = NSLocalizedString(@"Select Group", @"");
        NSArray *groups = [environment groupsWithSiteId:event.siteId groupIds:[user siteWithId:event.siteId].groupIds];
        for (CHDGroup *group in groups) {
            BOOL selected = false;
            for (NSNumber *groupId in event.groupIds) {
                if (groupId.intValue == group.groupId.intValue) {
                    selected = true;
                }
            }
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:group.name color:nil selected:selected refObject:group.groupId]];
        }
    }
    else if ([row isEqualToString:CHDAbsenceEditRowCategories]) {
        title = NSLocalizedString(@"Select Categories", @"");
        selectMultiple = NO;
        NSArray *categories = [environment absenceCategoriesWithSiteId:event.siteId];
        for (CHDAbsenceCategory *category in categories) {
            BOOL selected = false;
            for (NSNumber *categoryId in event.eventCategoryIds) {
                if (categoryId.intValue == category.categoryId.intValue) {
                    selected = true;
                }
            }
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:category.name color:category.color selected:selected refObject:category.categoryId]];
        }
    }
    else if ([row isEqualToString:CHDAbsenceEditRowUsers]) {
        title = NSLocalizedString(@"Select Users", @"");
        selectMultiple = NO;
        NSArray *users = [environment usersWithSiteId:event.siteId];
        if ([user siteWithId:event.siteId].permissions.canCreateAbsenceAndBook) {
        for (CHDPeerUser *peerUser in users) {
            BOOL selected = false;
            for (NSNumber *userId in event.userIds) {
                if (userId.intValue == peerUser.userId.intValue) {
                    selected = true;
                }
            }
            NSString *title = peerUser.name;
            if ([title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
                title = peerUser.email;
            }
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:title imageURL:peerUser.pictureURL color:nil  selected:selected refObject:peerUser.userId]];
        }
        }
        else{
            BOOL selected = false;
            for (NSNumber *userId in event.userIds) {
                if (userId.intValue == user.userId.intValue) {
                    selected = true;
                }
            }
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:user.name imageURL:user.pictureURL color:nil  selected:selected refObject:user.userId]];
            }
    }
    else if ([row isEqualToString:CHDAbsenceEditRowResources]) {
        title = NSLocalizedString(@"Select Resources", @"");
        selectMultiple = YES;
        NSArray *resources = [environment resourcesWithSiteId:event.siteId];
        for (CHDResource *resource in resources) {
            BOOL selected = false;
            for (NSNumber *resourceId in event.resourceIds) {
                if (resourceId.intValue == resource.resourceId.intValue) {
                    selected = true;
                }
            }
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:resource.name color:resource.color selected:selected refObject:resource.resourceId]];
        }
    }
    else if ([row isEqualToString:CHDAbsenceEditRowVisibility]) {
        title = NSLocalizedString(@"Select Visibility", @"");
        NSArray *visibilityTypes = @[@(CHDEventVisibilityPublicOnWebsite), @(CHDEventVisibilityOnlyInGroup), @(CHDEventVisibilityDraft) ];
        for (NSNumber *nVisibility in visibilityTypes) {
            CHDEventVisibility visibility = nVisibility.unsignedIntegerValue;
            [items addObject:[[CHDListSelectorConfigModel alloc] initWithTitle:[event localizedVisibilityStringForVisibility:visibility] color:nil selected:event.visibility == visibility refObject:nVisibility]];
        }
    }
    else if([row isEqualToString:CHDAbsenceEditRowStartDate]){
        title = NSLocalizedString(@"Choose start date", @"");
    }else if([row isEqualToString:CHDAbsenceEditRowEndDate]){
        title = NSLocalizedString(@"Choose end date", @"");
    }
    
    if (items.count) {
        CHDListSelectorViewController *vc = [[CHDListSelectorViewController alloc] initWithSelectableItems:items];
        vc.title = title;
        vc.selectMultiple = selectMultiple;
        RACSignal *selectedSignal = [[[RACObserve(vc, selectedItems) map:^id(NSArray *selectedItems) {
            return [selectedItems valueForKey:@"refObject"];
        }] skip:1] takeUntil:vc.rac_willDeallocSignal];
        
        RACSignal *selectedSingleSignal = [selectedSignal map:^id(NSArray *selectedItems) {
            return selectedItems.firstObject;
        }];
        
        if ([row isEqualToString:CHDAbsenceEditRowParish]) {
            [self.viewModel.event shprac_liftSelector:@selector(setSiteId:) withSignal:selectedSingleSignal];
            
            RACSignal *nilWhenSelectedSignal = [[selectedSingleSignal distinctUntilChanged] mapReplace:nil];
            [self.viewModel.event shprac_liftSelector:@selector(setEventCategoryIds:) withSignal:nilWhenSelectedSignal];
            [self.viewModel.event shprac_liftSelector:@selector(setGroupIds:) withSignal:nilWhenSelectedSignal];
            [self.viewModel.event shprac_liftSelector:@selector(setResourceIds:) withSignal:nilWhenSelectedSignal];
            [self.viewModel.event shprac_liftSelector:@selector(setUserIds:) withSignal:nilWhenSelectedSignal];
        }
        else if ([row isEqualToString:CHDAbsenceEditRowGroup]) {
            [self.viewModel.event shprac_liftSelector:@selector(setGroupIds:) withSignal:selectedSignal];
        }
        else if ([row isEqualToString:CHDAbsenceEditRowCategories]) {
            [self.viewModel.event shprac_liftSelector:@selector(setEventCategoryIds:) withSignal:selectedSignal];
        }
        else if ([row isEqualToString:CHDAbsenceEditRowUsers]) {
            [self.viewModel.event shprac_liftSelector:@selector(setUserIds:) withSignal:selectedSignal];
        }
        else if ([row isEqualToString:CHDAbsenceEditRowResources]) {
            [self.viewModel.event shprac_liftSelector:@selector(setResourceIds:) withSignal:selectedSignal];
        }
        else if ([row isEqualToString:CHDAbsenceEditRowVisibility]) {
            [self.viewModel.event shprac_liftSelector:@selector(setVisibility:) withSignal:[selectedSingleSignal ignore:nil]];
        }
        
        CGPoint offset = self.tableView.contentOffset;
        [self.tableView rac_liftSelector:@selector(setContentOffset:) withSignals:[[[self rac_signalForSelector:@selector(viewDidLayoutSubviews)] takeUntil:vc.rac_willDeallocSignal] mapReplace:[NSValue valueWithCGPoint:offset]], nil];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if([row isEqualToString:CHDAbsenceEditRowStartDate]){
        
        CHDDatePickerViewController *vc = [[CHDDatePickerViewController alloc] initWithDate:self.viewModel.event.startDate allDay:self.viewModel.event.allDayEvent canSelectAllDay:NO];
        vc.title = title;
        [self.navigationController pushViewController:vc animated:YES];
        
        RACSignal *selectedDateSignal = [[RACObserve(vc, date) takeUntil:vc.rac_willDeallocSignal] skip:1];
        RACSignal *selectedAllDaySignal = [[RACObserve(vc, allDay) takeUntil:vc.rac_willDeallocSignal] skip:1];
        
        [self.viewModel.event rac_liftSelector:@selector(setStartDate:) withSignals:selectedDateSignal, nil];
        [self.viewModel.event rac_liftSelector:@selector(setAllDayEvent:) withSignals:selectedAllDaySignal, nil];
        
        CHDEvent *event = self.viewModel.event;
        [self.viewModel.event rac_liftSelector:@selector(setEndDate:) withSignals:[[selectedDateSignal takeWhileBlock:^BOOL(NSDate *startDate) {
            return event.endDate == nil || [[startDate earlierDate:event.endDate] isEqualToDate: event.endDate];
        }] map:^id(NSDate* startDate) {
            return [startDate dateByAddingTimeInterval:60*60];
        }], nil];
    }
    else if([row isEqualToString:CHDAbsenceEditRowEndDate]){
        if(self.viewModel.event.startDate) {
            CHDDatePickerViewController *vc = [[CHDDatePickerViewController alloc] initWithDate:self.viewModel.event.endDate allDay:self.viewModel.event.allDayEvent canSelectAllDay:NO];
            vc.title = title;
            [self.navigationController pushViewController:vc animated:YES];
            
            RACSignal *selectedDateSignal = [[RACObserve(vc, date) takeUntil:vc.rac_willDeallocSignal] skip:1];
            [self.viewModel.event rac_liftSelector:@selector(setEndDate:) withSignals:selectedDateSignal, nil];
            
            [self.viewModel.event shprac_liftSelector:@selector(setStartDate:) withSignal:[[selectedDateSignal filter:^BOOL(NSDate *endDate) {
                return endDate.timeIntervalSince1970 < event.startDate.timeIntervalSince1970;
            }] map:^id(NSDate *endDate) {
                return [endDate dateByAddingTimeInterval:-60*60];
            }]];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel rowsForSectionAtIndex:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *row = [self.viewModel rowsForSectionAtIndex:indexPath.section][indexPath.row];
    UITableViewCell *returnCell = nil;
    
    CHDEvent *event = self.viewModel.event;
    CHDEnvironment *environment = self.viewModel.environment;
    CHDUser *user = self.viewModel.user;
    
    CHDEditAbsenceViewModel *viewModel = self.viewModel;
    
    if ([row isEqualToString:CHDAbsenceEditRowDivider]) {
        CHDDividerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"divider" forIndexPath:indexPath];
        cell.hideTopLine = indexPath.section == 0 && indexPath.row == 0;
        cell.hideBottomLine = indexPath.section == [tableView numberOfSections]-1 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1;
        returnCell = cell;
    }
    else if([row isEqualToString:CHDAbsenceEditRowAllDay]){
        CHDEventSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"All day", @"");
        cell.dividerLineHidden = YES;
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-clock-o" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
        cell.valueSwitch.on = event.allDayEvent;
        [event shprac_liftSelector:@selector(setAllDayEvent:) withSignal:[[[cell.valueSwitch rac_signalForControlEvents:UIControlEventValueChanged] map:^id(UISwitch *valueSwitch) {
            return @(valueSwitch.on);
        }] takeUntil:cell.rac_prepareForReuseSignal]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    }
    else if ([row isEqualToString:CHDAbsenceEditRowStartDate]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Start", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-clock-o" backgroundColor:[UIColor clearColor] iconColor:[UIColor clearColor] andSize:CGSizeMake(17.0f, 17.0f)];
        [cell.valueLabel rac_liftSelector:@selector(setText:) withSignals:[[RACObserve(event, allDayEvent) map:^id(NSNumber *allDay) {
            return [viewModel formatDate:event.startDate allDay:event.allDayEvent];
        }] takeUntil:cell.rac_prepareForReuseSignal], nil];
        
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowEndDate]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"End", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-clock-o" backgroundColor:[UIColor clearColor] iconColor:[UIColor clearColor] andSize:CGSizeMake(17.0f, 17.0f)];
        [cell.valueLabel rac_liftSelector:@selector(setText:) withSignals:[[RACObserve(event, allDayEvent) map:^id(NSNumber *allDay) {
            return [viewModel formatDate:event.endDate allDay:event.allDayEvent];
        }] takeUntil:cell.rac_prepareForReuseSignal], nil];
        
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowParish]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Parish", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-exchange" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
        [cell.valueLabel shprac_liftSelector:@selector(setText:) withSignal: [[RACObserve(event, siteId) map:^id(NSString *siteId) {
            return [user siteWithId:siteId].name;
        }] takeUntil:cell.rac_prepareForReuseSignal]];
        
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowGroup]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Group", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-users" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
        if (event.groupIds.count == 0) {
            cell.valueLabel.text = @"";
        }
        else{
            cell.valueLabel.text = event.groupIds.count <= 1 ? [environment groupWithId:event.groupIds.firstObject siteId:event.siteId].name : [@(event.groupIds.count) stringValue];
        }        
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowCategories]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Category", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-calendar" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
        cell.valueLabel.text = event.eventCategoryIds.count <= 1 ? [environment absenceCategoryWithId:event.eventCategoryIds.firstObject siteId:event.siteId].name : [@(event.eventCategoryIds.count) stringValue];
        
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowLocation]) {
        CHDEventTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textfield" forIndexPath:indexPath];
        cell.textField.placeholder = NSLocalizedString(@"Location", @"");
        cell.textField.text = event.location;
        cell.textFieldMaxLength = 255;
        [event shprac_liftSelector:@selector(setLocation:) withSignal:[cell.textField.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        returnCell = cell;
    }
        else if ([row isEqualToString:CHDAbsenceEditRowUsers]) {
        CHDEventValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Users", @"");
        cell.iconImageView.image = [UIImage imageWithIcon:@"fa-user" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
        cell.valueLabel.text = event.userIds.count <= 1 ? [self.viewModel.environment userWithId:event.userIds.firstObject siteId:event.siteId].name : [@(event.userIds.count) stringValue];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        returnCell = cell;
    }
    else if ([row isEqualToString:CHDAbsenceEditRowSubstitute]) {
            CHDEventTextViewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textview" forIndexPath:indexPath];
            cell.placeholder = NSLocalizedString(@"Substitute", @"");
            cell.textView.text = event.substitute;
            cell.iconImageView.image = [UIImage imageWithIcon:@"fa-arrows-h" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
            cell.tableView = tableView;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [event shprac_liftSelector:@selector(setSubstitute:) withSignal:[cell.textView.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal]];
            cell.textView.text.length > 0 ? (cell.contentView.alpha = 1.0) : (cell.contentView.alpha = 0.5);
            returnCell = cell;
        }
    else if ([row isEqualToString:CHDAbsenceEditRowComments]) {
            CHDEventTextViewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textview" forIndexPath:indexPath];
            cell.placeholder = NSLocalizedString(@"Comments", @"");
            if (event.absenceComment) {
                cell.textView.text = event.absenceComment;
            }
            cell.iconImageView.image = [UIImage imageWithIcon:@"fa-comments" backgroundColor:[UIColor clearColor] iconColor:[UIColor chd_textDarkColor] andSize:CGSizeMake(17.0f, 17.0f)];
            cell.tableView = tableView;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [event shprac_liftSelector:@selector(setAbsenceComment:) withSignal:[cell.textView.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal]];
            cell.textView.text.length > 0 ? (cell.contentView.alpha = 1.0) : (cell.contentView.alpha = 0.5);
            returnCell = cell;
        }
    else if ([row isEqualToString:CHDAbsenceEditRowDelete]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"delete" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"Delete", @"");
        cell.textLabel.textColor = [UIColor chd_redColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.contentView.alpha = 1.0;
        returnCell = cell;
    }
    
    if ([returnCell respondsToSelector:@selector(setDividerLineHidden:)]) {
        [(CHDEventInfoTableViewCell*)returnCell setDividerLineHidden:YES];
    }
    
    return returnCell;
}

#pragma mark - AlertView delegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 111) {
        if (buttonIndex == 0)
        {
            self.viewModel.event.sendNotifications = false;
            [self saveEvent];
        }
        else
        {
            self.viewModel.event.sendNotifications = true;
            [self saveEvent];
        }
    } else if (alertView.tag == 222){
        if (buttonIndex == 1) {
            [self deleteEvent];
        }
    }
}

#pragma mark - Lazy Initialization

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.userInteractionEnabled = YES;
        _tableView.estimatedRowHeight = 49;
        
        [_tableView registerClass:[CHDEventTextFieldCell class] forCellReuseIdentifier:@"textfield"];
        [_tableView registerClass:[CHDEventValueTableViewCell class] forCellReuseIdentifier:@"value"];
        [_tableView registerClass:[CHDEventTextViewTableViewCell class] forCellReuseIdentifier:@"textview"];
        [_tableView registerClass:[CHDEventSwitchTableViewCell class] forCellReuseIdentifier:@"switch"];
        [_tableView registerClass:[CHDDividerTableViewCell class] forCellReuseIdentifier:@"divider"];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"delete"];
    }
    return _tableView;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateStyle = NSDateFormatterLongStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _dateFormatter;
}

@end
