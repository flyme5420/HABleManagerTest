//
//  HABleManager.h
//  EKLLighting
//
//  Created by Chris on 2021/4/30.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "HABleModel.h"
#import "HABleTool.h"
#import "NSTimer+Blocks.h"
#import "CBPeripheral+RSSI.h"

#define CMD_LENGHT 20
#define _weakself __weak __typeof(&*self) weakself = self

typedef enum : NSUInteger {
    KConnectNone,
    KConnectWiFi,
} KConnectState;

//OTA特定的服务标识
#define kFRQServiceUUID             @"02F00000-0000-0000-0000-00000000FE00"
#define kFRQWriteCharacteristicUUID @"02F00000-0000-0000-0000-00000000FF01"
#define kFRQReadCharacteristicUUID  @"02F00000-0000-0000-0000-00000000FF02"

#define CharacteristicUUIDWrite @"6E616974-6E61-6974-6568-6E65776E6577"
#define CharacteristicServiceUUIDWrite @"6E61646E-6164-646E-6161-7568756f687A"

NS_ASSUME_NONNULL_BEGIN

//ble
typedef void (^SuccessConnectToPeriperalBlock)(CBCentralManager *central, CBPeripheral *peripheral);
typedef void (^FailConnectToPeriperalBlock)(CBCentralManager *central, CBPeripheral *peripheral, NSError *error);
typedef void (^CancelConnectToPeriperalBlock)(CBCentralManager *central, CBPeripheral *peripheral, NSError *error);
typedef void (^DiscoverPeriperalsBlock)(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary<NSString *, id> * advertisementData, NSNumber *RSSI);
typedef void (^DiscoverCharacteristicBlock)(CBPeripheral *CBPeripheral, CBService *service, NSError *error);
typedef void (^HADidWriteValueForCharacteristicBlock)(CBCharacteristic *characteristic,NSError *error);

//wifi
//typedef void(^MQTTDidConnect)(void);
//typedef void(^MQTTDidSubscribe)(void);
//typedef void(^MQTTDidPublished)(void);

@interface HABleManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic, strong) CBPeripheral *currentPeri;
@property(nonatomic, copy) NSString *isAvaliable;
@property(nonatomic, assign) KConnectState cState;
@property(nonatomic, strong) NSMutableArray *reConnectDeviceArray;
@property(nonatomic, strong) CBCharacteristic *writeCharacter;
@property(nonatomic, copy) SuccessConnectToPeriperalBlock successBlock;
@property(nonatomic, copy) FailConnectToPeriperalBlock failBlock;
@property(nonatomic, copy) CancelConnectToPeriperalBlock cancelBlock;
@property(nonatomic, copy) DiscoverPeriperalsBlock discoverPeriBlock;
@property(nonatomic, copy) DiscoverCharacteristicBlock discoverCharacteristicBlock;
@property(nonatomic, copy) HADidWriteValueForCharacteristicBlock haWriteBlock;
@property(nonatomic, copy) void (^bleSyncHander)(HABleModel *bleModel); //蓝牙主动发信息
//@property(nonatomic, copy) MQTTDidSubscribe mqttDidSubscribe;
//@property(nonatomic, copy) MQTTDidConnect mqttDidConnect;
//@property(nonatomic, copy) MQTTDidPublished mqttDidPublished;

@property(nonatomic, strong) CBCharacteristic *writeOTACharacteristic;
@property(nonatomic, strong) CBCharacteristic *readOTACharacteristic;

+ (HABleManager *)sharedManager;

- (void)scanPeriperals:(_Nullable DiscoverPeriperalsBlock)discoverPeriperals;
- (void)stopScanPeriperals;
- (void)connectToPeripheral:(CBPeripheral *)peripheral success:(SuccessConnectToPeriperalBlock)success fail:(FailConnectToPeriperalBlock)fail characteristic:(DiscoverCharacteristicBlock)characteristic;
- (void)cancelConnectToPeripheral:(_Nullable CancelConnectToPeriperalBlock)cancel;
- (void)readRSSIWithPeriperal:(CBPeripheral *)peripheral;
+ (void)sendDataToPeri:(Byte *)cmd completion:(void (^ _Nullable)(HABleModel *bleModel))completion;
+ (void)sendDataToPeri:(Byte *)cmd lenght:(NSInteger)lenght completion:(void (^ _Nullable)(HABleModel *bleModel))completion;
+ (void)sendCommandData:(NSData *)command completion:(void (^ _Nullable)(HABleModel *bleModel))completion;
- (BOOL)bleAvaliable;
- (void)removeOneCommand:(NSString *)cmdHeader;
- (void)removeAllCommand;
- (void)startHeartBeat;
- (void)stopHeartBeat;
- (BOOL)isHeartTimerValid;

//mqtt的代码，暂时不上传
//- (void)connectToMQTT:(MQTTDidSubscribe)mqttSubscribe;
//- (void)disconnectMqtt;
//+ (void)sendWifiCommand:(Byte *)cmd didPublish:(MQTTDidPublished)didPublish completion:(void (^ _Nullable)(HABleModel *bleModel))completion;
//- (void)startOTAUpdateWithUrl:(NSURL *)fileUrl delegate:(id)delegate;
//- (void)subscribeToTopic:(NSString *)topic didSubscribe:(MQTTDidSubscribe)didSubscribe;
//- (void)unsubscribeToTopic:(NSString *)topic;
//- (void)queryDeviceList:(dispatch_block_t)completion;
//- (void)queryDeviceOnline:(Device * _Nullable)oneDevice;
//- (Device *)getDeviceWithLocalUUID:(NSString *)localUUID;

@end

NS_ASSUME_NONNULL_END
