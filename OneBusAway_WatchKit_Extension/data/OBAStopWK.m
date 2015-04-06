//
//  OBAStopWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopWK.h"

@implementation OBAStopWK

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D c = { [self.latitude doubleValue], [self.longitude doubleValue] };

    return c;
}

@synthesize location = _location;
- (CLLocation *)location {
    if ((_location == nil) && (([self.latitude doubleValue] != 0) || ([self.longitude doubleValue] != 0))) {
        _location = [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue] longitude:[self.longitude doubleValue]];
    }

    return _location;
}

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"name", @"stopId", @"code", @"direction", @"latitude", @"longitude", @"filteredRouteIds", @"url"];
}

@end
