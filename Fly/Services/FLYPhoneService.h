//
//  FLYPhoneService.h
//  Flyy
//
//  Created by Xingxing Xu on 3/2/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYServiceBase.h"

typedef void(^FLYSendCodeSuccessBlock)(AFHTTPRequestOperation *operation, id responseObj);
typedef void(^FLYSendCodeErrorBlock)(id responseObj, NSError *error);

typedef void(^FLYVerifyCodeSuccessBlock)(AFHTTPRequestOperation *operation, id responseObj);
typedef void(^FLYVerifyCodeErrorBlock)(id responseObj, NSError *error);

@interface FLYPhoneService : FLYServiceBase

+ (instancetype)phoneServiceWithPhoneNumber:(NSString *)phoneNumber;

- (void)serviceSendCodeWithPhone:(NSString *)number isPasswordReset:(BOOL)isPasswordReset success:(FLYSendCodeSuccessBlock)successBlock error:(FLYSendCodeErrorBlock)errorBlock;

- (void)serviceVerifyCode:(NSString *)code phonehash:(NSString *)phoneHash phoneNumber:(NSString *)phoneNumber success:(FLYVerifyCodeSuccessBlock)successBlock error:(FLYVerifyCodeErrorBlock)errorBlock;

@end
