//
//  OBAStopWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"
#import <CoreLocation/CoreLocation.h>

@interface OBAStopWK : OBAModelObjectWK

@property (nonatomic, strong) NSString *stopId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *direction;
@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSArray *filteredRouteIds;    // NSString

@property (nonatomic, strong) NSString *url;

@property (nonatomic, readonly) CLLocation *location;

@end
