//
//  OBAApplicationWKController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/5/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBAModelDAO.h"
#import "OBAStopGroup.h"

@interface OBAApplicationWKController : NSObject

+ (instancetype)sharedController;

@property (nonatomic,readonly) OBAModelDAO *modelDao;

@property (nonatomic) NSMutableArray *stopGroups;

@end
