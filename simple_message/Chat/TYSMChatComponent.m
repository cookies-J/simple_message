//
//  TYSMChatComponent.m
//  simple_message
//
//  Created by jele lam on 13/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "TYSMChatComponent.h"
#import "FCFileManager.h"
#import "FMDB.h"

static NSString *const kTableName = @"simple_message_table";
static NSString *const kPlistFileName = @"simple_message.plist";
static NSString *const kDBFileName = @"simple_message.db";

@interface TYSMChatComponent ()
// TODO: 怎么简单怎么来
/// 负责 copy 数据给不可写数组 chatHistorys ，供 UI 使用
@property (nonatomic, strong) NSMutableArray <TYSMChatModel *> *readChatHistorys;

/// 负责跟本地 plist 文件打交道，保存记录
@property (nonatomic, strong) NSMutableArray *plistChatHistory;
/// 负责跟本地 db 文件打交道，保存记录
@property (nonatomic, strong) FMDatabaseQueue *dbqChatHistory;
@end

@implementation TYSMChatComponent {
    NSString * _filePath;
    TYSMStorageType _storageType;
}

- (instancetype)initWithStorageType:(TYSMStorageType)type {
    if (self = [super init]) {
        _storageType = type;
        if (type == TYSMStorageTypePlist) {
            [self getAllChatContentsWithPlist];
        }
        
        if (type == TYSMStorageTypeFMDB) {
            [self configureFMDB];
            [self getAllChatContentsWithFMDB];
        }
    }
    return self;
}

- (void)insertLastContentWithModel:(TYSMChatModel *)model {
    
    // 将当前所有数据复制给 _chatHistorys 展示到 UI
    // 数据量不大，暂时不做锁处理
    [self.readChatHistorys addObject:model];
    _chatHistorys = [self.readChatHistorys copy];
    
    if (_storageType == TYSMStorageTypePlist) {
        // 将当前所有数据写入本地 plist 文件
        [self.plistChatHistory addObject:@{
            @"name"     : model.name,
            @"content"  : model.content,
        }];
        NSAssert([self.plistChatHistory writeToFile:_filePath atomically:YES], @"写入错误");
    }
    
    if (_storageType == TYSMStorageTypeFMDB) {
        // 写入到 db 文件
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.dbqChatHistory inDatabase:^(FMDatabase *db) {
                NSString *sql = [NSString stringWithFormat:@"insert into %@(name,content) values ('%@','%@')",
                                 kTableName,
                                 model.name,
                                 model.content];
                NSError *error = nil;
                [db executeUpdate:sql withErrorAndBindings:&error];
                NSAssert1(error == nil,@"%@",error);
            }];
        });
    }
}

#pragma mark - public

- (NSString *)configureFilePathWithName:(NSString *)fileName {
    NSString *filepath = [FCFileManager pathForDocumentsDirectoryWithPath:fileName];
    
    NSError *error = nil;
    
    if ([FCFileManager existsItemAtPath:filepath] == NO) {
        [FCFileManager createFileAtPath:filepath error:&error];
        if (error) {
            NSLog(@"%@",error);
            return nil;
        }
    }
    return filepath;
}

#pragma mark - plist
- (void)getAllChatContentsWithPlist {
    
    _filePath = [self configureFilePathWithName:kPlistFileName];
    
    NSArray *contentArray = [NSArray arrayWithContentsOfFile:_filePath];
    
    [contentArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TYSMChatModel *contentModel = [[TYSMChatModel alloc] init];
        contentModel.name = obj[@"name"];
        contentModel.content = obj[@"content"];
        
        [self.readChatHistorys addObject:contentModel];
        
        [self.plistChatHistory addObject:obj];
    }];
    
    _chatHistorys = [self.readChatHistorys copy];
}

#pragma mark - fmdb

- (void)configureFMDB {
    _filePath = [self configureFilePathWithName:kDBFileName];
    
    self.dbqChatHistory = [FMDatabaseQueue databaseQueueWithPath:_filePath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.dbqChatHistory inDatabase:^(FMDatabase *db) {
            if(![db tableExists:kTableName]) {
                NSString * sql = [NSString stringWithFormat:@"create table if not exists %@(name,content)",kTableName];
                NSAssert1([db executeUpdate:sql],@"创建表%@失败", kTableName);
            }
        }];
    });
}

- (void)getAllChatContentsWithFMDB {
    
    __weak typeof(self) weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.dbqChatHistory inDatabase:^(FMDatabase *db) {
            
            NSMutableArray <TYSMChatModel *> *array = [NSMutableArray array];
            
            NSString * sql = [NSString stringWithFormat:@"select * from %@ ",kTableName];
            FMResultSet* result = [db executeQuery:sql];
            while (result.next) {
                NSString * name = [result stringForColumnIndex:0];
                NSString * content = [result stringForColumnIndex:1];
                
                TYSMChatModel *model = [[TYSMChatModel alloc] init];
                model.name = name;
                model.content = content;
                
                [array addObject:model];
                
                
            }
            [result close];
            
            // 深拷
            weakself.readChatHistorys = [array mutableCopy];
            // 浅拷
            self->_chatHistorys = [weakself.readChatHistorys copy];
        }];
    });
}


#pragma mark - loadlazy;

- (NSMutableArray<TYSMChatModel *> *)readChatHistorys {
    if (_readChatHistorys == nil) {
        _readChatHistorys = [NSMutableArray array];
    }
    return _readChatHistorys;
}

- (NSMutableArray *)plistChatHistory {
    if (_plistChatHistory == nil) {
        _plistChatHistory = [NSMutableArray array];
    }
    return _plistChatHistory;
}
@end
