//
//  OBAApplicationWKController.m
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAApplicationWKController.h"

@implementation OBAApplicationWKController

+ (instancetype)sharedController {
    static id sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[[self class] alloc] init];
    });
    return sharedController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
