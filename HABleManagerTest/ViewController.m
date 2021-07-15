//
//  ViewController.m
//  HABleManagerTest
//
//  Created by Chris on 2021/7/15.
//

#import "ViewController.h"
#import "HABleManager.h"
#import "MBProgressHUD.h"

@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *peripheralListArray;
@property (nonatomic ,strong) NSTimer *scanTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.peripheralListArray = [NSMutableArray array];
    [self startScan];
}

- (void)startScan {
    [_peripheralListArray removeAllObjects];
    _weakself;
    [[HABleManager sharedManager] scanPeriperals:^(CBCentralManager * _Nonnull central, CBPeripheral * _Nonnull peripheral,   NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
        [weakself.peripheralListArray addObject:peripheral];
        [weakself.devicesTableView reloadData];
   }];
}

- (IBAction)switchOnAction:(UIButton *)sender {
    Byte byte[20] = {0xaa, 0x01, 0x01};
    [HABleManager sendDataToPeri:byte completion:^(HABleModel * _Nonnull bleModel) {
        NSLog(@"cmdHeader : %@", bleModel.cmdHeader); //蓝牙回的消息
        //如果这里的业务逻辑比较复杂，可以在页面返回的事件方法中调用：[[HABleManager sharedManager] removeAllCommand];
    }];
}

- (IBAction)switchOffAction:(UIButton *)sender {
    Byte byte[20] = {0xaa, 0x01, 0x00};
    [HABleManager sendDataToPeri:byte completion:^(HABleModel * _Nonnull bleModel) {
        NSLog(@"cmdHeader : %@", bleModel.cmdHeader);  //蓝牙回的消息
    }];
}

#pragma mark - tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _peripheralListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.devicesTableView dequeueReusableCellWithIdentifier:@"demoCell" forIndexPath:indexPath];
    CBPeripheral *peripheral = [self.peripheralListArray objectAtIndex:indexPath.row];
    NSString *periName = [NSString stringWithFormat:@"%@", [peripheral.advertisementData objectForKey:@"kCBAdvDataLocalName"]];

    cell.textLabel.text = [NSString stringWithFormat:@"%@, 状态：%@", periName, peripheral.state == CBPeripheralStateConnected?@"已连接":@"未连接"];
    //信号和服务
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID：%@",[peripheral.identifier UUIDString]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CBPeripheral *peripheral = [self.peripheralListArray objectAtIndex:indexPath.row];

    //弹窗确认
    NSString *noticeText = [NSString stringWithFormat:@"确定连接蓝牙设备(%@)？",peripheral.name?:@"N/A"];
    UIAlertController *confirmAlertCtrl = [UIAlertController alertControllerWithTitle:@"提醒" message:noticeText preferredStyle:UIAlertControllerStyleAlert];
    [confirmAlertCtrl addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[HABleManager sharedManager] connectToPeripheral:peripheral success:nil fail:nil characteristic:^(CBPeripheral * _Nonnull CBPeripheral, CBService * _Nonnull service, NSError * _Nonnull error) {
            NSLog(@"ble %@ 连接成功", peripheral.name);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (![[HABleManager sharedManager] isHeartTimerValid]) {
                [[HABleManager sharedManager] startHeartBeat];
            }
        }];
    }]];
    [confirmAlertCtrl addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:confirmAlertCtrl animated:YES completion:nil];
    
}

@end
