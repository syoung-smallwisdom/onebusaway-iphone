//
//  OBAArrivalAndDepartureWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/13/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

@interface OBAArrivalAndDepartureWK : OBAModelObjectWK

@property (nonatomic) double distanceFromStop;

@property (nonatomic) long long predictedArrivalTime;
@property (nonatomic) long long predictedDepartureTime;
@property (nonatomic) long long scheduledArrivalTime;
@property (nonatomic) long long scheduledDepartureTime;

@property (nonatomic) NSString *tripId;

@property (nonatomic) NSString *routeId;
@property (nonatomic) NSString *routeShortName;

@property (nonatomic, readonly) NSDate *time;

@end
