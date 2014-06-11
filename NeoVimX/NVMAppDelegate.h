//
//  NVMAppDelegate.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 03.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NVMClient;
@class NVMTextView;

@interface NVMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NVMTextView *textView;

@property (retain) NVMClient *client;

@end
