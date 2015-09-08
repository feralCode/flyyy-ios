//
//  FLYGroup.m
//  Fly
//
//  Created by Xingxing Xu on 1/29/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYGroup.h"
#import "NSDictionary+FLYAddition.h"

@implementation FLYGroup

- (instancetype)initWithDictory:(NSDictionary *)dict
{
    if (self = [super init]) {
        if (dict == nil) {
            return self;
        }
        _groupId = [[dict fly_objectOrNilForKey:@"tag_id"] stringValue];
        _groupName = [dict fly_stringForKey:@"tag_name"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_groupId forKey:@"group_id"];
    [coder encodeObject:_groupName forKey:@"group_name"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _groupId = [aDecoder decodeObjectForKey:@"group_id"];
        _groupName = [aDecoder decodeObjectForKey:@"group_name"];
    }
    return self;
}

@end
