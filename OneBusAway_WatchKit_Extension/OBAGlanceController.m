//
//  OBAGlanceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAGlanceController.h"

#import "OBAStopGroupWK.h"
#import "OBAStopWK.h"

@interface OBAGlanceController () <CLLocationManagerDelegate>

@property (nonatomic) NSMutableArray *stopGroups;
@property (nonatomic) NSMutableDictionary *stops;
@property (nonatomic) NSString *mostRecentStopId;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) OBAStopGroupWK *currentStopGroup;

@end


@implementation OBAGlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    self.maxCount = 2;

    __weak typeof(self) weakSelf = self;
    [WKInterfaceController openParentApplication:@{ @"requestId": OBARequestIdRecentAndBookmarkStopGroups }
                                           reply:^(NSDictionary *userInfo, NSError *error) {
                                               [weakSelf loadRecentAndBookmarkStopGroups:userInfo];
                                           }];
    [self startUpdatingLocation];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

    [self stopUpdatingLocation];
}

- (void)startUpdatingLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        [self.locationManager startUpdatingLocation];
    }
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self stopUpdatingLocation];
    self.currentLocation = [locations lastObject];

    if (self.stops.count > 0) {
        [self findAndUpdateNearestStop];
    }
}

- (void)loadRecentAndBookmarkStopGroups:(NSDictionary *)userInfo {
    NSArray *stopGroupDictionaries = userInfo[@"stopGroups"];

    self.stopGroups = [NSMutableArray new];

    for (NSDictionary *stopGroup in stopGroupDictionaries) {
        [self.stopGroups addObject:[[OBAStopGroupWK alloc] initWithDictionary:stopGroup]];
    }

    NSDictionary *stopsMap = userInfo[@"stops"];
    self.stops = [NSMutableDictionary new];

    for (NSString *stopId in [stopsMap allKeys]) {
        self.stops[stopId] = [[OBAStopWK alloc] initWithDictionary:stopsMap[stopId]];
    }

    self.mostRecentStopId = userInfo[@"mostRecentStopId"];

    if (self.stops.count == 0) {
        // If no stops then stop looking for current location and
        // just show the no info message
        [self stopUpdatingLocation];
    }
    else {
        // Otherwise, kick of a request to get info for most recent
        [self findAndUpdateNearestStop];
    }
}

- (void)findAndUpdateNearestStop {
    OBAStopGroupWK *stopGroupWK = nil;

    if (self.currentLocation) {
        // Get the stop group with the stop nearest to the current location
        CLLocationDistance nearest = CLLocationDistanceMax;

        for (OBAStopGroupWK *stopGroup in self.stopGroups) {
            for (NSString *stopId in stopGroup.stopIds) {
                OBAStopWK *stop = self.stops[stopId];
                CLLocationDistance dist = [self.currentLocation distanceFromLocation:stop.location];

                if (dist < nearest) {
                    nearest = dist;
                    stopGroupWK = stopGroup;
                }
            }
        }
    }
    else {
        // If current location is not set, then set to the most recent stop
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"%@ IN stopIds", self.mostRecentStopId];
        stopGroupWK = [[self.stopGroups filteredArrayUsingPredicate:filter] firstObject];
    }

    if (stopGroupWK && ![self.currentStopGroup isEqual:stopGroupWK]) {
        self.currentStopGroup = stopGroupWK;

        for (NSString *stopId in self.currentStopGroup.stopIds) {
            OBAStopWK *stop = self.stops[stopId];
            [self refreshArrivalsAndDeparturesForStop:stop];
        }
    }
}

@end
