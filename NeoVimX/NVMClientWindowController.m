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
#import "NVMWindowViewController.h"


@interface NVMClientWindowController ()

@end


@implementation NVMClientWindowController

- (id)init
{
	self = [super initWithWindowNibName:@"NVMClientWindow"];
    if (self) {
        self.windowViewController = [NVMWindowViewController new];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.client = [NVMClient new];
    [self.client connectTo:@"/tmp/neovim"];

    [self.client discoverApi:^(id error, id result) {

        [self.client subscribeEvent:@"redraw:foreground_color"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:foreground_color: %@", result);
            [self.windowViewController.textView  redraw_foreground_color:event_data];
        }];

        [self.client subscribeEvent:@"redraw:background_color"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:background_color: %@", result);
            [self.windowViewController.textView  redraw_background_color:event_data];
        }];

        [self.client subscribeEvent:@"redraw:update_line"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:update_line: %@", event_data);
            [self.windowViewController.textView  redraw_update_line:event_data];
        }];

        [self.client subscribeEvent:@"redraw:insert_line"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:insert_line: %@", event_data);
            [self.windowViewController.textView  redraw_insert_line:event_data];
        }];

        [self.client subscribeEvent:@"redraw:delete_line"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:delete_line: %@", event_data);
            [self.windowViewController.textView  redraw_delete_line:event_data];
        }];

        [self.client subscribeEvent:@"redraw:win_end"
                           callback:^(id error, id event_data) {
            // NSLog(@"redraw:win_end: %@", event_data);
            [self.windowViewController.textView redraw_window_end:event_data];
        }];

        [self.client subscribeEvent:@"redraw:cursor"
                           callback:^(id error, id event_data) {
          // NSLog(@"redraw:cursor: %@", event_data);
            [self.windowViewController.textView  redraw_cursor:event_data];
        }];

        [self.client subscribeEvent:@"redraw:layout"
                           callback:^(id error, id event_data) {
            NSLog(@"redraw:layout: %@", event_data);

            NSView *windowView = self.windowViewController.view;
            [self.contentView.subviews.lastObject removeFromSuperview];
            [self.contentView addSubview:windowView];
            windowView.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(windowView);

            [self.contentView addConstraints:
                [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[windowView]|"
                                                        options:0
                                                        metrics:nil
                                                          views:views]];
            [self.contentView addConstraints:
                [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[windowView]|"
                                                        options:0
                                                        metrics:nil
                                                          views:views]];
                                
            [self.windowViewController redraw_layout:event_data];
        }];

        [self.client subscribeEvent:@"redraw:tabs"
                           callback:^(id error, id result) {
            // NSLog(@"redraw:tabs: %@", result);
        }];

        [self.client callMethod:@"vim_request_screen"
                         params:nil
                       callback:^(id error, id result) { }];
    }];
}

@end
