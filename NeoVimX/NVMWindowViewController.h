//
//  NVMWindowViewController.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NVMTextView;


@interface NVMWindowViewController : NSViewController

// contentView clips the NVMTextview
@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSLayoutConstraint *textViewWidth;
@property (weak) IBOutlet NSLayoutConstraint *textViewHeight;
@property (strong) NVMTextView *textView;

- (void)redraw_layout:(NSDictionary *)layoutNode;

@end
