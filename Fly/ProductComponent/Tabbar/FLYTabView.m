//
//  FLYTabView.m
//  Fly
//
//  Created by Xingxing Xu on 11/16/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

#import "FLYTabView.h"
#import "UIColor+FLYAddition.h"

#define kLabelPosH      1
#define kLabelPosV      28
#define kImagePostH     1
#define kImagePosV      2

@interface FLYTabView()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *label;

@end

@implementation FLYTabView

- (instancetype)initWithTitle:(NSString *)title image:(NSString *)imageName
{
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *image = [UIImage imageNamed:imageName];
        [_imageView setImage:image];
        [self addSubview:_imageView];
        
        _label = [UILabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.textColor = [UIColor flyGreen];
        _label.text = title;
        [self addSubview:_label];
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)updateConstraints
{
    
    //label constraints
    NSDictionary *metrics = @{@"imagePosH":@(kImagePostH), @"imagePosV":@(kImagePosV), @"labelPosH":@(kLabelPosH), @"labelPosV":@(kLabelPosV)};
    
    NSArray *imagePosH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-imagePosH-[_imageView]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_imageView)];
    NSArray *imagePosV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-imagePosV-[_imageView]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_imageView)];
    [self addConstraints:imagePosH];
    [self addConstraints:imagePosV];
    
    NSArray *labelPosH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-labelPosH-[_label]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_label)];
    NSArray *labelPosV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-labelPosV-[_label]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_label)];
    [self addConstraints:labelPosH];
    [self addConstraints:labelPosV];
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSLog(@"tabTabView %@", NSStringFromCGRect(self.frame));
}

@end
