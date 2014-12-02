//
//  FLYSingleGroupViewController.m
//  Fly
//
//  Created by Xingxing Xu on 12/1/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

#import "FLYSingleGroupViewController.h"
#import "FLYFeedViewController.h"

@interface FLYSingleGroupViewController ()

@property (nonatomic) FLYFeedViewController *feedViewController;

@property (nonatomic) BOOL didSetConstraints;


@end

@implementation FLYSingleGroupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _feedViewController = [FLYFeedViewController new];
    [self.view addSubview:_feedViewController.view];
    _feedViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [_feedViewController.view setNeedsUpdateConstraints];
    self.view.backgroundColor = [UIColor blueColor];
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (!_didSetConstraints) {
        [self _addViewConstraints];
        _didSetConstraints = YES;
    }
    [FLYUtilities printAutolayoutTrace];
}

- (void)_addViewConstraints
{
    [_feedViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.leading.equalTo(self.view);
            make.width.equalTo(self.view);
            make.height.equalTo(self.view);
    }];
}


@end
