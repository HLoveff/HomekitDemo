//
//  currentRoomVC.m
//  HomeKitDemo
//
//  Created by 王子胜 on 16/9/26.
//  Copyright © 2016年 王子胜. All rights reserved.
//

#import "currentRoomVC.h"

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self

@interface currentRoomVC ()<HMAccessoryBrowserDelegate,UITableViewDelegate,UITableViewDataSource,HMAccessoryDelegate>

@property (strong, nonatomic) HMAccessoryBrowser * broswer;

@property (strong, nonatomic) UITableView * tableView;
@property (strong, nonatomic) UIView * headerView;
@property (nonatomic, strong) UIView *footerView;
@property (strong, nonatomic) NSMutableArray * dataArray;

@property (nonatomic, strong) HMCharacteristic *wirteCha;
@property (nonatomic, strong) HMCharacteristic *readCha;

@end

@implementation currentRoomVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = self.currentRoom.name;
    
    //配置子视图
    [self.view addSubview:self.tableView];
    
    //布局子视图
    self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"abcCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abcCell"];
    }

    
    if (indexPath.section == 0) {
        HMAccessory * accessory = self.dataArray[indexPath.row];
        cell.textLabel.text = accessory.name;
    }
    else
    {
        HMAccessory * accessory = self.myHome.accessories[indexPath.row];
        cell.textLabel.text = accessory.name;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (section == 0) {
        return self.dataArray.count;
    }else{
        return self.myHome.accessories.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        
        HMAccessory * access = self.dataArray[indexPath.row];
        if (access.room != self.currentRoom) {
            
        }
        WS(weakSelf);
        [self.myHome addAccessory:access completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@",error);
            } else {
                [weakSelf.myHome assignAccessory:access toRoom:weakSelf.currentRoom completionHandler:^(NSError * _Nullable error) {
                    
                }];
            }
        }];
    }else{
        
        HMAccessory * access = self.myHome.accessories[indexPath.row];
        access.delegate = self;
        for (HMService * service in access.services) {
            
            //这里要根据不同类型的 特征属性 来设置不同类型的值,下面只是举个栗子
            for(HMCharacteristic * character in service.characteristics)
            {
                //特征属性为
                NSLog(@"属性类型为:%@",character.characteristicType);
                NSLog(@"特征属性有:%@",character.properties);
                [character readValueWithCompletionHandler:^(NSError * _Nullable error) {
                    
                }];
                [character writeValue:@(1) completionHandler:^(NSError * _Nullable error) {
                    if (!error) {
                        NSLog(@"设置成功");
                    }else{
                        NSLog(@"设置失败");
                    }
                }];
            }
//            NSLog(@"%@",service.characteristics);
        }
    }

    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"未添加的设备";
    }else{
        return @"已添加的设备";
    }
}


#pragma mark - HMAccessoryBrowserDelegate
- (void)accessoryBrowser:(HMAccessoryBrowser *)browser didFindNewAccessory:(HMAccessory *)accessory{
    //获取到新硬件
    [self.dataArray addObject:accessory];
    [self.tableView reloadData];
    NSLog(@"发现一个新硬件");

}

- (void)accessoryBrowser:(HMAccessoryBrowser *)browser didRemoveNewAccessory:(HMAccessory *)accessory{
    //移除新硬件
    [self.dataArray removeObject:accessory];
    [self.tableView reloadData];
    
    NSLog(@"失去一个新硬件");
}

- (void)accessory:(HMAccessory *)accessory service:(HMService *)service didUpdateValueForCharacteristic:(HMCharacteristic *)characteristic
{
    //更新了属性
    
}

#pragma mark - Action
- (void)scanAccess{
    //开始扫描新硬件
    [self.broswer startSearchingForNewAccessories];
    NSLog(@"开始扫描");
}

- (void)stopScanAccess{
    //停止扫描新硬件
    [self.broswer stopSearchingForNewAccessories];
    NSLog(@"结束扫描");
}

- (void)openEquipmentAccess {
    [self handleAccessory];
}

- (void)closeEquipmentAccess {
    [self handleAccessory];
}

- (void)handleAccessory {
    for (int i = 0; i < self.dataArray.count; i++) {
        HMAccessory *accessory = self.dataArray[i];
        HMService *mySeverce = accessory.services[i];
        for (int j = 0; j < mySeverce.characteristics.count; j++) {
            NSLog(@"服务的特征为 = %@",(mySeverce.characteristics[j].properties));
            HMCharacteristic *myCharacteristic = mySeverce.characteristics[j];
            if ([myCharacteristic.properties[0] isEqual:HMCharacteristicPropertyReadable]) {
                self.readCha = myCharacteristic;
                [self.readCha enableNotification:YES completionHandler:^(NSError * _Nullable error) {
                    // 接收外设的通知
                }];
            } else {
                self.wirteCha = myCharacteristic;
                [self.wirteCha enableNotification:YES completionHandler:^(NSError * _Nullable error) {
                    if (error == nil) {
                        id myValue = self.wirteCha.value;
                        NSLog(@"特征的状态%@",myValue);
                        if (myValue == 0) {
                            [self.wirteCha writeValue:@1 completionHandler:^(NSError * _Nullable error) {
                                if (error == nil) {
                                    NSLog(@"写入成功");
                                } else {
                                    NSLog(@"写入失败");
                                }
                            }];
                        } else {
                            [self.wirteCha writeValue:@0 completionHandler:^(NSError * _Nullable error) {
                                if (error == nil) {
                                    NSLog(@"写入成功");
                                } else {
                                    NSLog(@"写入失败");
                                }
                            }];
                        }
                    } else {
                        NSLog(@"读取特征失败");
                    }
                }];
            }
        }
    }
}

#pragma mark - Lazy

- (HMAccessoryBrowser *)broswer{
    
    if (_broswer == nil) {
        _broswer = [HMAccessoryBrowser new];
        _broswer.delegate = self;
        
        [self.dataArray addObjectsFromArray:_broswer.discoveredAccessories];
        [self.tableView reloadData];
    }
    return _broswer;
}

- (UITableView *)tableView{
    
    if (_tableView == nil) {
        _tableView = [UITableView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableHeaderView = self.headerView;
        _tableView.tableFooterView = [UIView new];
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"abcCell"];
    }
    return _tableView;
}

- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (UIView *)headerView{
    if (_headerView == nil) {
        
        _headerView = [UIView new];
        _headerView.backgroundColor = [UIColor redColor];
        
        UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [startBtn setTitle:@"开始扫描" forState:UIControlStateNormal];
        [startBtn addTarget:self action:@selector(scanAccess) forControlEvents:UIControlEventTouchUpInside];
        startBtn.backgroundColor = [UIColor blueColor];
        
        UIButton * stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [stopBtn setTitle:@"停止扫描" forState:UIControlStateNormal];
        [stopBtn addTarget:self action:@selector(stopScanAccess) forControlEvents:UIControlEventTouchUpInside];
        stopBtn.backgroundColor = [UIColor purpleColor];
        
        [_headerView addSubview:startBtn];
        [_headerView addSubview:stopBtn];
        
        _headerView.frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 150);
        startBtn.frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width/2, 50);
        stopBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2, 100, [UIScreen mainScreen].bounds.size.width/2, 50);

    }
    return _headerView;
}

- (UIView *)footerView {
    if (_footerView == nil) {
        
        _footerView = [UIView new];
        _footerView.backgroundColor = [UIColor redColor];
        
        UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [startBtn setTitle:@"开启设备" forState:UIControlStateNormal];
        [startBtn addTarget:self action:@selector(openEquipmentAccess) forControlEvents:UIControlEventTouchUpInside];
        startBtn.backgroundColor = [UIColor blueColor];
        
        UIButton * stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [stopBtn setTitle:@"关闭选中设备" forState:UIControlStateNormal];
        [stopBtn addTarget:self action:@selector(closeEquipmentAccess) forControlEvents:UIControlEventTouchUpInside];
        stopBtn.backgroundColor = [UIColor purpleColor];
        
        [_footerView addSubview:startBtn];
        [_footerView addSubview:stopBtn];
        
        _footerView.frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 150);
        startBtn.frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width/2, 50);
        stopBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2, 100, [UIScreen mainScreen].bounds.size.width/2, 50);

    }
    return _footerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
