//
//  NSColor+NeoVimX.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NSColor+NeoVimX.h"

@implementation NSColor (NeoVimX)

+ (NSColor*)NVM_colorWithHexColorString:(NSString*)inColorString
{
    // from http://stackoverflow.com/a/8697241
    NSColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;

    if (nil != inColorString)
    {
        NSScanner* scanner = [NSScanner scannerWithString:inColorString];
        if(![scanner scanHexInt:&colorCode]) {
            NSLog(@"invalid hex color: %@", inColorString);
        }
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits

    result = [NSColor
              colorWithCalibratedRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
    return result;
}


@end
