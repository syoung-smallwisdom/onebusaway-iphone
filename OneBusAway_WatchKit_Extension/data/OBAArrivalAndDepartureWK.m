//
//  OBAArrivalAndDepartureWK.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/13/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureWK.h"

@implementation OBAArrivalAndDepartureWK

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // ignored - do not throw exception
}

- (NSArray *)dictionaryRepresentationKeys {
    return @[@"tripId", @"routeId"];    // keys used to define equality
}

- (NSDate *)time {
    long long bestTime = self.predictedDepartureTime ? : self.predictedArrivalTime ? : self.scheduledDepartureTime ? : self.scheduledArrivalTime;

    if (bestTime == 0) {
        return nil;
    }
    else {
        NSDate *time = [NSDate dateWithTimeIntervalSince1970:(bestTime / 1000)];
        return time;
    }
}

@end
