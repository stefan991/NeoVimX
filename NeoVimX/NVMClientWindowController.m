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
        [self subscribeRedrawEvents];
    }];
}

- (void)subscribeEvent:(NSString *)eventName
              selector:(SEL)selector
                 group:(dispatch_group_t)group
{
    NVMCallback eventCallback = ^(id error, id eventData) {
        [self performSelector:selector
                   withObject:eventData];
    };
    dispatch_group_enter(group);
    [self.client subscribeEvent:eventName
                  eventCallback:eventCallback
              completionHandler:^(id error, id result) {
        dispatch_group_leave(group);
    }];
}

- (void)subscribeTextViewEvent:(NSString *)eventName
                      selector:(SEL)selector
                         group:(dispatch_group_t)group
{
    NVMCallback eventCallback = ^(id error, id eventData) {
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
    dispatch_group_enter(group);
    [self.client subscribeEvent:eventName
                  eventCallback:eventCallback
              completionHandler:^(id error, id result) {
        dispatch_group_leave(group);
    }];
}

- (void)subscribeRedrawEvents
{
    dispatch_group_t subscribeGroup = dispatch_group_create();

    // subscribe to events handled by self:
    [self subscribeEvent:@"redraw:foreground_color"
                selector:@selector(redrawForegroundColor:)
                   group:subscribeGroup];

    [self subscribeEvent:@"redraw:background_color"
                selector:@selector(redrawBackgroundColor:)
                   group:subscribeGroup];

    [self subscribeEvent:@"redraw:layout"
                selector:@selector(redraw_layout:)
                   group:subscribeGroup];

    [self subscribeEvent:@"redraw:tabs"
                selector:@selector(redrawTabs:)
                   group:subscribeGroup];

    // subscribe to events handled by the textviews:
    [self subscribeTextViewEvent:@"redraw:update_line"
                        selector:@selector(redraw_update_line:)
                           group:subscribeGroup];

    [self subscribeTextViewEvent:@"redraw:delete_line"
                        selector:@selector(redraw_delete_line:)
                           group:subscribeGroup];

    [self subscribeTextViewEvent:@"redraw:insert_line"
                        selector:@selector(redraw_insert_line:)
                           group:subscribeGroup];

    [self subscribeTextViewEvent:@"redraw:win_end"
                        selector:@selector(redraw_window_end:)
                           group:subscribeGroup];

    [self subscribeTextViewEvent:@"redraw:cursor"
                        selector:@selector(redraw_cursor:)
                           group:subscribeGroup];

    // request the screen after all events are subscribed
    dispatch_group_notify(subscribeGroup, dispatch_get_main_queue(), ^(){
        [self.client callMethod:@"vim_request_screen"
                         params:nil
                       callback:^(id error, id result) { }];
    });
}

- (void)redrawForegroundColor:(NSDictionary *)eventData
{
    [self.windowViewControllers enumerateKeysAndObjectsUsingBlock:
        ^(id key, NVMWindowViewController *controller, BOOL *stop) {
            [controller.textView redraw_foreground_color:eventData];
    }];
}

- (void)redrawBackgroundColor:(NSDictionary *)eventData
{
    [self.windowViewControllers enumerateKeysAndObjectsUsingBlock:
        ^(id key, NVMWindowViewController *controller, BOOL *stop) {
            [controller.textView redraw_background_color:eventData];
    }];
}

- (void)redrawTabs:(NSDictionary *)eventData
{
    // NSLog(@"redraw:tabs: %@", eventData);
}

- (void)redraw_layout:(NSDictionary *)event_data
{
    self.commandLineHeight.constant = self.cellSize.height;
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
            viewController.clientWindowController = self;
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
                                            direction:NVMSplitViewHorizontal
                                             cellSize:self.cellSize];
    } else if ([type isEqualToString:@"row"]) {
        return [[NVMSplitView alloc] initWithSubviews:subViews
                                            direction:NVMSplitViewVertical
                                             cellSize:self.cellSize];
    }
    NSLog(@"invalid redraw:layout node: %@", node);
    return nil;
}

- (NSSize)cellSize
{
    NSFont *font = [NSFont fontWithName:@"Menlo" size:13.0];
    NSDictionary *baseAttributes = @{NSFontAttributeName: font};
    float advance = [@"m" sizeWithAttributes:baseAttributes].width;
    NSLayoutManager *layoutManager = [NSLayoutManager new];
    float lineHeight = [layoutManager defaultLineHeightForFont:font];
    NSSize cellSize;
    cellSize.height = lineHeight;
    cellSize.width = advance;
    return cellSize;
}

@end
