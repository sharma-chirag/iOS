//
//  CHDDayCollectionViewCell.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 25/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CHDDayCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly) UILabel *weekdayLabel;
@property (nonatomic, readonly) UILabel *dayLabel;
@property (nonatomic, assign) BOOL picked;

@end
