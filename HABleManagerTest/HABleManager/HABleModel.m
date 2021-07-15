//
//  HABleModel.m
//  EKLLighting
//
//  Created by Chris on 2021/4/30.
//

#import "HABleModel.h"
#import "HABleTool.h"

@interface HABleModel ()
{
    NSArray *_cmdArray;
}

@end

@implementation HABleModel

- (void)parserCmdData:(NSData *)data
{
    _originData = data;
    NSString *dataString = [HABleTool convertDataToHexStr:data];
    _originString = dataString;
    
    _cmdHeader = [dataString substringToIndex:4];
    
    NSArray *originArray = [NSArray arrayWithArray:[HABleTool convertDataToArray:data]];
    NSArray *dataArray = [originArray subarrayWithRange:NSMakeRange(_cmdHeader.length / 2, originArray.count - _cmdHeader.length / 2)];
    
    _dataByteArray = dataArray;
    
}

@end
