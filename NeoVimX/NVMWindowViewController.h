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

@property (unsafe_unretained) IBOutlet NVMTextView *textView;
@property (weak) IBOutlet NSLayoutConstraint *textViewWidth;
@property (weak) IBOutlet NSLayoutConstraint *textViewHeight;

- (void)redraw_layout:(NSDictionary *)event_data;

@end
