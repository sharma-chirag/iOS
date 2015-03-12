//
// Created by Jakob Vinther-Larsen on 03/03/15.
// Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHDEnvironment.h"
#import "CHDMessage.h"

#import "CHDSite.h"

@class CHDAPICreate;

@interface CHDNewMessageViewModel : NSObject
@property (nonatomic, assign) NSString *message;
@property (nonatomic, assign) NSString *title;

@property (nonatomic, readonly) BOOL canSendMessage;

@property (nonatomic, readonly) BOOL canSelectParish;
@property (nonatomic, readonly) NSString *selectedParishName;
@property (nonatomic, assign) CHDSite *selectedSite;
@property (nonatomic, readonly) NSArray *selectableSites;

@property (nonatomic, readonly) BOOL canSelectGroup;
@property (nonatomic, assign) CHDGroup *selectedGroup;
@property (nonatomic, readonly) NSString *selectedGroupName;
@property (nonatomic, readonly) NSArray *selectableGroups;

@property (nonatomic, readonly) BOOL isSending;
@property (nonatomic, readonly) CHDAPICreate *createMessageAPIResponse;
-(void) sendMessage;
@end