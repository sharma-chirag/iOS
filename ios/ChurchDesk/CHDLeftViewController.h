//
//  CHDLeftViewController.h
//  ChurchDesk
//
//  Created by Jakob Vinther-Larsen on 17/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHDLeftViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource>
- (instancetype) initWithMenuItems: (NSArray *) items;
@property (nonatomic, strong) NSArray* menuItems;
@end
