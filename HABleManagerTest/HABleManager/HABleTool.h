//
//  HABleTool.h
//  HABleManagerTest
//
//  Created by Chris on 2021/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



@interface HABleTool : NSObject

+ (NSString *)convertDataToHexStr:(NSData *)data;
+ (NSArray *)convertDataToArray:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
