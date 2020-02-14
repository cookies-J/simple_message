//
//  TYSMChatModel.h
//  simple_message
//
//  Created by jele lam on 13/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYSMChatModel : NSObject
///名字
@property (nonatomic, copy) NSString *name;

/**
 后期类型可以用 NSData 声明，接收字符串以外图片、语音信息等
 */
@property (nonatomic, copy) NSString *content;
@end

NS_ASSUME_NONNULL_END
