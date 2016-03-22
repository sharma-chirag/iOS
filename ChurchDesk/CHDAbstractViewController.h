//
//  CHDAbstractViewController.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 25/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CHDDashboardTabBarViewController, CHDPeopleTabBarController;

@interface CHDAbstractViewController : UIViewController
@property (nonatomic, weak) CHDDashboardTabBarViewController *chd_tabbarViewController;
@property (nonatomic, weak) CHDPeopleTabBarController *chd_people_tabbarViewController;
@property (nonatomic) NSUInteger chd_tabbarIdx;
@end
