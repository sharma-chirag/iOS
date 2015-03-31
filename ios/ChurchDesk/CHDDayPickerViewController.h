//
//  CHDDayPickerViewController.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 25/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHDDayPickerViewController : UIViewController

@property (nonatomic, readonly) NSDate *referenceDate;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, readonly) NSUInteger currentWeekNumber;

- (void) scrollToDate: (NSDate*) date animated: (BOOL) animated;

@end
