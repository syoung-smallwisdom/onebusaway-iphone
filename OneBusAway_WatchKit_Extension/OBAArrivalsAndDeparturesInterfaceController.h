//
//  OBAArrivalsAndDeparturesInterfaceController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/14/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@class OBAStopWK;

@interface OBAArrivalsAndDeparturesInterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *messageLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@property (nonatomic) NSUInteger minutesBefore;
@property (nonatomic) NSUInteger minutesAfter;
@property (nonatomic) NSInteger maxCount;

- (void)refreshArrivalsAndDeparturesForStop:(OBAStopWK *)stop;
- (void)updateTable:(NSDictionary *)json stop:(OBAStopWK *)stop;


@end
