//
//  FLYMyTopicsViewController.m
//  Flyy
//
//  Created by Xingxing Xu on 4/3/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYMyTopicsViewController.h"
#import "FLYBarButtonItem.h"
#import "FLYNavigationController.h"
#import "FLYNavigationBar.h"
#import "FLYTopicService.h"

@interface FLYMyTopicsViewController ()

@end

@implementation FLYMyTopicsViewController

@synthesize isFullScreen = _isFullScreen;

- (instancetype)init
{
    if (self = [super init]) {
        [super setTopicService:[FLYTopicService myTopics]];
        self.feedType = FLYFeedTypeMyPosts;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Book" size:16];
    self.flyNavigationController.flyNavigationBar.titleTextAttributes =@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:titleFont};
    self.title = LOC(@"FLYMyPosts");
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

- (BOOL)hideLeftBarItem
{
    return YES;
}

- (BOOL)isFullScreen
{
    return _isFullScreen;
}

-(void)_backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
