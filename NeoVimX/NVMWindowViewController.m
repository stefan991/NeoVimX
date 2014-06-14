//
//  NVMWindowViewController.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMWindowViewController.h"
#import "NVMTextView.h"
#import "NVMClientWindowController.h"


@interface NVMWindowViewController ()

@end


@implementation NVMWindowViewController

- (id)init
{
    self = [super initWithNibName:@"NVMWindowView" bundle:nil];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    NVMTextView *textView =
        [[NVMTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    self.textView = textView;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:textView];
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
}

- (void)redraw_layout:(NSDictionary *)layoutNode
{
    NSNumber *height = layoutNode[@"height"];
    NSNumber *width = layoutNode[@"width"];
    NSSize cellSize = self.clientWindowController.cellSize;
    self.textViewHeight.constant = height.intValue * cellSize.height;
    self.textViewWidth.constant = ceil(width.doubleValue * cellSize.width);
}

@end
