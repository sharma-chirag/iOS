//
//  CHDResource.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 26/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDManagedModel.h"

@interface CHDResource : CHDManagedModel

@property (nonatomic, strong) NSNumber *resourceId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *site;
@property (nonatomic, strong) UIColor *color;


@end
