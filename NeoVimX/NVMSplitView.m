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
                        cellSize:(NSSize)cellSize
{
    self = [self initWithFrame:NSMakeRect(0, 0, 100, 100)];
    if (self) {
        if (direction == NVMSplitViewVertical && subviews.count > 1) {
            // insert seperator views
            NSMutableArray *newSubviews = [NSMutableArray new];
            for (int i = 0; i < subviews.count - 1; i++) {
                [newSubviews addObject:subviews[i]];
                NSView *seperator =
                    [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
                [newSubviews addObject:seperator];
                NSLayoutConstraint *widthConstraint =
                    [NSLayoutConstraint constraintWithItem:seperator
                                                 attribute:NSLayoutAttributeWidth
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:nil
                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                multiplier:1.0
                                                  constant:ceil(cellSize.width)];
                [self addConstraint:widthConstraint];
            }
            [newSubviews addObject: subviews.lastObject];
            subviews = newSubviews;
        }
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
            // If the subviews are not equal in width/height, ensure that
            // the spacing to the superview is >=0 and try to set it to 0 with
            // a high prirority.
            format = horizontal ? @"H:|[view]-(>=0,0@900)-|"
                                : @"V:|[view]-(>=0,0@900)-|";
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
