//
//  CHDListSelectorViewController.h
//  ChurchDesk
//
//  Created by Jakob Vinther-Larsen on 02/03/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDAbstractViewController.h"
#import "CHDListSelectorDelegate.h"
#import "CHDListSelectorConfigModel.h"

@interface CHDListSelectorViewController : CHDAbstractViewController  <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, assign) BOOL selectMultiple;
@property (weak) id<CHDListSelectorDelegate> selectorDelegate;
@property (nonatomic, readonly) NSArray *selectedItems;
@property (nonatomic, assign) BOOL isTag;
@property (nonatomic, assign) BOOL saveClicked;

-(instancetype)initWithSelectableItems: (NSArray*) items;
@end
