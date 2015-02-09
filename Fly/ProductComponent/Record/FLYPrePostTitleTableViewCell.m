//
//  FLYPrePostTitleTableViewCell.m
//  Fly
//
//  Created by Xingxing Xu on 12/11/14.
//  Copyright (c) 2014 Fly. All rights reserved.
//

#import "FLYPrePostTitleTableViewCell.h"

#define kTopPadding 10
#define kLeftPadding 15
#define kRightPadding 15

@interface FLYPrePostTitleTableViewCell()<UITextViewDelegate>

@property (nonatomic) UILabel *captionLabel;
@property (nonatomic) UITextView *descriptionTextView;
@property (nonatomic) UILabel *charLimitLabel;

@end

@implementation FLYPrePostTitleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _captionLabel = [UILabel new];
        [_captionLabel setFont:[UIFont fontWithName:@"Avenir-Book" size:16]];
        _captionLabel.text = @"Caption:";
        _captionLabel.textColor = [UIColor whiteColor];
        _captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_captionLabel];
        
        _descriptionTextView = [[UITextView alloc] init];
        _descriptionTextView.translatesAutoresizingMaskIntoConstraints = NO;
        [_descriptionTextView setDelegate:self];
        [_descriptionTextView setReturnKeyType:UIReturnKeyDone];
        [_descriptionTextView setText:LOC(@"FLYPrePostDefaultText")];
        [_descriptionTextView setFont:[UIFont fontWithName:@"Avenir-Book" size:16]];
        [_descriptionTextView setTextColor:[UIColor lightGrayColor]];
        [self addSubview:_descriptionTextView];
        
        [self updateConstraintsIfNeeded];
    }
    
    return self;
}

- (void)updateConstraints
{
    [self.captionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(kTopPadding);
        make.leading.equalTo(self).offset(kLeftPadding);
    }];
    
    [self.descriptionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.captionLabel.mas_bottom).offset(kTopPadding);
        make.leading.equalTo(self).offset(kLeftPadding);
        make.right.equalTo(self.mas_right).offset(kRightPadding);
        make.height.equalTo(@60);
    }];
    [super updateConstraints];
}

#pragma mark - UITextViewDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView.textColor == [UIColor lightGrayColor]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [_delegate titleTextViewShouldBeginEditing:textView];
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if(textView.text.length == 0){
        textView.textColor = [UIColor lightGrayColor];
        textView.text = LOC(@"FLYPrePostDefaultText");
    }
    
    [_delegate titleTextViewShouldEndEditing:textView];
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView
{
    if(textView.text.length == 0){
        textView.textColor = [UIColor lightGrayColor];
        textView.text = LOC(@"FLYPrePostDefaultText");
        [textView resignFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        if(textView.text.length == 0){
            textView.textColor = [UIColor lightGrayColor];
            textView.text = LOC(@"FLYPrePostDefaultText");
            [textView resignFirstResponder];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - UIResponder
- (void)becomeFirstResponder
{
    [_descriptionTextView becomeFirstResponder];
}

- (void)resignFirstResponder
{
    [_descriptionTextView resignFirstResponder];
}



@end
