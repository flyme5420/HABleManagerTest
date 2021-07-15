//
//  CBPeripheral+RSSI.h
//  EKLLighting
//
//  Created by sunbinbin on 2020/12/16.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (RSSI)
@property(nonatomic,strong)NSNumber *rssi;
@property(nonatomic,strong)NSDictionary *advertisementData;
@end

NS_ASSUME_NONNULL_END
