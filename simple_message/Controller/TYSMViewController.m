//
//  ViewController.m
//  simple_message
//
//  Created by jele lam on 12/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

/**
 实现一个点对点的IM聊天界面，具体要求如下：
 1.只需要实现一个聊天界面，不需要聊天列表。
 2.可以输入聊天内容（只需要支持文本聊天）。
 3.不需要接口，只需要发送消息时随机自动回复【我知道了、嗯、好的、谢谢】。
 4.杀掉应用再打开需要保留上次的聊天记录（数据持久化）。
 5.不限应用架构（MVC、MVVM等）。
 */

#import "TYSMViewController.h"
#import "TYSMTableViewCell.h"
#import "FCFileManager.h"
#import "TYSMChatComponent.h"
#import "IQKeyboardManager.h"

/// cell 复用标识， Left 表示屏幕左侧对方发出的信息 UI ，Right 表示右侧自己发出的消息 UI
static NSString * const kCellWithIdentifierLeft = @"kCellWithIdentifierLeft";
static NSString * const kCellWithIdentifierRight = @"kCellWithIdentifierRight";

@interface TYSMViewController () <UITableViewDelegate, UITableViewDataSource>
/// 输入框
@property (strong, nonatomic) IBOutlet IQTextView *inputTextView;
/// 聊天内容列表
@property (strong, nonatomic) IBOutlet UITableView *tableView;
/// 信息发送按钮
@property (strong, nonatomic) IBOutlet UIButton *sendButton;

/// 聊天内容组件，业务层逻辑
@property (nonatomic, strong) TYSMChatComponent *chatComponent;
@end

@implementation TYSMViewController

#pragma mark -  1.只需要实现一个聊天界面，不需要聊天列表。

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[IQKeyboardManager sharedManager] setEnable:YES];
    // 聊天内容业务层
    self.chatComponent = [[TYSMChatComponent alloc] initWithStorageType:TYSMStorageTypePlist];
    
    // 配置后台通知
    [self configureNotification];
    // 配置 列表、和其他 UI
    [self configureUI];

}

- (void)configureUI {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 100.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}



#pragma mark - notification
- (void)configureNotification {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyBoard:) name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
}

// TODO:  2.可以输入聊天内容（只需要支持文本聊天）。
- (void)willShowKeyboard:(NSNotification *)notification {

    CGRect keyBoardRect = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(CGRectGetHeight(keyBoardRect), 0, 0, 0);
    
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] animations:^{
        [self.tableView setContentInset:contentInsets];
    }];
}

- (void)willHideKeyBoard:(NSNotification *)notification {
        
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] animations:^{
        [self.tableView setContentInset:UIEdgeInsetsZero];
    }];
}

- (void)willResignActiveNotification:(NSNotification *)notification {
    if ([self.inputTextView isFirstResponder]) {
        [self.inputTextView resignFirstResponder];
    }
}

#pragma mark - Delegate && Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatComponent.chatHistorys.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TYSMTableViewCell *cell;

    BOOL isLeft = indexPath.row %2;
    if (isLeft) {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellWithIdentifierLeft];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellWithIdentifierRight];
    }
    
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TYSMTableViewCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:isLeft? 1 : 0 ];
    }
    
    [cell setContent:self.chatComponent.chatHistorys[indexPath.row].content];

    return cell;
    
}

#pragma mark - action

- (IBAction)sendMessage:(UIButton *)sender {
    
    /**
     TODO: 3. 不需要接口，只需要发送消息时随机自动回复【我知道了、嗯、好的、谢谢】。
     自动回复逻辑：根据信息 条目 求模 : 1 => 自己， 0 => 对方
     */
    TYSMChatModel *model = [[TYSMChatModel alloc] init];
    model.content = self.inputTextView.text;
    model.name = self.chatComponent.chatHistorys.count % 2 == 0? @"自己" : @"对方";
    
    [self.inputTextView setText:@""];
    
    /**
     TODO:  4.杀掉应用再打开需要保留上次的聊天记录（数据持久化）。
     */
    
    [self.chatComponent insertLastContentWithModel:model];
    
    // 插入 CELL
    [self.tableView beginUpdates];
    
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:self.chatComponent.chatHistorys.count-1 inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexpath]
                          withRowAnimation:indexpath.row %2!= 0 ? UITableViewRowAnimationLeft:UITableViewRowAnimationRight];
    
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    
    //  信息求模得 1 表示属于自己发的信息 做一次递归自动回复
    if (self.chatComponent.chatHistorys.count %2 != 0) {
        [self.inputTextView setText:@"我知道了、嗯、好的、谢谢"];
        [self sendMessage:sender];
    }
    
}

@end
