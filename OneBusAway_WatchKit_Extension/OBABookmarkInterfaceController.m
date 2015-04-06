//
//  OBABookmarkInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBABookmarkInterfaceController.h"

#import "OBABookmarkRowController.h"

#import "OBAStopGroupWK.h"
#import "OBAStopWK.h"

@interface OBABookmarkInterfaceController ()

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *noBookmarksLabel;

@property (nonatomic) NSMutableArray *rowObjects;

@end


@implementation OBABookmarkInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    __weak typeof(self) weakSelf = self;
    [WKInterfaceController openParentApplication:@{ @"requestId": OBARequestIdRecentAndBookmarkStopGroups }
                                           reply:^(NSDictionary *userInfo, NSError *error) {
                                               [weakSelf loadTable:userInfo];
                                           }];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#define headerRowType @"Bookmark Group Header Row"
#define detailRowType @"Bookmark Row"

- (void)loadTable:(NSDictionary *)userInfo {
    NSArray *stopGroups = userInfo[@"stopGroups"];
    NSDictionary *stops = userInfo[@"stops"];
    NSDictionary *routes = userInfo[@"routes"];

    if ([stopGroups count] > 0) {
        // Hide the "no bookmarks" label if there are stops
        [self.noBookmarksLabel setText:@""];
    }

    self.rowObjects = [NSMutableArray new];

    for (NSDictionary *stopGroupDict in stopGroups) {
        OBAStopGroupWK *stopGroup = [[OBAStopGroupWK alloc] initWithDictionary:stopGroupDict];
        NSDictionary *headerRow = @{ @"rowType": headerRowType,
                                     @"name": stopGroup.name };
        [self.rowObjects addObject:headerRow];

        for (NSString *stopId in stopGroup.stopIds) {
            NSDictionary *stopDict = stops[stopId];

            if (stopDict) {
                OBAStopWK *stop = [[OBAStopWK alloc] initWithDictionary:stops[stopId]];
                NSArray *stopRoutes = [routes objectsForKeys:stop.filteredRouteIds notFoundMarker:[NSDictionary new]];

                NSArray *sortedRoutes = [[stopRoutes valueForKey:@"name"] sortedArrayUsingComparator:^(id a, id b) {
                                                                              return [a                                                           compare:b
                                                                                        options:NSNumericSearch];
                                                                          }];
                NSString *stopDetail = [sortedRoutes componentsJoinedByString:@", "];

                if (stop.direction) {
                    stopDetail = [NSString stringWithFormat:@"%@ - %@", stop.direction, stopDetail];
                }

                NSDictionary *stopRow = @{ @"rowType": detailRowType,
                                           @"name": stopGroup.bookmarkNames[stopId] ? : stop.name,
                                           @"detail": stopDetail,
                                           @"stop": stopDict };
                [self.rowObjects addObject:stopRow];
            }
        }
    }

    [self.table setRowTypes:[self.rowObjects valueForKey:@"rowType"]];
    [self.rowObjects
     enumerateObjectsUsingBlock:^(NSDictionary *rowInfo, NSUInteger idx, BOOL *stop) {
         OBABookmarkRowController *rowController = [self.table
                                                   rowControllerAtIndex:idx];
         [rowController.titleLabel
         setText:rowInfo[@"name"]];
         [rowController.detailLabel
         setText:rowInfo[@"detail"]];
     }];
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier
                            inTable:(WKInterfaceTable *)table
                           rowIndex:(NSInteger)rowIndex {
    return self.rowObjects.count > rowIndex ? self.rowObjects[rowIndex][@"stop"] : nil;
}

@end
