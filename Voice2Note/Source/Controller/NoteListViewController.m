//
//  NoteListViewController.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "NoteEditViewController.h"
#import "NoteListCell.h"
#import "NoteListViewController.h"
#import "NoteManager.h"
#import "SVProgressHUD.h"
#import "SignViewController.h"
#import "UIColor+VNHex.h"
#import "VNConstants.h"
#import "VNNote.h"

@interface NoteListViewController () <UIAlertViewDelegate, UISearchResultsUpdating>

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UIBarButtonItem *cancelButton, *addButton, *editButton, *deleteButton;

@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.navigationItem.title = kAppName;
    self.view.backgroundColor = [UIColor whiteColor];

    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNote)];
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"删除所有" style:UIBarButtonItemStylePlain target:self action:@selector(delete)];
    [self.deleteButton setTintColor:[UIColor redColor]];

    [self updateButtonsToMatchTableState];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    // 在搜索状态下，设置背景框的颜色为灰色
    self.searchController.dimsBackgroundDuringPresentation = YES;
    // 点击搜索框的时候，是否隐藏导航栏
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    // 添加搜索范围分类
    self.searchController.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"ScopeButtonContent", @"内容"),
                                                           NSLocalizedString(@"ScopeButtonDate", @"日期") ];
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //是否可以多选
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:kNotificationCreateFile
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData {
    self.dataSource = [[NoteManager sharedManager] readAllNotes];
    [self.tableView reloadData];
    [self updateButtonsToMatchTableState];
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NoteManager sharedManager] readAllNotes];
    }
    return _dataSource;
}

#pragma mark -
#pragma mark === Toolbar Action ===
#pragma mark -

- (void)addNote {
    NoteEditViewController *note = [[NoteEditViewController alloc] init];
    [self.navigationController pushViewController:note animated:YES];
}

- (void)edit {
    [self.tableView setEditing:YES animated:YES];
    [self updateButtonsToMatchTableState];
}

- (void)cancel {
    [self.tableView setEditing:NO animated:YES];
    [self updateButtonsToMatchTableState];
}

- (void) delete {
    NSString *actionTitle;
    if (([[self.tableView indexPathsForSelectedRows] count] == 1)) {
        actionTitle = @"你确定要删除这一项吗?";
    } else {
        actionTitle = @"你确定要删除这些项目吗?";
    }
    NSString *cancelTitle = @"取消";
    NSString *okTitle = @"确定";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){

                     }]];

    [alert addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {

               NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
               BOOL deleteSpecificRows = selectedRows.count > 0;
               if (deleteSpecificRows) {
                   NSMutableIndexSet *indicesOfItemsToDelete = [NSMutableIndexSet new];
                   for (NSIndexPath *selectionIndex in selectedRows) {
                       [indicesOfItemsToDelete addIndex:selectionIndex.row];
                       VNNote *note = [self.dataSource objectAtIndex:selectionIndex.row];
                       [[NoteManager sharedManager] deleteNote:note];
                   }

                   [self.dataSource removeObjectsAtIndexes:indicesOfItemsToDelete];

                   [self.tableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];

               } else {
                   [self.dataSource removeAllObjects];
                   //根据模型 更新view
                   [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
               }
               //退出编辑模式
               [self.tableView setEditing:NO animated:YES];
               [self updateButtonsToMatchTableState];
           }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -
#pragma mark === DataSource & Delegate ===
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
    return [NoteListCell heightWithNote:note];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListCell"];
    if (!cell) {
        cell = [[NoteListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ListCell"];
    }
    // 搜素状态
    if (self.searchController.active) {

    } else {
        VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
        note.index = indexPath.row;
        [cell updateWithNote:note];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.editing) {
        [self updateDeleteButtonTitle];
    } else {
        _selectedIndex = indexPath.row;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *pwd = [defaults objectForKey:[NSString stringWithFormat:@"%ld", (long)self.selectedIndex]];
        if (pwd) {
            // 锁定文本，弹出输入密码
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"请输入解锁密码"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
            [alter setAlertViewStyle:UIAlertViewStyleSecureTextInput];
            // 以解决 Multiple UIAlertView 的代理事件
            [alter show];

        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            VNNote *note = [self.dataSource objectAtIndex:indexPath.row];

            NoteEditViewController *yy = [[NoteEditViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:yy animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateDeleteButtonTitle];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // TODO: 搜索逻辑
}

#pragma mark -
#pragma mark === EditMode ===
#pragma mark -

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

#pragma mark -
#pragma mark === Updating button state ===
#pragma mark -

- (void)updateButtonsToMatchTableState {
    // 处于编辑状态
    if (self.tableView.editing) {
        //显示取消按钮
        self.navigationItem.rightBarButtonItem = self.cancelButton;
        [self updateDeleteButtonTitle];
        //显示删除按钮
        self.navigationItem.leftBarButtonItem = self.deleteButton;
    } else {
        //显示添加按钮
        self.navigationItem.leftBarButtonItem = self.addButton;
        if (self.dataSource.count > 0) {
            self.editButton.enabled = YES;
        } else {
            self.editButton.enabled = NO;
        }
        //显示编辑按钮
        self.navigationItem.rightBarButtonItem = self.editButton;
    }
}

- (void)updateDeleteButtonTitle {
    // 根据选中情况 更新删除标题
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];

    BOOL allItemsAreSelected = selectedRows.count == self.dataSource.count;
    BOOL noItemsAreSelected = selectedRows.count == 0;

    if (allItemsAreSelected || noItemsAreSelected) {
        self.deleteButton.title = @"删除所有";
    } else {
        self.deleteButton.title = [NSString stringWithFormat:@"删除 (%lu)", (unsigned long) selectedRows.count];
    }
}

#pragma mark -
#pragma mark === UIAlertViewDelegate ===
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userDefaults_pwd = [userDefaults objectForKey:[NSString stringWithFormat:@"%ld", (long)self.selectedIndex]];
    NSString *text_pwd = [[alertView textFieldAtIndex:0] text];
    if (buttonIndex == 1) {
        // 判读密码是否相等
        if ([userDefaults_pwd isEqualToString:text_pwd]) {
            VNNote *note = [self.dataSource objectAtIndex:_selectedIndex];
            NoteEditViewController *yy = [[NoteEditViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:yy animated:NO];
        } else {
            // 密码错误
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"密码错误"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alter show];
        }
    }
}

@end