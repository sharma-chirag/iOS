//
//  CHDNewMessageViewController.m
//  ChurchDesk
//
//  Created by Jakob Vinther-Larsen on 26/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDNewMessageViewController.h"
#import "CHDDividerTableViewCell.h"
#import "CHDNewMessageSelectorCell.h"
#import "CHDNewMessageTextViewCell.h"
#import "CHDNewMessageTextFieldCell.h"
#import "NSObject+SHPKeyboardAwareness.h"
#import "SHPKeyboardEvent.h"
#import "CHDListSelectorViewController.h"
#import "CHDNewMessageViewModel.h"
#import "CHDGroup.h"

typedef NS_ENUM(NSUInteger, newMessagesSections) {
    divider1Section,
    selectParishSection,
    selectGroupSection,
    devider2Section,
    titleInputSection,
    messageInputSection,
    newMessagesCountSections,
};

static NSString* kNewMessageDividerCell = @"newMessageDeviderCell";
static NSString* kNewMessageSelectorCell = @"newMessageSelectorCell";
static NSString* kNewMessageTextFieldCell = @"newMessagTextFieldCell";
static NSString* kNewMessageTextViewCell = @"newMessageTextViewCell";

@interface CHDNewMessageViewController ()
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) CHDNewMessageViewModel *messageViewModel;
@end

@implementation CHDNewMessageViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"New message", @"");
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem new] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(leftBarButtonTouch)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem new] initWithTitle:NSLocalizedString(@"Send", @"") style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonTouch)];

        self.messageViewModel = [CHDNewMessageViewModel new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self makeViews];
    [self makeConstraints];
    [self makeBindings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Bar button handlers
-(void) leftBarButtonTouch{
    //Cancel the creation of new message
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) rightBarButtonTouch{
    //create a new message
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if((newMessagesSections)indexPath.row == selectParishSection){
        if(self.messageViewModel.selectableSites.count > 0) {
            CHDListSelectorViewController *selectorViewController = [[CHDListSelectorViewController new] initWithSelectableItems:self.messageViewModel.selectableSites];
            selectorViewController.title = NSLocalizedString(@"Parish", @"");
            selectorViewController.selectMultiple = NO;
            selectorViewController.selectorDelegate = self;

            [self.navigationController pushViewController:selectorViewController animated:YES];
        }
    }

    if((newMessagesSections)indexPath.row == selectGroupSection){
        if(self.messageViewModel.selectableGroups.count > 0) {
            CHDListSelectorViewController *selectorViewController = [[CHDListSelectorViewController new] initWithSelectableItems:self.messageViewModel.selectableGroups];
            selectorViewController.title = NSLocalizedString(@"Group", @"");
            selectorViewController.selectMultiple = NO;
            selectorViewController.selectorDelegate = self;
            [self.navigationController pushViewController:selectorViewController animated:YES];
        }
    }
}

#pragma mark - TableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return newMessagesCountSections;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if((newMessagesSections)indexPath.row == divider1Section || (newMessagesSections)indexPath.row == devider2Section){
        CHDDividerTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kNewMessageDividerCell forIndexPath:indexPath];
        return cell;
    }
    if((newMessagesSections)indexPath.row == selectParishSection){
        CHDNewMessageSelectorCell* cell = [tableView dequeueReusableCellWithIdentifier:kNewMessageSelectorCell forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Parish", @"");
        cell.selectedLabel.text = self.messageViewModel.selectedParishName;
        return cell;
    }
    if((newMessagesSections)indexPath.row == selectGroupSection){
        CHDNewMessageSelectorCell* cell = [tableView dequeueReusableCellWithIdentifier:kNewMessageSelectorCell forIndexPath:indexPath];
        cell.titleLabel.text = NSLocalizedString(@"Group", @"");
        cell.selectedLabel.text = self.messageViewModel.selectedGroupName;
        cell.dividerLineHidden = YES;
        return cell;
    }
    if((newMessagesSections)indexPath.row == titleInputSection){
        CHDNewMessageTextFieldCell* cell = [tableView dequeueReusableCellWithIdentifier:kNewMessageTextFieldCell forIndexPath:indexPath];

        RAC(self.messageViewModel, title) = [cell.textField.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal];
        return cell;
    }
    if((newMessagesSections)indexPath.row == messageInputSection){
        CHDNewMessageTextViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kNewMessageTextViewCell forIndexPath:indexPath];
        cell.dividerLineHidden = YES;
        cell.tableView = tableView;

        RAC(self.messageViewModel, message) = [cell.textView.rac_textSignal takeUntil:cell.rac_prepareForReuseSignal];
        return cell;
    }
    return nil;
}

#pragma mark - Selector Delegate

- (void)chdListSelectorDidSelect:(CHDListSelectorConfigModel *)selection {
    if([selection.refObject isKindOfClass:[CHDGroup class] ]){
        self.messageViewModel.selectedGroup = (CHDGroup *)selection.refObject;
    }

    if([selection.refObject isKindOfClass:[CHDSite class] ]){
        self.messageViewModel.selectedSite = (CHDSite *)selection.refObject;
    }
}


#pragma mark - Lazy initialization

-(void) makeViews {
    [self.view addSubview:self.tableView];
}

-(void) makeConstraints {
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

-(void) makeBindings {
    [self rac_liftSelector:@selector(chd_willToggleKeyboard:) withSignals:[self shp_keyboardAwarenessSignal], nil];

    //Change the state of the send button
    RAC(self.navigationItem.rightBarButtonItem, enabled) = RACObserve(self.messageViewModel, canSendMessage);
    RAC(self.navigationItem.rightBarButtonItem, tintColor) = [RACObserve(self.navigationItem.rightBarButtonItem, enabled) map:^id(NSNumber *SelectedNumber) {
        return SelectedNumber.boolValue? [UIColor whiteColor] : [UIColor chd_textDarkColor];
    }];
}


-(UITableView*)tableView {
    if(!_tableView){
        _tableView = [UITableView new];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundView.backgroundColor = [UIColor chd_lightGreyColor];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 44;
        [_tableView registerClass:[CHDDividerTableViewCell class] forCellReuseIdentifier:kNewMessageDividerCell];
        [_tableView registerClass:[CHDNewMessageSelectorCell class] forCellReuseIdentifier:kNewMessageSelectorCell];
        [_tableView registerClass:[CHDNewMessageTextViewCell class] forCellReuseIdentifier:kNewMessageTextViewCell];
        [_tableView registerClass:[CHDNewMessageTextFieldCell class] forCellReuseIdentifier:kNewMessageTextFieldCell];

        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

#pragma mark - Keyboard

-(void) chd_willToggleKeyboard: (SHPKeyboardEvent*) keyboardEvent{
    CGFloat offset = 0;
    switch (keyboardEvent.keyboardEventType) {
        case SHPKeyboardEventTypeShow:

            //Set content inset
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardEvent.keyboardFrame.size.height, 0);

            // Keyboard will appear. Calculate the new offset from the provided offset
            offset = self.tableView.contentOffset.y - keyboardEvent.requiredViewOffset;

            // Save the current view offset into the event to retrieve it later
            keyboardEvent.originalOffset = self.tableView.contentOffset.y;

            break;
        case SHPKeyboardEventTypeHide:
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            // Keyboard will hide. Reset view offset to its state before keyboard appeared
            offset = keyboardEvent.originalOffset;

            break;
        default:
            break;
    }

    [UIView animateWithDuration:keyboardEvent.keyboardAnimationDuration
                          delay:0
                        options:keyboardEvent.keyboardAnimationOptionCurve
                     animations:^{
                         self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, offset);
                     } completion:nil];
}

@end
