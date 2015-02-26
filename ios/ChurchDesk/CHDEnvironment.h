//
//  CHDEnvironment.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 26/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDManagedModel.h"

@class CHDEventCategory, CHDResource, CHDGroup, CHDPeerUser;

@interface CHDEnvironment : CHDManagedModel

@property (nonatomic, strong) NSArray *eventCategories;
@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *users;

- (CHDEventCategory*) eventCategoryWithId: (NSNumber*) eventCategoryId;
- (CHDResource*) resourceWithId: (NSNumber*) resourceId;
- (CHDGroup*) groupWithId: (NSNumber*) groupId;
- (CHDPeerUser*) userWithId: (NSNumber*) userId;

@end
