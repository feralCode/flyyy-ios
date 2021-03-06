//
//  FLYSearchBar.h
//  Flyy
//
//  Created by Xingxing Xu on 8/20/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLYSearchBar;

typedef NS_ENUM(NSInteger, FLYSearchBarType) {
    FLYSearchBarTypeTag = 0,
    FLYSearchBarTypeUsername
};

@protocol FLYSearchBarDelegate <NSObject>

@optional
- (void)searchBarDidBeginEditing:(FLYSearchBar *)searchBar;
- (void)searchBarDidEndEditing:(FLYSearchBar *)searchBar;
- (void)searchBarCancelButtonClicked:(FLYSearchBar *)searchBar;
- (void)searchBar:(FLYSearchBar *)searchBar textDidChange:(NSString *)searchText;

@end

@interface FLYSearchBar : UIView

@property (nonatomic, weak) id<FLYSearchBarDelegate> delegate;

- (instancetype)initWithType:(FLYSearchBarType)type;
- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end
