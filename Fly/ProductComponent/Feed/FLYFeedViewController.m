//
//  FLYFeedViewController.m
//  Fly
//
//  Created by Xingxing Xu on 11/27/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FLYFeedViewController.h"
#import "FLYFeedTopicTableViewCell.h"
#import "FLYFilterHomeFeedSelectorViewController.h"
#import "FLYSingleGroupViewController.h"
#import "FLYInlineReplyView.h"
#import "FLYTopicDetailViewController.h"
#import "FLYBarButtonItem.h"
#import "FLYGroupViewController.h"
#import "FLYDownloadManager.h"
#import "FLYTopic.h"
#import "SVPullToRefresh.h"
#import "FLYAudioStateManager.h"
#import "FLYPlayableItem.h"
#import "UIColor+FLYAddition.h"
#import "AFHTTPRequestOperationManager.h"
#import "Dialog.h"
#import "STKAudioPlayer.h"
#import "SampleQueueId.h"
#import "FLYDownloadableAudio.h"

@interface FLYFeedViewController () <UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, FLYFeedTopicTableViewCellDelegate, STKAudioPlayerDelegate>

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) FLYInlineReplyView *inlineReplyView;
@property (nonatomic) UITableView *feedTableView;

//used for pagination load more
@property (nonatomic) NSString *beforeTimestamp;

@property (nonatomic) NSMutableArray *posts;
@property (nonatomic) BOOL didSetConstraints;
@property (nonatomic) enum RequestType requestType;

@property (nonatomic) STKAudioPlayer *audioPlayer;

@end

@implementation FLYFeedViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadComplete:)
                                                     name:kDownloadCompleteNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_newPostReceived:)
                                                     name:kNewPostReceivedNotification object:nil];
        
        
        NSError *error;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        
        _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = NO, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000} }];
        _audioPlayer.meteringEnabled = YES;
        _audioPlayer.volume = 1;
        _audioPlayer.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _posts = [NSMutableArray new];
    
    self.view.backgroundColor = [UIColor flyBackgroundColorBlue];
    if (![self isKindOfClass:[FLYGroupViewController class]]) {
        [self _loadLeftBarItem];
    }
    [self _addInlineReplyBar];
    
    _feedTableView = [UITableView new];
    _feedTableView.backgroundColor = [UIColor clearColor];
    _feedTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _feedTableView.dataSource = self;
    _feedTableView.delegate = self;
    [_feedTableView registerClass:[FLYFeedTopicTableViewCell class] forCellReuseIdentifier:@"feedPostCellIdentifier"];
    [self.view addSubview:_feedTableView];
    
    _feedTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _feedTableView.scrollsToTop = YES;
    
    _backgroundView = [UIView new];
    _backgroundView.userInteractionEnabled = NO;
    _backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_backgroundView];
    
    //init audio recording view controller
    

    @weakify(self)
    [_feedTableView addPullToRefreshWithActionHandler:^{
        @strongify(self)
        self.requestType = RequestTypeNormal;
        [self _fetchHomeTimelineService:nil requestType:RequestTypeNormal];
    }];
    
    // setup infinite scrolling
    [_feedTableView addInfiniteScrollingWithActionHandler:^{
        @strongify(self)
        self.requestType = RequestTypeLoadMore;
        [self _fetchHomeTimelineService:self.beforeTimestamp requestType:RequestTypeLoadMore];
    }];

    [_feedTableView triggerPullToRefresh];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"timeline_view"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self clearCurrentPlayingItem];
}

- (void)_addInlineReplyBar
{
    _inlineReplyView = [FLYInlineReplyView new];
    _inlineReplyView.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    _inlineReplyView.backgroudTappedBlock = ^(FLYInlineReplyView *view){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf _moveInlineReplyViewOffScreen];
    };
    [self.view addSubview:_inlineReplyView];
}

- (void)_loadLeftBarItem
{
    FLYGroupsButtonItem *leftBarItem = [FLYGroupsButtonItem barButtonItem:YES];
    self.navigationItem.leftBarButtonItem = leftBarItem;
}

- (void)loadRightBarButton
{
    UIImage *autoPlayImage = [UIImage imageNamed:@"icon_homefeed_playall"];
    UIButton *autoPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [autoPlayButton setImage:autoPlayImage forState:UIControlStateNormal];
    [autoPlayButton addTarget:self action:@selector(_autoPlayButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [autoPlayButton setFrame:CGRectMake(0, 0, 39, 39)];
    UIBarButtonItem *autoPlayItem = [[UIBarButtonItem alloc] initWithCustomView:autoPlayButton];
    
    UIImage *profileButtonImage = [UIImage imageNamed:@"icon_homefeed_profile"];
    UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [profileButton setImage:profileButtonImage forState:UIControlStateNormal];
    [profileButton addTarget:self action:@selector(_profileButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [profileButton setFrame:CGRectMake(0, 0, 39, 39)];
    UIBarButtonItem *profileItem = [[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItems = @[profileItem, autoPlayItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowRecordIconNotification object:self];
//    [self updateViewConstraints];
}

- (void)updateViewConstraints
{
    [_backgroundView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.leading.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [_feedTableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kStatusBarHeight + kNavBarHeight);
        make.leading.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [_inlineReplyView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(CGRectGetHeight(self.view.bounds));
        make.leading.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
    }];
    [super updateViewConstraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

#pragma mark - fetch home timeline API
- (void)_fetchHomeTimelineService:(NSString *)before requestType:(enum RequestType)requestType
{
    NSString *partialUrl;
    if (requestType == RequestTypeNormal) {
        partialUrl = [NSString stringWithFormat:@"topics?limit=%d", kTopicPaginationCount];
    } else {
        partialUrl = [NSString stringWithFormat:@"topics?limit=%d&before=%@", kTopicPaginationCount, self.beforeTimestamp];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    @weakify(self)
    [manager GET:partialUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        @strongify(self)
        [_feedTableView.pullToRefreshView stopAnimating];
        [_feedTableView.infiniteScrollingView stopAnimating];
        NSArray *results = responseObject;
        if (results == nil ||  results.count == 0) {
            return;
        }
        if (requestType == RequestTypeNormal) {
            [self.posts removeAllObjects];
        }
        for(int i = 0; i < results.count; i++) {
            FLYTopic *post = [[FLYTopic alloc] initWithDictory:results[i]];
            [self.posts addObject:post];
        }
        //Set up before id for load more
        FLYTopic *lastTopic = [self.posts lastObject];
        self.beforeTimestamp = lastTopic.createdAt;
        
        [self.feedTableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [_feedTableView.pullToRefreshView stopAnimating];
        [_feedTableView.infiniteScrollingView stopAnimating];
        UALog(@"Post error %@", error);
    }];
    
}

- (void)_filterButtonTapped
{
    FLYFilterHomeFeedSelectorViewController *vc = [FLYFilterHomeFeedSelectorViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"feedPostCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL needUpdateConstraints = YES;
    if (cell == nil) {
        needUpdateConstraints = NO;
        cell = [[FLYFeedTopicTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    FLYFeedTopicTableViewCell *topicCell = (FLYFeedTopicTableViewCell *)cell;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)
    {
        topicCell.contentView.frame = cell.bounds;
        topicCell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    }
    topicCell.backgroundColor = [UIColor clearColor];
    //set cell state
    [topicCell updatePlayState:FLYPlayStateNotSet];
    if ([[FLYAudioStateManager sharedInstance].currentPlayItem.indexPath isEqual:indexPath]) {
        [topicCell updatePlayState:[FLYAudioStateManager sharedInstance].currentPlayItem.playState];
    }
    topicCell.topic = _posts[indexPath.row];
    topicCell.indexPath = indexPath;
    [topicCell setupTopic:_posts[indexPath.row] needUpdateConstraints:needUpdateConstraints];
    topicCell.selectionStyle = UITableViewCellSelectionStyleNone;
    topicCell.delegate = self;
    [topicCell setNeedsUpdateConstraints];
    [cell updateConstraints];
    return topicCell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [FLYFeedTopicTableViewCell heightForTopic:_posts[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideRecordIconNotification object:self];
    
    self.navigationController.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    [self.view layoutIfNeeded];
    FLYTopic *topic = self.posts[indexPath.row];
    FLYTopicDetailViewController *viewController = [[FLYTopicDetailViewController alloc] initWithTopic:topic];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)downloadComplete:(NSNotification *)notificaiton
{
    NSString *localPath = [notificaiton.userInfo objectForKey:kDownloadAudioLocalPathkey];
    FLYDownloadableAudioType type = [[notificaiton.userInfo objectForKey:kDownloadAudioTypeKey] integerValue];
    if(type != FLYDownloadableTopic) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStatePlaying;
        FLYFeedTopicTableViewCell *currentCell = (FLYFeedTopicTableViewCell *) [self.feedTableView cellForRowAtIndexPath:[FLYAudioStateManager sharedInstance].currentPlayItem.indexPath];
        [currentCell updatePlayState:FLYPlayStatePlaying];
        
        
        NSURL* url = [NSURL fileURLWithPath:localPath];
        
        STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
        
        [_audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0 indexPath:[FLYAudioStateManager sharedInstance].currentPlayItem.indexPath]];
        return;
        
        
        [[FLYAudioStateManager sharedInstance] playAudioURLStr:localPath withCompletionBlock:^{
            [self clearCurrentPlayingItem];
            //If auto play is enabled, play next audio file
            BOOL isAutoPlayEnabled = [FLYAppStateManager sharedInstance].isAutoPlayEnabled;
            if (isAutoPlayEnabled) {
                NSIndexPath *preIndexPath = [FLYAudioStateManager sharedInstance].previousPlayItem.indexPath;
                NSInteger toPlayRow = preIndexPath.row + 1;
                if (toPlayRow >= [self.posts count]) {
                    return;
                }
                FLYTopic *postToPlay = self.posts[toPlayRow];
                NSIndexPath *indexPathToPlay = [NSIndexPath indexPathForRow:toPlayRow inSection:preIndexPath.section];
                FLYFeedTopicTableViewCell *toPlayCell = (FLYFeedTopicTableViewCell *)[self.feedTableView cellForRowAtIndexPath:indexPathToPlay];
                [self playButtonTapped:toPlayCell withPost:postToPlay withIndexPath:indexPathToPlay];
            }
        }];
    });
}


#pragma mark - STKAudioPlayerDelegate

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    NSLog(@"state change");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    NSLog(@"error");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStatePlaying;
    FLYFeedTopicTableViewCell *currentCell = (FLYFeedTopicTableViewCell *) [self.feedTableView cellForRowAtIndexPath:[FLYAudioStateManager sharedInstance].currentPlayItem.indexPath];
    [currentCell updatePlayState:FLYPlayStatePlaying];
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"finish buffering");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(SampleQueueId *)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    if ([FLYAudioStateManager sharedInstance].currentPlayItem.indexPath == queueItemId.indexPath && [FLYAudioStateManager sharedInstance].currentPlayItem.playState != FLYPlayStatePaused) {
         [self clearCurrentPlayingItem];
    }
}


- (void)_newPostReceived:(NSNotification *)notif
{
    FLYTopic *topic = [notif.userInfo objectForKey:kNewPostKey];
    [self.posts insertObject:topic atIndex:0];
    [self.feedTableView reloadData];
    [self _scrollToTop];
}

- (void)_scrollToTop
{
    NSIndexPath* top = [NSIndexPath indexPathForRow:NSNotFound inSection:0];
    [self.feedTableView scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - FLYFeedTopicTableViewCellDelegate
- (void)commentButtonTapped:(FLYFeedTopicTableViewCell *)cell
{
     self.navigationController.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    [self.view layoutIfNeeded];
    [self.view bringSubviewToFront:_inlineReplyView];
    [self _moveInlineReplyViewOnScreen];
    [self.view needsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)playButtonTapped:(FLYFeedTopicTableViewCell *)tappedCell withPost:(FLYTopic *)post withIndexPath:(NSIndexPath *)indexPath
{
    if (post.audioDuration >= kStreamingMinimialLen) {
        NSURL* url = [NSURL URLWithString:post.mediaURL];
        STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
        [_audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0 indexPath:indexPath]];
    }
    
    //If currentPlayItem is empty, set the tappedCell as currentPlayItem
    NSIndexPath *tappedCellIndexPath;
    if (!indexPath) {
        tappedCellIndexPath = [self.feedTableView indexPathForCell:tappedCell];
    } else {
        tappedCellIndexPath = indexPath;
    }
    if (![FLYAudioStateManager sharedInstance].currentPlayItem) {
        [FLYAudioStateManager sharedInstance].currentPlayItem = [[FLYPlayableItem alloc] initWithItem:tappedCell playableItemType:FLYPlayableFeed playState:FLYPlayStateNotSet indexPath:tappedCellIndexPath];
    }
    
    //tap on the same cell
    if ([FLYAudioStateManager sharedInstance].currentPlayItem.indexPath == tappedCellIndexPath) {
        if ([FLYAudioStateManager sharedInstance].currentPlayItem.playState == FLYPlayStateNotSet) {
            [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStateLoading;
            [tappedCell updatePlayState:FLYPlayStateLoading];
            if (post.audioDuration < kStreamingMinimialLen) {
                [[FLYDownloadManager sharedInstance] loadAudioByURLString:post.mediaURL audioType:FLYDownloadableTopic];
            }
        } else if ([FLYAudioStateManager sharedInstance].currentPlayItem.playState == FLYPlayStateLoading) {
            return;
        } else if ([FLYAudioStateManager sharedInstance].currentPlayItem.playState == FLYPlayStatePlaying) {
            [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStatePaused;
            [tappedCell updatePlayState:FLYPlayStatePaused];
            [_audioPlayer pause];
        } else if ([FLYAudioStateManager sharedInstance].currentPlayItem.playState == FLYPlayStatePaused) {
            [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStatePlaying;
            [_audioPlayer resume];
            [tappedCell updatePlayState:FLYPlayStatePlaying];
        }  else {
            [FLYAudioStateManager sharedInstance].currentPlayItem.playState = FLYPlayStateFinished;
            [[FLYAudioStateManager sharedInstance] removePlayer];
            [tappedCell updatePlayState:FLYPlayStateFinished];
        }
        
        [FLYAudioStateManager sharedInstance].currentPlayItem.item = tappedCell;
    } else {
        //tap on a different cell
        //[[FLYAudioStateManager sharedInstance] removePlayer];
        if (post.audioDuration < kStreamingMinimialLen) {
            [[FLYDownloadManager sharedInstance] loadAudioByURLString:post.mediaURL audioType:FLYDownloadableTopic];
        }
        
        //change previous state, remove animation, change current to previous
        [FLYAudioStateManager sharedInstance].previousPlayItem = [FLYAudioStateManager sharedInstance].currentPlayItem;
        [FLYAudioStateManager sharedInstance].previousPlayItem.playState = FLYPlayStateNotSet;
        FLYFeedTopicTableViewCell *previousCell = (FLYFeedTopicTableViewCell *)[FLYAudioStateManager sharedInstance].previousPlayItem.item;
        [previousCell updatePlayState:FLYPlayStateNotSet];
    
        [FLYAudioStateManager sharedInstance].currentPlayItem =  [[FLYPlayableItem alloc] initWithItem:tappedCell playableItemType:FLYPlayableFeed playState:FLYPlayStateLoading indexPath:tappedCellIndexPath];
        [tappedCell updatePlayState:FLYPlayStateLoading];
    }
}

- (void)clearCurrentPlayingItem
{
    if (![FLYAudioStateManager sharedInstance].currentPlayItem) {
        [FLYAudioStateManager sharedInstance].previousPlayItem = nil;
        return;
    }
    FLYFeedTopicTableViewCell *currentPlayingCell = (FLYFeedTopicTableViewCell *)[FLYAudioStateManager sharedInstance].currentPlayItem.item;
    [currentPlayingCell updatePlayState:FLYPlayStateNotSet];
    
    [FLYAudioStateManager sharedInstance].previousPlayItem = [FLYAudioStateManager sharedInstance].currentPlayItem;
    [FLYAudioStateManager sharedInstance].currentPlayItem = nil;
}

#pragma mark - download audios
- (void)_autoDownloadAudios
{
    
}

#pragma mark - reply view move in and off screen
- (void)_moveInlineReplyViewOnScreen
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    [_inlineReplyView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.leading.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
    }];
    [UIView animateWithDuration:0.3f animations:^{
        _backgroundView.backgroundColor = [UIColor grayColor];
        _backgroundView.alpha = 0.4;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {

    }];
}

- (void)_moveInlineReplyViewOffScreen
{
    self.navigationController.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - kTabBarViewHeight);
    
    _backgroundView.backgroundColor = [UIColor clearColor];
    _backgroundView.alpha = 0;
    [self.view bringSubviewToFront:_backgroundView];
    [_inlineReplyView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(CGRectGetHeight(self.view.bounds));
        make.leading.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
    }];
    [UIView animateWithDuration:0.3f animations:^{
        [self.view layoutIfNeeded];
    }];
    [self.view needsUpdateConstraints];
    [self.view layoutIfNeeded];
}

#pragma mark - navigation bar item tapped 
- (void)_autoPlayButtonTapped
{
    [Dialog simpleToast:LOC(@"FLYAutoPlayEnabledHudText")];
}

- (void)_profileButtonTapped
{
    
}

#pragma mark - Navigation bar and status bar
- (UIColor *)preferredNavigationBarColor
{
    return [UIColor whiteColor];
}

- (UIColor*)preferredStatusBarColor
{
    return [UIColor whiteColor];
}

@end
