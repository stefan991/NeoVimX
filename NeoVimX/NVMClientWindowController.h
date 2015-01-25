//
//  NVMClientWindowController.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NVMClient;


@interface NVMClientWindowController : NSWindowController

@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSLayoutConstraint *contentViewWidth;
@property (weak) IBOutlet NSLayoutConstraint *contentViewHeight;

@property (retain) NVMClient *client;

@property (readonly) NSSize cellSize;
@property (strong) NSColor *foregroundColor;
@property (strong) NSColor *backgroundColor;

@end
