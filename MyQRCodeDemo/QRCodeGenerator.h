//
//  QRCodeGenerator.h
//  MyQRCodeDemo
//
//  Created by Monky on 17/1/13.
//  Copyright (c) 2017年 MKBlueTooth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface QRCodeGenerator : NSObject
//for ios7+ 生成二维码
- (UIImage *)imageWithSize:(CGFloat)size andColorWithRed:(CGFloat)red Green:(CGFloat)green Blue:(CGFloat)blue andQRString:(NSString *)qrString;
@end
