//
//  OBAStopGroup.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

extern NSString *const OBARequestIdRecentAndBookmarkStopGroups;

@class OBAStopWK;

typedef NS_ENUM (NSInteger, OBAStopGroupType) {
    OBAStopGroupTypeRecent,
    OBAStopGroupTypeBookmark,
    OBAStopGroupTypeNearby
};

@interface OBAStopGroupWK : OBAModelObjectWK

@property (nonatomic) NSString *name;
@property (nonatomic) OBAStopGroupType groupType;
@property (nonatomic, copy) NSArray *stopIds; // NSString
@property (nonatomic, copy) NSDictionary *bookmarkNames;

@end
