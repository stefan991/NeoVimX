//
//  NSColor+NeoVimX.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (NeoVimX)

+ (NSColor*)NVM_colorWithHexColorString:(NSString*)inColorString;

@end
