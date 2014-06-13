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
#import "NVMSplitView.h"


@interface NVMClientWindowController ()

@property (retain) NSMutableDictionary *windowViewControllers;

@end


@implementation NVMClientWindowController

- (id)init
{
	self = [super initWithWindowNibName:@"NVMClientWindow"];
    if (self) {
        self.windowViewControllers = [NSMutableDictionary new];
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
                           callback:^(id error, id eventData) {
            [self.windowViewControllers enumerateKeysAndObjectsUsingBlock:
                ^(id key, NVMWindowViewController *controller, BOOL *stop) {
                [controller.textView redraw_foreground_color:eventData];
            }];
        }];

        [self.client subscribeEvent:@"redraw:background_color"
                           callback:^(id error, id eventData) {
            [self.windowViewControllers enumerateKeysAndObjectsUsingBlock:
                ^(id key, NVMWindowViewController *controller, BOOL *stop) {
                [controller.textView redraw_background_color:eventData];
            }];
        }];

        [self subscribeTextViewEvent:@"redraw:update_line"
                            selector:@selector(redraw_update_line:)];

        [self subscribeTextViewEvent:@"redraw:delete_line"
                            selector:@selector(redraw_delete_line:)];

        [self subscribeTextViewEvent:@"redraw:insert_line"
                            selector:@selector(redraw_insert_line:)];

        [self subscribeTextViewEvent:@"redraw:win_end"
                            selector:@selector(redraw_window_end:)];

        [self subscribeTextViewEvent:@"redraw:cursor"
                            selector:@selector(redraw_cursor:)];

        [self.client subscribeEvent:@"redraw:layout"
                           callback:^(id error, id event_data) {
            NSLog(@"redraw:layout: %@", event_data);
            [self redraw_layout:event_data];
        }];

        [self.client subscribeEvent:@"redraw:tabs"
                           callback:^(id error, id result) {
            // NSLog(@"redraw:tabs: %@", result);
        }];

        // TODO(stefan991): handle event subscription callback instead of waiting
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self.client callMethod:@"vim_request_screen"
                             params:nil
                           callback:^(id error, id result) { }];
        });
    }];
}

- (void)subscribeTextViewEvent:(NSString *)eventName
                      selector:(SEL)selector
{
    NVMCallback callback = ^(id error, id eventData) {
        NSNumber *windowID = eventData[@"window_id"];
        NVMWindowViewController *viewController =
            self.windowViewControllers[windowID];
        if (viewController) {
            [viewController.textView performSelector:selector
                                          withObject:eventData];
        } else {
            NSLog(@"window id not found");
        }
    };
    [self.client subscribeEvent:eventName
                       callback:callback];
}

- (void)redraw_layout:(NSDictionary *)event_data
{
    // TODO(stefan991): cleanup self.windowViewControllers after layout
    NSView *view = [self viewForNode:event_data];

    [view removeFromSuperview];
    [self.contentView.subviews.lastObject removeFromSuperview];
    [self.contentView addSubview:view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [self.contentView addConstraints:
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                options:0
                                                metrics:nil
                                                  views:views]];
    [self.contentView addConstraints:
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                options:0
                                                metrics:nil
                                                  views:views]];
}

- (NSView *)viewForNode:(NSDictionary *)node
{
    NSString *type = node[@"type"];
    if ([type isEqualToString:@"leaf"]) {
        NSNumber *windowID = node[@"window_id"];
        NVMWindowViewController *viewController =
            self.windowViewControllers[windowID];
        if (!viewController) {
            viewController = [NVMWindowViewController new];
            self.windowViewControllers[windowID] = viewController;
        }
        // remove from supervriew before setting the size,
        // avoids mutally exclusive constraints
        [viewController.view removeFromSuperview];
        [viewController redraw_layout:node];
        return viewController.view;
    }

    NSMutableArray *subViews = [NSMutableArray new];
    for (NSDictionary *subNode in node[@"children"]) {
        [subViews addObject:[self viewForNode:subNode]];
    }

    if ([type isEqualToString:@"column"]) {
        return [[NVMSplitView alloc] initWithSubviews:subViews
                                            direction:NVMSplitViewHorizontal];
    } else if ([type isEqualToString:@"row"]) {
        return [[NVMSplitView alloc] initWithSubviews:subViews
                                            direction:NVMSplitViewVertical];
    }
    NSLog(@"invalid redraw:layout node: %@", node);
    return nil;
}

@end
