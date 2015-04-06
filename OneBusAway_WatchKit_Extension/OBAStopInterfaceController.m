//
//  OBAStopInterfaceController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/4/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAStopInterfaceController.h"

#import "OBAStopWK.h"
#import "OBAArrivalAndDepartureWK.h"

#import "OBAStopRowController.h"

@interface OBAStopInterfaceController ()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

@property (nonatomic) OBAStopWK *stop;

@property (weak, nonatomic) NSTimer *timer;

@end


@implementation OBAStopInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // get the stop
    self.stop = [[OBAStopWK alloc] initWithDictionary:context];

    // set the title
    NSString *title = self.stop.name;

    if (self.stop.direction) {
        title = [NSString stringWithFormat:@"%@ - %@ %@", title, self.stop.direction, NSLocalizedString(@"Bound", @"Bound")];
    }

    [self.titleLabel setText:title];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    [self refreshArrivalsAndDeparturesForStop:self.stop];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateTable:(NSDictionary *)json stop:(OBAStopWK *)stop {
    [super updateTable:json stop:stop];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshArrivalsAndDeparturesForStop:) userInfo:nil repeats:NO];
}

@end
