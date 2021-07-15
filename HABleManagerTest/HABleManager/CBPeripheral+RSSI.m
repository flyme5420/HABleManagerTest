//
//  CBPeripheral+RSSI.m
//  EKLLighting
//
//  Created by sunbinbin on 2020/12/16.
//

#import "CBPeripheral+RSSI.h"
@implementation CBPeripheral (RSSI)

char nameKey;

- (void)setRssi:(NSNumber *)rssi{
    objc_setAssociatedObject(self, &nameKey, rssi, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)rssi{
    return objc_getAssociatedObject(self, &nameKey);
}

-(void)setAdvertisementData:(NSDictionary *)advertisementData {
    objc_setAssociatedObject(self, &nameKey, advertisementData, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSDictionary *)advertisementData {
    return objc_getAssociatedObject(self, &nameKey);
}




@end
