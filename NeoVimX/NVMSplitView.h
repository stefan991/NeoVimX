//
//  NVMSplitView.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, NVMSplitViewDirection) {
    NVMSplitViewHorizontal,
    NVMSplitViewVertical
};

@interface NVMSplitView : NSView

@property NVMSplitViewDirection directon;

- (instancetype)initWithSubviews:(NSArray *)subviews
                       direction:(NVMSplitViewDirection)direction
                        cellSize:(NSSize)cellSize;

@end
