//
//  FLYFeedOnBoardingView.h
//  Flyy
//
//  Created by Xingxing Xu on 4/8/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

@class FLYFeedTopicTableViewCell;
@class FLYFeedOnBoardingView;
@class FLYMainViewController;

@protocol FLYFeedOnBoardingDelegate <NSObject>

- (void)onboardingViewTapped:(FLYFeedOnBoardingView *)onboardingView;

@end

@interface FLYFeedOnBoardingView : UIView

@property (nonatomic) FLYFeedTopicTableViewCell *cellToExplain;
@property (nonatomic) UIView *showInView;
@property (nonatomic, weak) id<FLYFeedOnBoardingDelegate> delegate;
@property (nonatomic) FLYMainViewController *mainViewController;

- (instancetype)initWithCell:(FLYFeedTopicTableViewCell *)onboardingCell;
+ (UIView *)showFeedOnBoardViewWithCellToExplain:(FLYFeedTopicTableViewCell *)cell mainVC:(FLYMainViewController *)mainVC;

@end
