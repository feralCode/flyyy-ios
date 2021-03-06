//
//  FLYTopicDetailTabbar.h
//  Flyy
//
//  Created by Xingxing Xu on 3/9/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYIconButton.h"

@protocol FLYTopicDetailTabbarDelegate <NSObject>

- (void)commentButtonOnTabbarTapped:(id)sender;
- (void)playAllButtonOnTabbarTapped:(id)sender;

@end


@interface FLYTopicDetailTabbar : UIView


@property (nonatomic) FLYIconButton *playAllButton;
@property (nonatomic) FLYIconButton *commentButton;

@property (nonatomic, weak) id<FLYTopicDetailTabbarDelegate>delegate;

@end
