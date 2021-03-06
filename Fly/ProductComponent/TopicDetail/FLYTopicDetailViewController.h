//
//  FLYTopicDetailViewController.h
//  Fly
//
//  Created by Xingxing Xu on 12/6/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

@class FLYTopic;
@class FLYTopicDetailTabbar;

#import "FLYUniversalViewController.h"

typedef NS_ENUM(NSInteger, FlyTopicDetailCellType) {
    FlyTopicCellSectionIndex = 0,
    FlyReplyCellSectionIndex
};

@interface FLYTopicDetailViewController : FLYUniversalViewController

@property (nonatomic) FLYTopicDetailTabbar *tabbar;
@property (nonatomic) BOOL isBackFullScreen;

@property (nonatomic) BOOL viewFrameStartBelowNavBar;

- (instancetype)initWithTopicId:(NSString *)topicId;
- (instancetype)initWithTopic:(FLYTopic *)topic;

@end
