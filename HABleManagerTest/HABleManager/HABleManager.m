//
//  HABleManager.m
//  EKLLighting
//
//  Created by Chris on 2021/4/30.
//

#import "HABleManager.h"

@interface HABleManager()

@property(nonatomic, strong) CBCentralManager *centralManager;
@property(nonatomic, strong) dispatch_queue_t eklCommandQueue;
@property(nonatomic, strong) NSMutableDictionary *bleModelDictionary;
@property(nonatomic, strong) NSTimer *heartTimer;

@end

@implementation HABleManager

+ (HABleManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self){
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        self.eklCommandQueue = dispatch_queue_create("EKL.ECOLOR.QUEUE", DISPATCH_QUEUE_SERIAL);
        self.bleModelDictionary = [NSMutableDictionary dictionary];
        _reConnectDeviceArray = [NSMutableArray array];
    }
    return self;
}

/*
 * 扫描
 * scan
 */
- (void)scanPeriperals:(_Nullable DiscoverPeriperalsBlock)discoverPeriperals{
    _discoverPeriBlock = discoverPeriperals;
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}];
}

/*
 * 停止扫描
 * stop scan
 */
- (void)stopScanPeriperals{
    [self.centralManager stopScan];
}

/*
 * 连接
 * connect
 */
- (void)connectToPeripheral:(CBPeripheral *)peripheral success:(SuccessConnectToPeriperalBlock)success fail:(FailConnectToPeriperalBlock)fail characteristic:(DiscoverCharacteristicBlock)characteristic
{
    _successBlock = success;
    _failBlock = fail;
    _discoverCharacteristicBlock = characteristic;
    if (peripheral) {
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

/*
 * 断开连接
 * cancel connect
 */
- (void)cancelConnectToPeripheral:(_Nullable CancelConnectToPeriperalBlock)cancel
{
    _cancelBlock = cancel;
    [self destroyBleConnect];
    _weakself;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakself.cancelBlock) {
            weakself.cancelBlock(nil, nil, nil);
            weakself.cancelBlock = nil;
        }
    });
}

- (void)destroyBleConnect
{
    _discoverCharacteristicBlock = nil;
    _writeCharacter = nil;
    [_bleModelDictionary removeAllObjects];
    if (_currentPeri) {
        [self.centralManager cancelPeripheralConnection:_currentPeri];
    }
}

- (void)removeAllCommand
{
    [_bleModelDictionary removeAllObjects];
}

/*
 * 发送数据
 * send data
 */

+ (void)sendDataToPeri:(Byte *)cmd completion:(void (^ _Nullable)(HABleModel *bleModel))completion
{
    [HABleManager sendDataToPeri:cmd lenght:CMD_LENGHT completion:completion];
}

+ (void)sendDataToPeri:(Byte *)cmd lenght:(NSInteger)lenght completion:(void (^ _Nullable)(HABleModel *bleModel))completion {
    
    NSData *command = [NSData dataWithBytes:cmd length:lenght];
    [HABleManager sendCommandData:command completion:completion];
}

+ (void)sendCommandData:(NSData *)command completion:(void (^ _Nullable)(HABleModel *bleModel))completion
{
    NSString *cmdHexString = [HABleTool convertDataToHexStr:command];
    NSString *cmdHeader = [cmdHexString substringToIndex:4];
    
    HABleManager *eleMgr = [HABleManager sharedManager];
    
    HABleModel *bleModel = [[HABleModel alloc] init];
    bleModel.bleCompleHander = completion;
    
    if (!eleMgr.writeCharacter && eleMgr.cState == KConnectNone) {
        return;
    }
    
    if (eleMgr.currentPeri && eleMgr.writeCharacter) {
        if (!eleMgr.writeCharacter.isNotifying) {
            [eleMgr.currentPeri setNotifyValue:YES forCharacteristic:eleMgr.writeCharacter];
        }
        eleMgr.bleModelDictionary[[cmdHeader stringByAppendingString:@"ble"]] = bleModel;  //蓝牙，wifi的逻辑我去掉了

        dispatch_block_t commandTask = ^{
            [eleMgr.currentPeri writeValue:command
                 forCharacteristic:eleMgr.writeCharacter
                             type:CBCharacteristicWriteWithoutResponse];
        };
        dispatch_async(eleMgr.eklCommandQueue, commandTask);
    }
}

/*
 * 读取信号量
 * read RSSI
 */
- (void)readRSSIWithPeriperal:(CBPeripheral *)peripheral{
    [peripheral readRSSI];
}

- (void)getOTACharacteristics:(CBService *)service
{
    for (CBCharacteristic *character in service.characteristics) {
        if ([character.UUID.UUIDString containsString:kFRQWriteCharacteristicUUID]) { //写
            _writeOTACharacteristic = character;
        }
        else if ([character.UUID.UUIDString containsString:kFRQReadCharacteristicUUID]){ //读
            _readOTACharacteristic = character;
        }
    }
}

- (void)handleRecvData:(NSData *)data topic:(NSString *)topic
{
    NSString *dataString = [HABleTool convertDataToHexStr:data];
    if (dataString.length < 4) {
        return;
    }
    NSString *cmdHeader = [dataString substringToIndex:4];
    NSString *type = (topic ? @"wifi": @"ble");
    cmdHeader = [cmdHeader stringByAppendingString:type];
    HABleModel *bleModel = _bleModelDictionary[cmdHeader];
    if (bleModel) {
        [bleModel parserCmdData:data];
        bleModel.topic = topic;
        if (bleModel.bleCompleHander) {
            bleModel.bleCompleHander(bleModel);
        }
    }else{  //这里是蓝牙主动给手机发消息时的处理，可以在业务层实现bleSyncHander的相关逻辑
        HABleModel *bleModel = [[HABleModel alloc] init];
        [bleModel parserCmdData:data];
        bleModel.topic = topic;
        if (_bleSyncHander) {
            _bleSyncHander(bleModel);
        }
    }
}

- (void)removeOneCommand:(NSString *)cmdHeader
{
    NSString *wifikey = [cmdHeader stringByAppendingString:@"wifi"];
    NSString *blekey = [cmdHeader stringByAppendingString:@"ble"];
    [_bleModelDictionary removeObjectsForKeys:@[wifikey, blekey]];
}

- (BOOL)bleAvaliable
{
    bool avaliable = [_isAvaliable boolValue];
    return avaliable;
}

- (NSTimer *)heartTimer{
    if (!_heartTimer){
        _weakself;
        _heartTimer = [NSTimer scheduledTimerWithTimeInterval:3 block:^{
            Byte byte[20] = {0x66};
            if (weakself.currentPeri && weakself.writeCharacter) {
                [HABleManager sendDataToPeri:byte completion:^(HABleModel * _Nonnull bleModel) {
                    NSLog(@"heartTimer: %@", bleModel.cmdHeader);
                }];
            }else {
                if ([self bleAvaliable]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"KBleReconnectNotification" object:nil];
                }
            }
        } repeats:YES];
        
//        // 将定时器加入循环。mode为NSRunLoopCommonModes，防止页面滑动造成定时器停止。
//        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _heartTimer;
}

- (void)startHeartBeat
{
    NSTimer *timer = [self heartTimer];
    [timer fire];
}

- (BOOL)isHeartTimerValid
{
    return [_heartTimer isValid];
}

- (void)stopHeartBeat
{
    [_heartTimer invalidate];
    _heartTimer = nil;
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    _isAvaliable = @"0";
    switch (central.state){
        case CBManagerStatePoweredOn:
            NSLog(@"蓝牙开启且可用");
            _isAvaliable = @"1";
            [self scanPeriperals:_discoverPeriBlock];
            break;
        case CBManagerStateUnknown:
            NSLog(@"手机没有识别到蓝牙，请检查手机。"); break;
        case CBManagerStateResetting:
            NSLog(@"手机蓝牙已断开连接，重置中。"); break;
        case CBManagerStateUnsupported:
            NSLog(@"手机不支持蓝牙功能，请更换手机。"); break;
        case CBManagerStatePoweredOff:
            break;
        case CBManagerStateUnauthorized:
            break;
    }
    if ([_isAvaliable isEqualToString:@"0"]) {
        _currentPeri = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CentralManagerStatusUpdate" object:_isAvaliable];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    peripheral.advertisementData = advertisementData;
    if (_discoverPeriBlock) {
        _discoverPeriBlock(central, peripheral, advertisementData, RSSI);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    _currentPeri = peripheral;
    NSString *bleName = [peripheral.advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSLog(@"cmdHeader didConnectPeripheral: %@, %@", bleName, _currentPeri);
    if (_discoverCharacteristicBlock == nil) {
        [self destroyBleConnect];
        return;
    }
    if (_successBlock) {
        _successBlock(central, peripheral);
    }
    
    peripheral.delegate = self;
    
    CBUUID  *serviceUUID    = [CBUUID UUIDWithString:CharacteristicServiceUUIDWrite];
    CBUUID  *serviceOTAUUID    = [CBUUID UUIDWithString:kFRQServiceUUID];
    NSArray  *serviceArray  = [NSArray arrayWithObjects:serviceUUID, serviceOTAUUID, nil];
    [peripheral discoverServices:serviceArray];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    _currentPeri = nil;
    [_reConnectDeviceArray removeAllObjects];
    if (_failBlock) {
        _failBlock(central, peripheral, error);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    _currentPeri = nil;
    [_reConnectDeviceArray removeAllObjects];
    if (_cancelBlock) {
        _cancelBlock(central, peripheral, error);
        _cancelBlock = nil;
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CancelConnectToPeriperal" object:peripheral];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
   
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (_discoverCharacteristicBlock == nil) {
        [self destroyBleConnect];
        return;
    }
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (_discoverCharacteristicBlock == nil) {
        [self destroyBleConnect];
        return;
    }
    for (CBCharacteristic *cha in service.characteristics){
        if ([cha.UUID.UUIDString isEqualToString:CharacteristicUUIDWrite]){
            //获取特征
            _writeCharacter = cha;
            if (_discoverCharacteristicBlock) {
                _discoverCharacteristicBlock(peripheral, service, error);
            }
        }
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties&CBCharacteristicPropertyRead || characteristic.properties&CBCharacteristicPropertyBroadcast) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    [self getOTACharacteristics:service];
}

//读蓝牙数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([characteristic.UUID.UUIDString isEqualToString:CharacteristicUUIDWrite]){
        //获取特征
        NSData *data = characteristic.value;
        [self handleRecvData:data topic:nil];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
   
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (_haWriteBlock) {
        _haWriteBlock(characteristic, error);
    }
}

@end
