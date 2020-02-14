//
//  TYSMChatComponent.h
//  simple_message
//
//  Created by jele lam on 13/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYSMChatModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_CLOSED_ENUM(NSInteger, TYSMStorageType) {
    TYSMStorageTypePlist,
    TYSMStorageTypeFMDB,
};

@interface TYSMChatComponent : NSObject

/**
 根据存储方式，初始化聊天记录组件
 @param type 参考 TYSMStorageType， 用 plist 或 FMDB 做存储
 */

- (instancetype)initWithStorageType:(TYSMStorageType)type;

/// 对话记录
@property (nonatomic, strong, readonly) NSArray <TYSMChatModel *>*chatHistorys;

/**
 插入最后一条对话内容
 @param model 模型
 */
- (void)insertLastContentWithModel:(TYSMChatModel *)model;

@end

NS_ASSUME_NONNULL_END
