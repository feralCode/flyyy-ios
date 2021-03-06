//
//  FLYOnboardingStartViewController.m
//  Flyy
//
//  Created by Xingxing Xu on 4/8/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYOnboardingStartViewController.h"
#import "UIColor+FLYAddition.h"
#import "FLYMainViewController.h"
#import "SDVersion.h"
#import "UIColor+FLYAddition.h"
#import "UIFont+FLYAddition.h"
#import "FLYOnboardingEnablePushNotificationViewController.h"

@interface FLYOnboardingStartViewController ()

@property (nonatomic) UIImageView *bgImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic) UIButton *actionButton;

@end

@implementation FLYOnboardingStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.bgImageView = [UIImageView new];
    self.bgImageView.image = [UIImage imageNamed:@"welcome_moving_bg_dot"];
    self.bgImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.bgImageView];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.text = LOC(@"FLYFirstTimeGetStartedTitle");
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont flyBlackFontWithSize:36.0f];
    self.titleLabel.textColor = [UIColor flyFirstTimeUserTextColor];
    [self.titleLabel sizeToFit];
    [self.view addSubview:self.titleLabel];
    
    self.descriptionLabel = [UILabel new];
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.text = LOC(@"FLYFirstTimeGetStartedDescriptionLabel");
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.font = [UIFont flyBlackFontWithSize:22.0f];
    self.descriptionLabel.textColor = [UIColor flyFirstTimeUserTextColor];
    [self.descriptionLabel sizeToFit];
    [self.view addSubview:self.descriptionLabel];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setTitle:LOC(@"FLYFirstTimeGetStartedActionButtonText") forState:UIControlStateNormal];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.actionButton setBackgroundColor:[UIColor flyFirstTimeUserTextColor]];
    self.actionButton.titleLabel.font = [UIFont flyBlackFontWithSize:22];
    self.actionButton.layer.cornerRadius = 4.0f;
    self.actionButton.contentEdgeInsets = UIEdgeInsetsMake(12, 85, 12, 85);
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.actionButton addTarget:self action:@selector(_handleTap) forControlEvents:UIControlEventTouchUpInside];
    [self.actionButton sizeToFit];
    [self.view addSubview:self.actionButton];
 
    [self _addViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)_addViewConstraints
{
    
    CGFloat actionButtonBottomPadding = -60;
    if ([SDVersion deviceSize] == Screen5Dot5inch) {
        actionButtonBottomPadding = -75;
    }
    
    [self.actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(actionButtonBottomPadding);
    }];
    
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.actionButton.mas_top).offset(-35);
        make.leading.lessThanOrEqualTo(self.view.mas_leading).offset(50);
        make.trailing.lessThanOrEqualTo(self.view.mas_trailing).offset(-50);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.descriptionLabel.mas_top).offset(-17);
    }];
    
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.bottom.equalTo(self.titleLabel.mas_top).offset(30);
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _startAnimateBackground];
}

- (void)_startAnimateBackground
{
    [UIView animateWithDuration:14.0f animations:^{
        [self.bgImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.view);
            make.bottom.equalTo(self.titleLabel.mas_top).offset(30);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)_handleTap
{
    FLYOnboardingEnablePushNotificationViewController *vc = [FLYOnboardingEnablePushNotificationViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Navigation bar and status bar
- (UIColor *)preferredNavigationBarColor
{
    return [UIColor clearColor];
}

- (UIColor*)preferredStatusBarColor
{
    return [UIColor clearColor];
}

@end
