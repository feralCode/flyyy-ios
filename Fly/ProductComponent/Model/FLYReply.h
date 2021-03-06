//
//  FLYReply.h
//  Flyy
//
//  Created by Xingxing Xu on 2/15/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FLYUser;

@interface FLYReply : NSObject

@property (nonatomic, copy) NSString *replyId;
@property (nonatomic, copy) NSString *topicId;
@property (nonatomic, copy) NSString *parentReplyId;
@property (nonatomic) FLYUser *parentReplyUser;
@property (nonatomic) FLYUser *user;
@property (nonatomic, copy) NSString *mediaURL;
@property (nonatomic) NSInteger likeCount;
@property (nonatomic) NSInteger audioDuration;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *displayableCreateAt;
@property (nonatomic) BOOL liked;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)like;

@end
