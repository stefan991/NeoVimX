//
//  NVMWindowViewController.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NVMTextView;
@class NVMClientWindowController;


@interface NVMWindowViewController : NSViewController

// contentView clips the NVMTextview
@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSLayoutConstraint *textViewWidth;
@property (weak) IBOutlet NSLayoutConstraint *textViewHeight;
@property (weak) IBOutlet NSLayoutConstraint *statusLineHeight;

@property (strong) NVMTextView *textView;

@property (weak) NVMClientWindowController *clientWindowController;

- (void)redrawLayout:(NSDictionary *)layoutNode;

@end
