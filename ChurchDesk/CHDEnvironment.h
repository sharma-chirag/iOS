//
//  CHDEnvironment.h
//  ChurchDesk
//
//  Created by Mikkel Selsøe Sørensen on 26/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDManagedModel.h"
#import "CHDEventCategory.h"
#import "CHDAbsenceCategory.h"
#import "CHDResource.h"
#import "CHDGroup.h"
#import "CHDPeerUser.h"

@interface CHDEnvironment : CHDManagedModel

@property (nonatomic, strong) NSArray *eventCategories;
@property (nonatomic, strong) NSArray *absenceCategories;
@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *users;

- (CHDEventCategory*) eventCategoryWithId: (NSNumber*) eventCategoryId siteId: (NSString*) siteId;
- (NSArray*) eventCategoriesWithSiteId: (NSString*) siteId;

- (CHDAbsenceCategory*) absenceCategoryWithId: (NSNumber*) absenceCategoryId siteId: (NSString*) siteId;
- (NSArray*) absenceCategoriesWithSiteId: (NSString*) siteId;

- (CHDResource*) resourceWithId: (NSNumber*) resourceId siteId: (NSString*) siteId;
- (NSArray*) resourcesWithSiteId: (NSString*) siteId;

- (CHDGroup*) groupWithId: (NSNumber*) groupId siteId: (NSString*) siteId;
- (NSArray*) groupsWithSiteId: (NSString*) siteId;
- (NSArray*) groupsWithSiteId: (NSString*) siteId groupIds: (NSArray*) groupIds;

- (CHDPeerUser*) userWithId: (NSNumber*) userId siteId: (NSString*) siteId;
- (NSArray*) usersWithSiteId: (NSString*) siteId groupIds: (NSArray*) groupIds;

@end
