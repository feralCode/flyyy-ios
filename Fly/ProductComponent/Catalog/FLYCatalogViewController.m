//
//  FLYCatalogViewController.m
//  Flyy
//
//  Created by Xingxing Xu on 3/30/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYCatalogViewController.h"
#import "HMSegmentedControl.h"
#import "UIColor+FLYAddition.h"
#import "UIFont+FLYAddition.h"
#import "FLYNotificationViewController.h"
#import "FLYEverythingElseViewController.h"
#import "FLYSettingsViewController.h"
#import "FLYBarButtonItem.h"
#import "FLYFeedViewController.h"
#import "FLYAppStateManager.h"
#import "FLYUser.h"
#import "FLYMyRepliesViewController.h"
#import "FLYMyTopicsViewController.h"
#import "FLYNavigationController.h"
#import "JSBadgeView.h"
#import "FLYTopicDetailViewController.h"
#import "FLYProfileViewController.h"

#define kSegmentedControlHeight 44

@interface FLYCatalogViewController ()<UIScrollViewDelegate, FLYEverythingElseViewControllerDelegate, FLYNotificationViewControllerDelegate>

@property (nonatomic) HMSegmentedControl *segmentedControl;
@property (nonatomic) UIScrollView *scrollView;

@property (nonatomic) FLYNotificationViewController *notificationVC;
@property (nonatomic) FLYEverythingElseViewController *everythingElseVC;

@end

@implementation FLYCatalogViewController

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_usernameUpdated) name:kUsernameUpdatedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([FLYAppStateManager sharedInstance].currentUser) {
        self.title = [NSString stringWithFormat:@"@%@", [FLYAppStateManager sharedInstance].currentUser.userName];
    }
    
    self.view.backgroundColor = [UIColor flySettingBackgroundColor];
    CGFloat scrollViewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat scrollViewHeight = CGRectGetHeight(self.view.bounds) - kStatusBarHeight - kNavBarHeight - kSegmentedControlHeight;
    
    self.segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"Notifications", @"Everything Else"]];
    self.segmentedControl.backgroundColor = [UIColor flySettingBackgroundColor];
    self.segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 20, 0, 20);
    self.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
    self.segmentedControl.selectionIndicatorHeight = 2.0f;
    UIFont *font = [UIFont flyFontWithSize:15];
    [self.segmentedControl setTitleFormatter:^NSAttributedString *(HMSegmentedControl *segmentedControl, NSString *title, NSUInteger index, BOOL selected) {
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName : [UIColor flyBlue], NSFontAttributeName : font}];
        return attString;
    }];
    @weakify(self)
    [self.segmentedControl setIndexChangeBlock:^(NSInteger index) {
        @strongify(self)
        [self.scrollView setContentOffset:CGPointMake(scrollViewWidth * index, 0) animated:YES];
    }];
    [self.view addSubview:self.segmentedControl];
    
    //add scroll view
    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = [UIColor flySettingBackgroundColor];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(scrollViewWidth * 2, scrollViewHeight);
    self.scrollView.delegate = self;
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    [self.view addSubview:self.scrollView];
    
    
    self.notificationVC = [FLYNotificationViewController new];
    [self.scrollView addSubview:self.notificationVC.view];
    self.notificationVC.delegate = self;
    
    self.everythingElseVC = [FLYEverythingElseViewController new];
    [self.scrollView addSubview:self.everythingElseVC.view];
    self.everythingElseVC.delegate = self;
    
    
    [self _addViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([FLYAppStateManager sharedInstance].currentUser) {
        [[FLYAppStateManager sharedInstance] updateActivityCount];
    }
}

#pragma mark - Navigation bar
- (void)loadLeftBarButton
{
    if ([self.navigationController.viewControllers count] > 1) {
        FLYBackBarButtonItem *barItem = [FLYBackBarButtonItem barButtonItem:YES];
        __weak typeof(self)weakSelf = self;
        barItem.actionBlock = ^(FLYBarButtonItem *barButtonItem) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf _backButtonTapped];
        };
        self.navigationItem.leftBarButtonItem = barItem;
    }
}

- (void)_addViewConstraints
{
    CGFloat scrollViewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat scrollViewHeight = CGRectGetHeight(self.view.bounds) - kStatusBarHeight - kNavBarHeight - kSegmentedControlHeight;
    [self.segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.top.equalTo(self.view).offset(kStatusBarHeight + kNavBarHeight);
        make.trailing.equalTo(self.view);
        make.height.equalTo(@(kSegmentedControlHeight));
    }];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self.notificationVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.leading.equalTo(@(0));
        make.width.equalTo(@(scrollViewWidth));
        make.height.equalTo(@(scrollViewHeight));
    }];
    
    [self.everythingElseVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.leading.equalTo(self.notificationVC.view.mas_trailing);
        make.width.equalTo(@(scrollViewWidth));
        make.height.equalTo(@(scrollViewHeight));
    }];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = scrollView.contentOffset.x / pageWidth;
    
    [self.segmentedControl setSelectedSegmentIndex:page animated:YES];
}

#pragma mark - FLYEverythingelseDelegate
- (void)everythingElseCellTapped:(FLYUniversalViewController *)vc type:(FLYEverythingElseCellType)type
{
    if (type == FLYEverythingElseCellTypeSettings) {
        FLYSettingsViewController *vc = [FLYSettingsViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (type == FLYEverythingElseCellTypePosts) {
        FLYMyTopicsViewController *myPostsVC = [FLYMyTopicsViewController new];
        myPostsVC.isFullScreen = YES;
        self.flyNavigationController.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
        [self.flyNavigationController pushViewController:myPostsVC animated:YES];
    } else if (type == FLYEverythingElseCellTypeReplies) {
        FLYMyRepliesViewController *vc = [FLYMyRepliesViewController new];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - FLYNotificationControllerDelegate
- (void)visitTopicDetail:(FLYTopic *)topic
{
    FLYTopicDetailViewController *viewController = [[FLYTopicDetailViewController alloc] initWithTopic:topic];
    viewController.isBackFullScreen = YES;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)visitProfile:(FLYUser *)user
{
    FLYProfileViewController *profileVC = [[FLYProfileViewController alloc] initWithUserId:user.userId];
    [self.navigationController pushViewController:profileVC animated:YES];
}

#pragma mark - Navigation bar and status bar
- (UIColor *)preferredNavigationBarColor
{
    return [UIColor flyBlue];
}

- (UIColor*)preferredStatusBarColor
{
    return [UIColor flyBlue];
}

-(void)_usernameUpdated
{
    if ([FLYAppStateManager sharedInstance].currentUser) {
        self.title = [NSString stringWithFormat:@"@%@", [FLYAppStateManager sharedInstance].currentUser.userName];
    }
}

- (void)_backButtonTapped
{
    self.navigationController.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - kTabBarViewHeight);
    [self.view layoutIfNeeded];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
