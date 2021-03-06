//
//  FLYPost.m
//  Fly
//
//  Created by Xingxing Xu on 11/27/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

#import "FLYTopic.h"
#import "FLYUser.h"
#import "FLYGroup.h"
#import "NSDictionary+FLYAddition.h"
#import "FLYDownloadableAudio.h"
#import "FLYURLConstants.h"
#import "NSDate+TimeAgo.h"
#import "FLYTopicService.h"
#import "FLYServerConfig.h"
#import "iRate.h"

@interface FLYTopic() <FLYDownloadableAudio>

@end


@implementation FLYTopic

- (instancetype)initWithDictory:(NSDictionary *)dict
{
    if (self = [super init]) {
        _topicId = [[dict fly_objectOrNilForKey:@"topic_id"] stringValue];
        _topicTitle = [dict fly_stringForKey:@"topic_title"];
        NSString *mediaPath = [dict fly_stringForKey:@"media_path"];
        _mediaURL = [NSString stringWithFormat:@"%@/%@", [FLYServerConfig getAssetURL], mediaPath];
        _likeCount = [dict fly_integerForKey:@"like_count"];
        _replyCount = [dict fly_integerForKey:@"reply_count"];
        _audioDuration = [dict fly_integerForKey:@"audio_duration"];
        _createdAt = [[dict fly_objectOrNilForKey:@"created_at"] stringValue];
        _updatedAt = [[dict fly_objectOrNilForKey:@"updated_at"] stringValue];
        _user = [[FLYUser alloc] initWithDictionary:[dict fly_dictionaryForKey:@"user"]];
        
        _tags = [NSMutableArray new];
        NSArray *tagsData = [dict fly_arrayForKey:@"tags"];
        for (NSDictionary *tagDict in tagsData) {
            FLYGroup *tag = [[FLYGroup alloc] initWithDictory:tagDict];
            [_tags addObject:tag];
        }
        _liked = [dict fly_boolForKey:@"liked" defaultValue:0];
        
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:[_createdAt longLongValue]/1000];
        NSString *ago = [date timeAgoSimple];
        _displayableCreateAt = ago;
    }
    return self;
}

- (NSString *)audioURLStr
{
    return self.mediaURL;
}

- (FLYDownloadableAudioType)downloadableAudioType
{
    return FLYDownloadableTopic;
}

- (void)like
{
    [self _serverLike:self.liked];
    if (self.liked) {
        [self _clientLike:self.liked];
    } else {
        [self _clientLike:self.liked];
    }
}

- (void)_clientLike:(BOOL)liked
{
    if (self.liked) {
        if (liked >= 1) {
            self.likeCount -= 1;
        }
    } else {
        self.likeCount += 1;
    }
    self.liked = !liked;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationTopicLikeChanged object:self userInfo:@{@"topic":self}];
}

- (void)_serverLike:(BOOL)liked
{
    FLYLikeSuccessBlock successBlock = ^(AFHTTPRequestOperation *operation, id responseObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[iRate sharedInstance] logEvent:NO];
        });
    };
    
    FLYLikeErrorBlock errorBlock = ^(id responseObj, NSError *error) {
        // revert like
        [self _clientLike:self.liked];
    };
    
    [FLYTopicService likeTopicWithId:self.topicId liked:liked successBlock:successBlock errorBlock:errorBlock];
}

- (void)decrementReplyCount:(NSDictionary *)dict
{
    self.replyCount -= 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewReplyDeletedNotification object:self userInfo:dict];
    
}

- (void)incrementReplyCount:(NSDictionary *)dict
{
    self.replyCount += 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewReplyPostedNotification object:self userInfo:dict];
}

#pragma mark - isEqual + hash
- (BOOL)isEqual:(FLYTopic *)object
{
    if (![object isKindOfClass:[FLYTopic class]]) {
        return NO;
    }
    if ([self.topicId isEqualToString:object.topicId]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    return 37 + self.topicId.hash;
}


@end
