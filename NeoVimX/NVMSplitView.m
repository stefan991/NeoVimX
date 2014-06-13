//
//  NVMSplitView.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMSplitView.h"

@implementation NVMSplitView

- (instancetype)initWithSubviews:(NSArray *)subviews
                       direction:(NVMSplitViewDirection)direction
{
    self = [self initWithFrame:NSMakeRect(0, 0, 100, 100)];
    if (self) {
        NSView *lastView;
        NSDictionary *views;
        BOOL horizontal = (direction == NVMSplitViewHorizontal);
        NSString *format;
        for (NSView *view in subviews) {
            [view removeFromSuperview];
            [self addSubview:view];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            if (lastView) {
                views = NSDictionaryOfVariableBindings(lastView, view);
                format = horizontal ? @"V:[lastView][view]"
                                    : @"H:[lastView][view]";
                [self addConstraints:
                    [NSLayoutConstraint constraintsWithVisualFormat:format
                                                            options:0
                                                            metrics:nil
                                                              views:views]];

            } else {  // first view
                views = NSDictionaryOfVariableBindings(view);
                format = horizontal ? @"V:|[view]"
                                    : @"H:|[view]";
                [self addConstraints:
                    [NSLayoutConstraint constraintsWithVisualFormat:format
                                                            options:0
                                                            metrics:nil
                                                              views:views]];
            }
            views = NSDictionaryOfVariableBindings(view);
            format = horizontal ? @"H:|[view]|"
                                : @"V:|[view]|";
            [self addConstraints:
                [NSLayoutConstraint constraintsWithVisualFormat:format
                                                        options:0
                                                        metrics:nil
                                                          views:views]];
            [self addSubview:view];
            lastView = view;
        }
        if (lastView) {
            views = NSDictionaryOfVariableBindings(lastView);
            format = horizontal ? @"V:[lastView]|"
                                : @"H:[lastView]|";
            [self addConstraints:
                [NSLayoutConstraint constraintsWithVisualFormat:format
                                                        options:0
                                                        metrics:nil
                                                          views:views]];
        }
    }
    return self;
}

@end
