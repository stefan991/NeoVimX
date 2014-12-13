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
#import "NSColor+NeoVimX.h"


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

    NVMTextView *textView = [NVMTextView new];
    [self.contentView addSubview:textView];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(textView);
    [self.contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    [self.contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];

    self.client = [NVMClient new];
    [self.client connectTo:@"/tmp/nvim"];

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
    [self.client subscribeRedrawEvent:eventName
                        eventCallback:eventCallback
                    completionHandler:^(id error, id result) {
        dispatch_group_leave(group);
    }];
}


- (void)subscribeRedrawEvents
{
    dispatch_group_t subscribeGroup = dispatch_group_create();

    // request the screen after all events are subscribed
    dispatch_group_notify(subscribeGroup, dispatch_get_main_queue(), ^(){

    });
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
