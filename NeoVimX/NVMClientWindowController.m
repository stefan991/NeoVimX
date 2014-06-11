//
//  NVMClientWindowController.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMClientWindowController.h"
#import "NVMClient.h"
#import "NVMTextView.h"


@interface NVMClientWindowController ()

@end


@implementation NVMClientWindowController

- (id)init
{
	self = [super initWithWindowNibName:@"NVMClientWindow"];
    if (self) {

    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.client = [NVMClient new];
    [self.client connectTo:@"/tmp/neovim"];

    [self.client discoverApi:^(id error, id result) {

        [self.textView connectToClient:self.client];

        [self.client subscribeEvent:@"redraw:layout"
                           callback:^(id error, id result) {
            NSLog(@"redraw:layout: %@", result);
        }];

        [self.client subscribeEvent:@"redraw:tabs"
                           callback:^(id error, id result) {
            NSLog(@"redraw:tabs: %@", result);
        }];

        [self.client callMethod:@"vim_request_screen"
                         params:nil
                       callback:^(id error, id result) { }];
    }];
}

@end
