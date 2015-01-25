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

- (void)handleUIUpdate:(NSString *)type
             arguments:(NSArray *)arguments;

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
        [self attachUI];
    }];
}

- (void)attachUI
{
    [self.client handleEvent:@"redraw" eventCallback:^(id error, id result) {
        NSLog(@"redraw handled");
        for (NSArray *update in result) {
            [self handleUIUpdate:update[0] arguments:update[1]];
        }
    }];

    [self.client callMethod:@"ui_attach"
                     params:@[@(80), @(24), @YES]
                   callback:^(id error, id result) {
        NSLog(@"attached");
        [self.client callMethod:@"ui_try_resize"
                         params:@[@(100), @(15)]
                       callback:^(id error, id result) { NSLog(@"resized"); }];

    }];
}

- (void)handleUIUpdate:(NSString *)type arguments:(NSArray *)arguments
{
    if ([type isEqualToString: @"update_fg"]) {
        return;
    }
    if ([type isEqualToString: @"update_bg"]) {
        return;
    }
    if ([type isEqualToString: @"cursor_on"]) {
        return;
    }
    if ([type isEqualToString: @"cursor_off"]) {
        return;
    }
    if ([type isEqualToString: @"highlight_set"]) {
        return;
    }
    if ([type isEqualToString: @"resize"]) {
        NSNumber *width = arguments[0];
        NSNumber *height = arguments[1];
        NSSize cellSize = self.cellSize;
        self.contentViewWidth.constant = ceil(width.doubleValue * cellSize.width);
        self.contentViewHeight.constant = height.intValue * cellSize.height;
        return;
    }

    NSLog(@"unknown update: %@", type);
    for (id argument in arguments) {
        NSLog(@"                %@", argument);
    }
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
