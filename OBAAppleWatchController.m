//
//  OBAAppleWatchController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAAppleWatchController.h"
#import "OBAApplicationDelegate.h"

#import "OBAModelDAO.h"
#import "OBABookmarkGroup.h"
#import "OBABookmarkV2.h"
#import "OBAStopAccessEventV2.h"
#import "OBARouteV2.h"

#import "OBAStopGroupWK.h"
#import "OBAStopWK.h"
#import "OBARouteWK.h"

@implementation OBAAppleWatchController

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)handleWatchKitExtensionRequestForAppDelegate:(OBAApplicationDelegate *)appDelegate
                                            userInfo:(NSDictionary *)userInfo
                                               reply:(void (^)(NSDictionary *replyInfo))reply {
    NSString *requestId = userInfo[@"requestId"];

    if ([requestId isEqualToString:OBARequestIdRecentAndBookmarkStopGroups]) {
        [self requestRecentAndBookmarkStopGroupsForAppDelegate:appDelegate reply:reply];
    }
    else {
        reply(@{ @"status": @"unknownRequestId" });
    }
}

- (void)requestRecentAndBookmarkStopGroupsForAppDelegate:(OBAApplicationDelegate *)appDelegate reply:(void (^)(NSDictionary *replyInfo))reply {
    NSMutableSet *allStopIds = [NSMutableSet new];
    __block NSMutableArray *stopGroups = [NSMutableArray new];

    // Add bookmarks
    NSArray *bookmarkGroups = [self bookmarkGroupsForAppDelegate:appDelegate];

    for (OBAStopGroupWK *stopGroup in bookmarkGroups) {
        [stopGroups addObject:[stopGroup dictionaryRepresentation]];
        [allStopIds addObjectsFromArray:stopGroup.stopIds];
    }

    // Add most recent stop if not already included
    OBAStopGroupWK *mostRecentStopGroup = [self mostRecentStopGroupForAppDelegate:appDelegate];
    NSInteger countBefore = allStopIds.count;
    [allStopIds unionSet:[NSSet setWithArray:mostRecentStopGroup.stopIds]];

    if (countBefore < allStopIds.count) {
        [stopGroups insertObject:[mostRecentStopGroup dictionaryRepresentation] atIndex:0];
    }

    // Get stop info for each stopId in the list
    __block NSMutableDictionary *stops = [NSMutableDictionary new];
    __block NSMutableDictionary *routes = [NSMutableDictionary new];

    //create a dispatch group so we return when all the operation have completed
    dispatch_group_t dataRequestGroup = dispatch_group_create();

    OBAModelService *service = appDelegate.modelService;

    for (NSString *stopId in allStopIds) {
        dispatch_group_enter(dataRequestGroup);

        OBAStopPreferencesV2 *prefs = [appDelegate.modelDao stopPreferencesForStopWithId:stopId];
        [service requestStopForId:stopId
                  completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
                      OBAEntryWithReferencesV2 *entry = responseData;
                      OBAStopV2 *stop = entry.entry;

                      OBAStopWK *stopWK = [[OBAStopWK alloc] init];
                      stopWK.stopId = stopId;
                      stopWK.name = stop.name;
                      stopWK.code = stop.code;
                      stopWK.direction = stop.direction;
                      stopWK.latitude = stop.latitude;
                      stopWK.longitude = stop.longitude;
                      NSMutableSet *filteredRoutes = [NSMutableSet setWithArray:stop.routeIds];

                      if (prefs.routeFilter) {
                      [filteredRoutes minusSet:prefs.routeFilter];
                      }

                      stopWK.filteredRouteIds = [filteredRoutes allObjects];

                      NSURL *url = [appDelegate.modelService
                          urlForStopWithArrivalsAndDeparturesForId:stopId];
                      stopWK.url = [url absoluteString];

                      stops[stopId] = [stopWK dictionaryRepresentation];

                      for (OBARouteV2 *route in stop.routes) {
                      if (route.routeId && [stopWK.filteredRouteIds
                                      containsObject:route.routeId]) {
                      OBARouteWK *routeWK = [[OBARouteWK alloc] init];
                      routeWK.routeId = route.routeId;
                      routeWK.name = route.safeShortName ? : route.longName;
                      routeWK.routeType = route.routeType;
                      routes[route.routeId] = [routeWK dictionaryRepresentation];
                      }
                      }

                      dispatch_group_leave(dataRequestGroup);
                  }];
    }

    // wait for all requests to complete then send reply
    dispatch_group_notify(dataRequestGroup, dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{ @"stopGroups": [stopGroups copy],
                                    @"stops": [stops copy],
                                    @"routes": [routes copy],
                                    @"mostRecentStopId": [mostRecentStopGroup.stopIds firstObject] ? : @"", };
        reply(userInfo);
    });
}

- (OBAStopGroupWK *)mostRecentStopGroupForAppDelegate:(OBAApplicationDelegate *)appDelegate {
    OBAStopGroupWK *stopGroup = nil;
    OBAStopAccessEventV2 *event = [appDelegate.modelDao.mostRecentStops firstObject];

    if (event) {
        stopGroup = [[OBAStopGroupWK alloc] init];
        stopGroup.groupType = OBAStopGroupTypeRecent;
        stopGroup.name = NSLocalizedString(@"Most Recent Stop", @"Most Recent Stop");
        stopGroup.stopIds = event.stopIds;
        stopGroup.bookmarkNames = @{ [event.stopIds firstObject]: [OBAAppleWatchController shortenStopName:event.title] };
    }

    return stopGroup;
}

- (NSArray *)bookmarkGroupsForAppDelegate:(OBAApplicationDelegate *)appDelegate {
    NSMutableArray *stopGroups = [NSMutableArray new];
    NSArray *bookmarkGroups = appDelegate.modelDao.bookmarkGroups;

    if (appDelegate.modelDao.bookmarks.count > 0) {
        OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:NSLocalizedString(@"Bookmarks", @"Bookmarks")];
        [group.bookmarks addObjectsFromArray:appDelegate.modelDao.bookmarks];
        bookmarkGroups = [bookmarkGroups arrayByAddingObject:group];
    }

    for (OBABookmarkGroup *group in bookmarkGroups) {
        // create a stop group for this bookmark group
        OBAStopGroupWK *stopGroup = [[OBAStopGroupWK alloc] init];
        stopGroup.groupType = OBAStopGroupTypeBookmark;
        stopGroup.name = group.name;
        NSMutableArray *stopIds = [NSMutableArray new];
        NSMutableDictionary *bookmarkNames = [NSMutableDictionary new];

        for (OBABookmarkV2 *bookmark in group.bookmarks) {
            [stopIds addObjectsFromArray:bookmark.stopIds];
            bookmarkNames[[bookmark.stopIds firstObject]] = [OBAAppleWatchController shortenStopName:bookmark.name];
        }

        stopGroup.stopIds = stopIds;
        stopGroup.bookmarkNames = bookmarkNames;
        [stopGroups addObject:stopGroup];
    }

    return stopGroups;
}

+ (NSString *)shortenStopName:(NSString *)name {
    // shorten the default name used by the service by removing Ave, St, etc.
    NSArray *streetNames = @[@"St", @"Ave", @"Way", @"Rd", @"Ln", @"Ct", @"Dr", @"Aly"];
    NSMutableString *stopName = [name mutableCopy];

    for (NSString *streetName in streetNames) {
        [stopName replaceOccurrencesOfString:[NSString stringWithFormat:@" %@ ", streetName]
                                  withString:@" "
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(0, stopName.length)];
        NSInteger endLength = streetName.length + 1;
        [stopName replaceOccurrencesOfString:[NSString stringWithFormat:@" %@", streetName]
                                  withString:@""
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(stopName.length - endLength, endLength)];
    }

    NSRange bracketRange = [stopName rangeOfString:@" [" options:NSBackwardsSearch];

    if (bracketRange.location != NSNotFound) {
        if (bracketRange.location > 3) {
            bracketRange.length = stopName.length - bracketRange.location;
            [stopName replaceCharactersInRange:bracketRange withString:@""];
        }
    }

    return stopName;
}

@end
