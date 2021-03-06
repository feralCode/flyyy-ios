//
//  FLYLoginViewController.m
//  Flyy
//
//  Created by Xingxing Xu on 2/28/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYLoginViewController.h"
#import "FLYIconButton.h"
#import "UIColor+FLYAddition.h"
#import "UIFont+FLYAddition.h"
#import "ECPhoneNumberFormatter.h"
#import "FLYCountrySelectorViewController.h"
#import "FLYNavigationController.h"
#import "FLYNavigationBar.h"
#import "FLYLoginService.h"
#import "FLYUser.h"
#import "NSDictionary+FLYAddition.h"
#import "UICKeyChainStore.h"
#import "RNLoadingButton.h"
#import "PXAlertView.h"
#import "FLYPasswordResetPhoneNumberViewController.h"
#import "FLYMainViewController.h"
#import "FLYLoginManager.h"
#import "SDVersion.h"
#import "UIButton+TouchAreaInsets.h"
#import "UIView+FLYAddition.h"
#import "FLYBarButtonItem.h"

#define kTitleTopPadding 20
#define kLeftIconWidth 50
#define kTextFieldLeftPadding 40
#define kTextFieldRightPadding 20
#define kExitButtonOriginX 20
#define kExitButtonOriginY 32

@interface FLYLoginViewController () <UITextFieldDelegate, UIScrollViewDelegate>

@property (nonatomic) UIScrollView *dummyScrollView;

@property (nonatomic) UIButton *exitButton;
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) RNLoadingButton *loginButton;

//password field
@property (nonatomic) UIView *passwordView;
@property (nonatomic) UIImageView *passwordIcon;
@property (nonatomic) UITextField *passwordTextField;
@property (nonatomic) UIImageView *passwordUnderlineView;

@property (nonatomic) UIButton *forgetPasswordButton;

// phone number
@property (nonatomic) UIView *phoneNumberView;
@property (nonatomic) UIImageView *phoneNumberUnderlineView;
@property (nonatomic) FLYIconButton *countryCodeChooser;
@property (nonatomic) UITextField *phoneNumberTextField;

// logo view
@property (nonatomic) UIImageView *logoView;

@property (nonatomic, copy) NSString *formattedPhoneNumber;
@property (nonatomic, copy) NSString *unformattedPhoneNumber;
@property (nonatomic, copy) NSString *countryAreaCode;

//service
@property (nonatomic) FLYLoginService *loginService;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL shouldBeginEditing;

@end

@implementation FLYLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // hide the 1px bottom line in navigation bar
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    self.backgroundImageView = [UIImageView new];
    self.backgroundImageView.image = [UIImage imageNamed:@"login_background"];
    [self.view addSubview:self.backgroundImageView];
    
    if (self.canGoBack) {
        self.exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.exitButton setImage:[UIImage imageNamed:@"icon_sign_in_exit_white"] forState:UIControlStateNormal];
        [self.exitButton addTarget:self action:@selector(_exitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.exitButton];
        self.exitButton.touchAreaInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    }
    
    self.loginButton = [RNLoadingButton new];
    self.loginButton.layer.cornerRadius = 5.0f;
    //    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginButton.hideTextWhenLoading = NO;
    self.loginButton.loading = NO;
    self.loginButton.backgroundColor = [FLYUtilities colorWithHexString:@"#DBCC25"];
    [self.loginButton setActivityIndicatorAlignment:RNLoadingButtonAlignmentLeft];
    [self.loginButton setActivityIndicatorStyle:UIActivityIndicatorViewStyleGray forState:UIControlStateDisabled];
    self.loginButton.activityIndicatorEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    [self.view addSubview:self.loginButton];
    
    [self.loginButton setEnabled:NO];
    [self.loginButton setTitle:LOC(@"FLYLoginButtonText") forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont flyFontWithSize:20.0f];
    [self.loginButton addTarget:self action:@selector(_loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    
    // password view
    self.passwordView = [UIView new];
    self.passwordView.backgroundColor = [UIColor clearColor];
    self.passwordView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.passwordView];
    
    self.passwordUnderlineView = [UIImageView new];
    self.passwordUnderlineView.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordUnderlineView.image = [UIImage imageNamed:@"login_underline"];
    [self.passwordView addSubview:self.passwordUnderlineView];
    [self.passwordUnderlineView sizeToFit];
    
    self.passwordIcon = [UIImageView new];
    self.passwordIcon.image = [UIImage imageNamed:@"login_lock"];
    [self.passwordView addSubview:self.passwordIcon];
    
    self.passwordTextField = [UITextField new];
    self.passwordTextField.textColor = [UIColor whiteColor];
    self.passwordTextField.backgroundColor = [UIColor clearColor];
    self.passwordTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passwordTextField.alpha = 0.54f;
    UIColor *color = [UIColor whiteColor];
    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LOC(@"FLYLoginDefaultPasswordTextFieldText") attributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName:[UIFont flyFontWithSize:17.0f]}];
    self.passwordTextField.secureTextEntry = YES;
    self.phoneNumberTextField.font = [UIFont flyFontWithSize:17.0f];
    self.passwordTextField.delegate = self;
    [self.passwordTextField addTarget:self action:@selector(_passwordTextFieldDidChange)
                     forControlEvents:UIControlEventEditingChanged];
    [self.passwordView addSubview:self.passwordTextField];

    self.phoneNumberView = [UIView new];
    self.phoneNumberView.backgroundColor = [UIColor clearColor];
    self.phoneNumberView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.phoneNumberView];
    
    self.phoneNumberUnderlineView = [UIImageView new];
    self.phoneNumberUnderlineView.translatesAutoresizingMaskIntoConstraints = NO;
    self.phoneNumberUnderlineView.image = [UIImage imageNamed:@"login_underline"];
    [self.phoneNumberView addSubview:self.phoneNumberUnderlineView];
    [self.phoneNumberUnderlineView sizeToFit];
    
    self.countryCodeChooser = [[FLYIconButton alloc] initWithText:[FLYUtilities getCountryDialCode] textFont:[UIFont flyFontWithSize:18] textColor:[UIColor whiteColor] icon:@"icon_login_country_code" isIconLeft:NO];
    [self.countryCodeChooser addTarget:self action:@selector(_countrySelectorSelected) forControlEvents:UIControlEventTouchUpInside];
    self.countryCodeChooser.translatesAutoresizingMaskIntoConstraints = NO;
    [self.phoneNumberView addSubview:self.countryCodeChooser];
    self.countryAreaCode = [FLYUtilities getCountryDialCode];
    
    self.phoneNumberTextField = [UITextField new];
    self.phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.phoneNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneNumberTextField.alpha = 0.54f;
    self.phoneNumberTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LOC(@"FLYLoginDefaultPhoneNumberTextFieldText") attributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName:[UIFont flyFontWithSize:17.0f]}];
    [self.phoneNumberTextField addTarget:self action:@selector(_phoneNumberTextFieldDidChange)
                        forControlEvents:UIControlEventEditingChanged];
    self.phoneNumberTextField.textColor = [UIColor whiteColor];
    self.phoneNumberTextField.font = [UIFont flyFontWithSize:17.0f];
    self.phoneNumberTextField.delegate = self;
    [self.phoneNumberView addSubview:self.phoneNumberTextField];
    
    self.logoView = [UIImageView new];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoView.image = [UIImage imageNamed:@"login_logo"];
    [self.logoView sizeToFit];
    [self.view addSubview:self.logoView];
    
    self.forgetPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.forgetPasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.forgetPasswordButton setImage:[UIImage imageNamed:@"login_question_mark"] forState:UIControlStateNormal];
    [self.forgetPasswordButton addTarget:self action:@selector(_forgetPasswordButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.forgetPasswordButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.view addSubview:self.forgetPasswordButton];
    [self.forgetPasswordButton sizeToFit];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(0.0f,1.0f);
    [scrollView setContentOffset:CGPointMake(0.0f,1.0f) animated:NO];
    // optional
    scrollView.scrollsToTop = YES; // default is YES.
    [self.view addSubview:scrollView];
    
    [self _addObservers];
    [self updateViewConstraints];
    
    self.loginService = [FLYLoginService loginService];
}

- (void)_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:@"UIKeyboardWillShowNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:@"UIKeyboardWillHideNotification"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)updateViewConstraints
{
    
    [self.backgroundImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.canGoBack) {
        [self.exitButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.view).offset(kExitButtonOriginX);
            make.top.equalTo(self.view).offset(kExitButtonOriginY);
        }];
    }
    
    if (self.keyboardHeight) {
        if ([self.phoneNumberTextField.text length] == 0 || [self.passwordTextField.text length] == 0) {
            [self.loginButton setEnabled:NO];
            self.loginButton.backgroundColor = [UIColor flyColorFlySignupGrey];
        }
        
        [self.loginButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-20 - self.keyboardHeight);
            make.width.equalTo(@(CGRectGetWidth([UIScreen mainScreen].bounds) - 80));
            make.height.equalTo(@(45));
        }];
    } else {
        [self.loginButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-20 - self.keyboardHeight);
            make.width.equalTo(@(CGRectGetWidth([UIScreen mainScreen].bounds) - 80));
            make.height.equalTo(@(45));
        }];
    }
    
    //password field
    [self.passwordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.loginButton.mas_top).offset(-55);
        make.leading.equalTo(self.view).offset(kTextFieldLeftPadding);
        make.height.equalTo(@(44));
        make.trailing.equalTo(self.view).offset(-kTextFieldRightPadding);
    }];
    
    [self.passwordUnderlineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.passwordView).offset(10);
        make.trailing.equalTo(self.passwordView).offset(-10);
        make.bottom.equalTo(self.passwordView);
    }];
    
    [self.passwordIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneNumberView).offset(15);
        make.centerY.equalTo(self.passwordView);
    }];
    
    [self.passwordTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.countryCodeChooser.mas_trailing).offset(6);
        make.trailing.equalTo(self.passwordView);
        make.top.equalTo(self.passwordView);
        make.bottom.equalTo(self.passwordView);
    }];
    
    [self.forgetPasswordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.passwordView);
        make.trailing.equalTo(self.passwordUnderlineView);
    }];
    
    
    //phone field
    [self.phoneNumberView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.passwordView.mas_top).offset(-30);
        make.leading.equalTo(self.view).offset(kTextFieldLeftPadding);
        make.height.equalTo(@(44));
        make.trailing.equalTo(self.view).offset(-kTextFieldRightPadding);
    }];
    
    [self.phoneNumberUnderlineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneNumberView).offset(10);
        make.trailing.equalTo(self.phoneNumberView).offset(-10);
        make.bottom.equalTo(self.phoneNumberView);
    }];
    
    [self.countryCodeChooser sizeToFit];
    [self.countryCodeChooser mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.phoneNumberView).offset(5);
        make.width.equalTo(@(kLeftIconWidth));
        make.centerY.equalTo(self.phoneNumberView);
    }];
    
    [self.phoneNumberTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.countryCodeChooser.mas_trailing).offset(6);
        make.trailing.equalTo(self.phoneNumberView);
        make.top.equalTo(self.phoneNumberView);
        make.bottom.equalTo(self.phoneNumberView);
    }];
    
    //logo view
    
    CGFloat logoOffeset = -100;
    CGFloat logoWidth = CGRectGetWidth(self.logoView.bounds);
    CGFloat logoHeight = CGRectGetHeight(self.logoView.bounds);
    
    if ([SDVersion deviceSize] == Screen3Dot5inch) {
        logoOffeset = -30;
        logoWidth = logoWidth / 1.4;
        logoHeight = logoHeight / 1.4;
    }
    
    [self.logoView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.phoneNumberView.mas_top).offset(logoOffeset);
        make.width.equalTo(@(logoWidth));
        make.height.equalTo(@(logoHeight));
    }];
    
    [super updateViewConstraints];
}

- (void)_phoneNumberTextFieldDidChange
{
    if ([self.phoneNumberTextField.text length] > 0) {
        self.phoneNumberTextField.alpha = 1.0f;
    } else {
        self.phoneNumberTextField.alpha = 0.54f;
    }
    
    if ([self.phoneNumberTextField.text length] > 0 && [self.passwordTextField.text length] > 0) {
        self.loginButton.backgroundColor = [UIColor flyButtonYellow];
        [self.loginButton setEnabled:YES];
    } else {
        self.loginButton.backgroundColor = [UIColor flyColorFlySignupGrey];
        [self.loginButton setEnabled:NO];
    }
    ECPhoneNumberFormatter *formatter = [[ECPhoneNumberFormatter alloc] init];
    NSString *formattedNumber = [formatter stringForObjectValue:self.phoneNumberTextField.text];
    self.phoneNumberTextField.text = formattedNumber;
    
    self.formattedPhoneNumber = [NSString stringWithFormat:@"%@%@", self.countryAreaCode, formattedNumber];
}

- (void)_passwordTextFieldDidChange
{
    if ([self.passwordTextField.text length] > 0) {
        self.passwordTextField.alpha = 1.0f;
    } else {
        self.passwordTextField.alpha = 0.54f;
    }
    
    if ([self.phoneNumberTextField.text length] > 0 && [self.passwordTextField.text length] > 0) {
        self.loginButton.backgroundColor = [UIColor flyButtonYellow];
        [self.loginButton setEnabled:YES];
    } else {
        self.loginButton.backgroundColor = [UIColor flyColorFlySignupGrey];
        [self.loginButton setEnabled:NO];
    }
}

- (void)_forgetPasswordButtonTapped
{
    [[FLYScribe sharedInstance] logEvent:@"login_page" section:@"forget_password" component:nil element:nil action:@"click"];
    
    FLYPasswordResetPhoneNumberViewController *vc = [FLYPasswordResetPhoneNumberViewController new];
    [self.navigationController pushViewController:vc animated:NO];
    
}

- (void)_countrySelectorSelected
{
    FLYCountrySelectorViewController *vc = [FLYCountrySelectorViewController new];
    @weakify(self)
    vc.countrySelectedBlock = ^(NSString *countryDialCode) {
        @strongify(self)
        self.countryAreaCode = countryDialCode;
        [self.countryCodeChooser setLabelText:countryDialCode];
        
        ECPhoneNumberFormatter *formatter = [[ECPhoneNumberFormatter alloc] init];
        NSString *formattedNumber = [formatter stringForObjectValue:self.phoneNumberTextField.text];
        self.formattedPhoneNumber = [NSString stringWithFormat:@"%@%@", self.countryAreaCode, formattedNumber];
    };
    FLYNavigationController *nav = [[FLYNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_loginButtonTapped
{
    [[FLYScribe sharedInstance] logEvent:@"login_page" section:@"login" component:nil element:nil action:@"click"];
    
    [self.loginButton setTitle:@"logging In" forState:UIControlStateDisabled];
    self.loginButton.enabled = NO;
    self.loginButton.loading = YES;
    
    //get phone number
    
    ECPhoneNumberFormatter *formatter = [[ECPhoneNumberFormatter alloc] init];
    NSString *unformattedPhoneNumber;
    NSString *error;
    [formatter getObjectValue:&unformattedPhoneNumber forString:self.formattedPhoneNumber errorDescription:&error];
    
    //get password
    NSString *password = self.passwordTextField.text;
    
    FLYLoginUserSuccessBlock successBlock= ^(AFHTTPRequestOperation *operation, id responseObj) {
        self.loginButton.enabled = YES;
        self.loginButton.loading = NO;
        [self.loginButton setTitle:@"Login" forState:UIControlStateDisabled];
        
        NSString *authToken = [responseObj fly_stringForKey:@"auth_token"];
        if (!authToken) {
            UALog(@"Auth token is empty");
            return;
        }
        //store token
        [FLYAppStateManager sharedInstance].authToken = authToken;
        [UICKeyChainStore setString:[FLYAppStateManager sharedInstance].authToken forKey:kAuthTokenKey];
        
        if (!responseObj) {
            UALog(@"User is empty");
            return;
        }
        
        // common init
        [[FLYLoginManager sharedInstance] initAfterLogin:responseObj];
        
        [FLYAppStateManager sharedInstance].needRestartNavigationStackAfterLogin = NO;
        FLYMainViewController *mainVC = [FLYMainViewController new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainVC];
        [self presentViewController:nav animated:YES completion:nil];
    };
    
    FLYLoginUserErrorBlock errorBlock= ^(id responseObj, NSError *error) {
        self.loginButton.enabled = YES;
        self.loginButton.loading = NO;
        [self.loginButton setTitle:@"Login" forState:UIControlStateDisabled];
        
        if (responseObj && [responseObj isKindOfClass:[NSDictionary class]]) {
            NSInteger code = [responseObj fly_integerForKey:@"code"];
            if (code == kInvalidPassword) {
                [PXAlertView showAlertWithTitle:LOC(@"FLYLoginWrongPassword")];
            } else if (code == kLoginPhoneNotFound) {
                [PXAlertView showAlertWithTitle:LOC(@"FLYLoginPhoneNumberNotFound")];
            } else if (code == kInvalidToken) {
                [PXAlertView showAlertWithTitle:LOC(@"FLYLoginInvalidToken")];
            }
        } else {
            UALog(@"Login failed");
        }
    };
    
    [self.loginService loginWithPhoneNumber:unformattedPhoneNumber password:password success:successBlock error:errorBlock];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    // DETECTED! - do what you need to
    NSLog(@"scrollViewShouldScrollToTop");
    return NO;
}

#pragma mark - private methods
- (void)_exitButtonTapped
{
    if (!self.presentingViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.shouldBeginEditing = YES;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.shouldBeginEditing = NO;
    return YES;
}

- (void)keyboardWillShow:(NSNotification *)note {
    if (self.shouldBeginEditing) {
        NSDictionary *userInfo = [note userInfo];
        CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        if (!self.keyboardHeight) {
            self.keyboardHeight = kbSize.height;
        }
        self.logoView.hidden = YES;
        [self updateViewConstraints];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    if (self.shouldBeginEditing) {
        self.logoView.hidden = NO;
        [self updateViewConstraints];
    }
}

#pragma mark - Navigation bar
- (void)loadLeftBarButton
{
    @weakify(self)
    FLYBackBarButtonItem *barItem = [FLYBackBarButtonItem barButtonItem:YES];
    barItem.actionBlock = ^(FLYBarButtonItem *barButtonItem) {
        @strongify(self)
        [self _backButtonTapped];
    };
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)_backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Navigation bar and status bar
- (UIColor *)preferredNavigationBarColor
{
    return [UIColor clearColor];
}

//- (UIColor*)preferredStatusBarColor
//{
//    return [FLYUtilities colorWithHexString:@"#00BEFF"];
//}

@end
