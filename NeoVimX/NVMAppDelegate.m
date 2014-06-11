//
//  NVMAppDelegate.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 03.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMAppDelegate.h"
#import "NVMClientWindowController.h"


@interface NVMAppDelegate ()

@property (strong) NVMClientWindowController *clientWindowController;

@end


@implementation NVMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.clientWindowController = [NVMClientWindowController new];
    [self.clientWindowController showWindow:nil];
}

@end
