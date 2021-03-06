//
//  FLYInlineReplyView.h
//  Fly
//
//  Created by Xingxing Xu on 12/6/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

@class FLYInlineReplyView;

typedef void(^FLYMoveOffscreenBlock)(FLYInlineReplyView *view);

@interface FLYInlineReplyView : UIView

@property (nonatomic) UIView *backgroundView;
@property (nonatomic, copy)FLYMoveOffscreenBlock backgroudTappedBlock;

@end
