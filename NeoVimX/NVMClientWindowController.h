//
//  NVMClientWindowController.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NVMClient;
@class NVMWindowViewController;


@interface NVMClientWindowController : NSWindowController

@property (weak) IBOutlet NSView *contentView;

@property (retain) NVMClient *client;
@property (retain) NVMWindowViewController *windowViewController;

@end
