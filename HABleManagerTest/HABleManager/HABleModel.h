//
//  HABleModel.h
//  EKLLighting
//
//  Created by Chris on 2021/4/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HABleModel : NSObject

@property (nonatomic, copy) NSString *cmdHeader;       //指令部分
@property (nonatomic, copy) NSString *topic;           //wifi设备主题
@property (nonatomic, strong) NSArray *dataByteArray;  //数据部分
@property (nonatomic, copy) NSString *originString;    //原始字符串
@property (nonatomic, strong) NSData *originData;      //原始数据
@property (nonatomic, copy, nullable) void (^bleCompleHander)(HABleModel *);    //回调

- (void)parserCmdData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
