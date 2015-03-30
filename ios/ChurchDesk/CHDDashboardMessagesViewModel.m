//
//  CHDDashboardMessagesViewModel.m
//  ChurchDesk
//
//  Created by Jakob Vinther-Larsen on 25/02/15.
//  Copyright (c) 2015 Shape A/S. All rights reserved.
//

#import "CHDDashboardMessagesViewModel.h"
#import "CHDAPIClient.h"
#import "CHDEnvironment.h"
#import "CHDUser.h"
#import "CHDMessage.h"

@interface CHDDashboardMessagesViewModel ()
@property (nonatomic) BOOL canFetchNewMessages;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) CHDEnvironment *environment;
@property (nonatomic, strong) CHDUser* user;

@property (nonatomic, strong) RACCommand *readCommand;
@property (nonatomic, strong) RACCommand *getMessagesCommand;
@end

@implementation CHDDashboardMessagesViewModel

- (instancetype)initWaitForSearch: (BOOL) waitForSearch {
    _waitForSearch = waitForSearch;
    return [self initWithUnreadOnly:NO];
}

- (instancetype)initWithUnreadOnly: (BOOL) unreadOnly {
    self = [super init];
    if (self) {
        self.unreadOnly = unreadOnly;
        self.canFetchNewMessages = YES;
        CHDAPIClient *apiClient = [CHDAPIClient sharedInstance];
        
        //Inital model signal
        RACSignal *initialModelSignal = [[RACObserve(self, unreadOnly) filter:^BOOL(NSNumber *iUnreadnly) {
            return iUnreadnly.boolValue;
        }] flattenMap:^RACStream *(id value) {
            return [[apiClient getUnreadMessages] catch:^RACSignal *(NSError *error) {
                return [RACSignal empty];
            }];
        }];
        
        
        //Update signal
        
        RACSignal *updateSignal = [[[RACObserve(self, unreadOnly) filter:^BOOL(NSNumber *iUnreadnly) {
            return iUnreadnly.boolValue;
        }] flattenMap:^RACStream *(id value) {
            return [[apiClient.manager.cache rac_signalForSelector:@selector(invalidateObjectsMatchingRegex:)] filter:^BOOL(RACTuple *tuple) {
                NSString *regex = tuple.first;
                NSString *resourcePath = [apiClient resourcePathForGetUnreadMessages];
                return [regex rangeOfString:resourcePath].location != NSNotFound;
            }];
        }] flattenMap:^RACStream *(id value) {
            return [[apiClient getUnreadMessages] catch:^RACSignal *(NSError *error) {
                return [RACSignal empty];
            }];
        }];
        
        RACSignal *fetchAllMessagesSignal = [RACObserve(self, unreadOnly) filter:^BOOL(NSNumber *nUnreadOnly) {
            return !nUnreadOnly.boolValue;
        }];
        if (self.waitForSearch) {
            [self rac_liftSelector:@selector(fetchMoreMessagesWithQuery:continuePagination:) withSignals:[fetchAllMessagesSignal flattenMap:^RACStream *(id value) {
                return [RACObserve(self, searchQuery) filter:^BOOL(NSString *searchQuery) {
                    return searchQuery.length > 0;
                }];
            }], [RACSignal return:@NO], nil];
        }
        else {
            [self shprac_liftSelector:@selector(fetchMoreMessages) withSignal:fetchAllMessagesSignal];
        }
        
        [self rac_liftSelector:@selector(parseMessages:) withSignals:[RACSignal merge:@[initialModelSignal, updateSignal]], nil];
        
        
        RAC(self, user) = [[apiClient getCurrentUser] catch:^RACSignal *(NSError *error) {
            return [RACSignal empty];
        }];

        RAC(self, environment) = [[apiClient getEnvironment] catch:^RACSignal *(NSError *error) {
            return [RACSignal empty];
        }];
    }
    return self;
}

- (BOOL)removeMessageWithIndex:(NSUInteger)idx {
    if(self.messages.count < idx){return NO;}

    NSMutableArray *messages = [[NSMutableArray alloc] initWithArray:self.messages];
    [messages removeObjectAtIndex:idx];

    self.messages = [messages copy];
    return YES;
}


-(RACSignal*) setMessageAsRead:(CHDMessage *)message {
    message.read = YES;
    return [self.readCommand execute:RACTuplePack(message)];
}

-(RACCommand*)readCommand{
    if(!_readCommand){
        _readCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(RACTuple *tuple) {
            CHDMessage *message = tuple.first;

            return [[[CHDAPIClient sharedInstance] setMessageAsRead:message.messageId siteId:message.siteId] catch:^RACSignal *(NSError *error) {
                return [RACSignal empty];
            }];
        }];
    }
    return _readCommand;
}


- (NSString*) authorNameWithId: (NSNumber*) authorId authorSiteId: (NSString*) siteId {
    CHDPeerUser *user = [self.environment userWithId:authorId siteId:siteId];
    return user.name;
}

- (RACCommand*) getMessagesCommand {
    if(!_getMessagesCommand){
        _getMessagesCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(RACTuple *tuple) {
            NSDate *date = tuple.first;
            NSString *query = tuple.second;

            return [[[CHDAPIClient sharedInstance] getMessagesFromDate:date limit:50 query:query] catch:^RACSignal *(NSError *error) {
                return [RACSignal empty];
            }];
        }];
    }
    return _getMessagesCommand;
}

- (void) fetchMoreMessages {
    [self fetchMoreMessagesWithQuery:self.searchQuery continuePagination:NO];
}

- (void) fetchMoreMessagesWithQuery: (NSString*) query continuePagination: (BOOL) continuePagination {
    CHDMessage *message = continuePagination ? self.messages.lastObject : nil;
    [self fetchMoreMessagesFromDate: message != nil ? [message.lastActivityDate dateByAddingTimeInterval:-1.0] : [NSDate date] withQuery:query continuePagination:continuePagination];
}

- (void) fetchMoreMessagesFromDate: (NSDate*) date {
    [self fetchMoreMessagesFromDate:date withQuery:nil continuePagination:YES];
}

- (void) fetchMoreMessagesFromDate: (NSDate*) date withQuery: (NSString*) query continuePagination: (BOOL) continuePagination {
    if(self.unreadOnly || !self.canFetchNewMessages){return;}
    NSLog(@"Fetch messages from %@", date);
    [self rac_liftSelector:@selector(parseMessages:append:) withSignals:[self.getMessagesCommand execute:RACTuplePack(date, query)], [RACSignal return:@(continuePagination)], nil];
}

- (void) parseMessages: (NSArray*) messages append: (BOOL) append {
    NSLog(@"Parsing messages %i", (uint) messages.count);
    self.canFetchNewMessages = self.waitForSearch || messages.count > 0;

    NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(CHDMessage *message1, CHDMessage *message2) {
        return [message2.lastActivityDate compare:message1.lastActivityDate];
    }];

    if (self.unreadOnly || self.waitForSearch){
        self.messages = sortedMessages;
    }
    else {
        self.messages = [(self.messages ?: @[]) arrayByAddingObjectsFromArray:sortedMessages];
    }
}

- (void) reloadUnread {
    CHDAPIClient *apiClient = [CHDAPIClient sharedInstance];
    NSString *resoursePath = [apiClient resourcePathForGetUnreadMessages];
    [[[apiClient manager] cache] invalidateObjectsMatchingRegex:resoursePath];
}

-(void) reloadAll {
    CHDAPIClient *apiClient = [CHDAPIClient sharedInstance];
    NSString *resoursePath = [apiClient resourcePathForGetMessagesFromDate];
    [[[apiClient manager] cache] invalidateObjectsMatchingRegex:resoursePath];

    [self rac_liftSelector:@selector(setMessages:) withSignals:[[[self.getMessagesCommand execute:RACTuplePack([NSDate date])] filter:^BOOL(NSArray *messages) {
        return messages.count > 0;
    }] map:^id(NSArray *messages) {
        NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(CHDMessage *message1, CHDMessage *message2) {
            return [message2.lastActivityDate compare:message1.lastActivityDate];
        }];
        return sortedMessages;
    }], nil];
}

@end
