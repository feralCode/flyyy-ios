//
//  FLYMentionPayload.m
//  Flyy
//
//  Created by Xingxing Xu on 5/30/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYMentionPayload.h"
#import "NSDictionary+FLYAddition.h"

@implementation FLYMentionPayload

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if (self = [super initWithDictionary:dict]) {
        _topicId = [dict fly_stringForKey:@"tid"];
    }
    return self;
}

@end
