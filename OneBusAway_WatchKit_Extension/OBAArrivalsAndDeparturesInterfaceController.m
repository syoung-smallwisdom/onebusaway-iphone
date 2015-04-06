//
//  OBAArrivalsAndDeparturesInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/14/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAArrivalsAndDeparturesInterfaceController.h"

#import "OBAStopWK.h"
#import "OBAArrivalAndDepartureWK.h"

#import "OBAStopRowController.h"

#define kStopRouteDetailRowType @"Route Detail Row"

@interface OBAArrivalsAndDeparturesInterfaceController ()

@property (nonatomic) NSMutableOrderedSet *arrivalsAndDepartures;

@property (weak, nonatomic) NSURLSessionDataTask *dataTask;

@end

@implementation OBAArrivalsAndDeparturesInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Setup defaults
    self.arrivalsAndDepartures = [NSMutableOrderedSet new];
    self.maxCount = NSIntegerMax;
    self.minutesBefore = 5;
    self.minutesAfter = 35;
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

    [self.dataTask cancel];
    self.dataTask = nil;
}

- (NSArray *)filteredRouteIds {
    return nil;
}

- (void)refreshArrivalsAndDeparturesForStop:(OBAStopWK *)stop {
    NSString *urlString = [NSString stringWithFormat:@"%@&minutesBefore=%@&minutesAfter=%@", stop.url, @(self.minutesBefore), @(self.minutesAfter)];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];

    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

    __weak typeof(self) weakSelf = self;
    NSURLSession *session = [NSURLSession sharedSession];
    self.dataTask = [session dataTaskWithRequest:request
                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                   if (error) {
                                   [weakSelf.messageLabel
                                   setText:[error localizedDescription]];
                                   }
                                   else {
                                   NSError *jsonError;
                                   NSDictionary *json = [NSJSONSerialization              JSONObjectWithData:data
                                                                              options:0
                                                                                error:&jsonError];

                                   if (jsonError) {
                                   NSString *message = NSLocalizedString(@"Could not connect to server.", @"ould not connect to server.");
                                   [weakSelf.messageLabel
                                   setText:message];
                                   }

                                   [weakSelf              updateTable:json
                                          stop:stop];
                                   }
                               }];
    [self.dataTask resume];
}

- (void)updateTable:(NSDictionary *)json stop:(OBAStopWK *)stop {
    // Load table
    NSArray *nextArrivalsAndDepartures = [json valueForKeyPath:@"data.entry.arrivalsAndDepartures"];
    NSUInteger initialIndex = self.arrivalsAndDepartures.count;

    for (NSDictionary *ad in nextArrivalsAndDepartures) {
        OBAArrivalAndDepartureWK *arrival = [[OBAArrivalAndDepartureWK alloc] initWithDictionary:ad];

        if ([stop.filteredRouteIds containsObject:arrival.routeId]) {
            [self.arrivalsAndDepartures addObject:arrival];
        }
    }

    if (self.arrivalsAndDepartures.count > self.maxCount) {
        [self.arrivalsAndDepartures sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
        [self.arrivalsAndDepartures removeObjectsInRange:NSMakeRange(self.maxCount, self.arrivalsAndDepartures.count - self.maxCount)];
    }

    if (self.arrivalsAndDepartures.count > 0) {
        [self.messageLabel setText:@""];

        if (initialIndex == 0) {
            [self.table setNumberOfRows:self.arrivalsAndDepartures.count withRowType:kStopRouteDetailRowType];
        }
        else if (initialIndex < self.arrivalsAndDepartures.count) {
            [self.table insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(initialIndex, self.arrivalsAndDepartures.count - initialIndex)] withRowType:kStopRouteDetailRowType];
        }

        [self.arrivalsAndDepartures
         enumerateObjectsUsingBlock:^(OBAArrivalAndDepartureWK *item, NSUInteger idx, BOOL *stop) {
             OBAStopRowController *rowController = [self.table
                                                   rowControllerAtIndex:idx];
             [rowController.routeLabel
             setText:item.routeShortName];
             NSDate *time = [item time];
             [rowController.routeTimeLabel
             setText:[NSDateFormatter localizedStringFromDate:time
                                                    dateStyle:NSDateFormatterNoStyle
                                                    timeStyle:NSDateFormatterShortStyle]];
             [rowController.routeMinutesTimer
             setDate:time];
             [rowController.routeMinutesTimer start];
         }];
    }
    else {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"No arrivals in the next %i minutes", @"[arrivals count] == 0"), self.minutesAfter];
        [self.messageLabel setText:message];
    }
}

@end
