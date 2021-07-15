//
//  HABleTool.m
//  HABleManagerTest
//
//  Created by Chris on 2021/7/15.
//

#import "HABleTool.h"

@implementation HABleTool

+ (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

+ (NSArray *)convertDataToArray:(NSData *)data {
    if (!data || [data length] == 0) {
        return nil;
    }
    NSMutableArray *stringArray = [[NSMutableArray alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [stringArray addObject:hexStr];
            } else {
                [stringArray addObject:[NSString stringWithFormat:@"0%@", hexStr]];
            }
        }
    }];
    
    return stringArray;
}


@end
