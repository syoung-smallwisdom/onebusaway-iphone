//
//  OBAStopGroup.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopGroupWK.h"
#import "OBAStopWK.h"

NSString *const OBARequestIdRecentAndBookmarkStopGroups = @"recentAndBookmarkStopGroups";

@interface OBAStopGroupWK ()

@end

@implementation OBAStopGroupWK

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"name", @"groupType", @"stopIds", @"bookmarkNames"];
}

@end
