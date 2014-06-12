//
//  NVMWindowViewController.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 12.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMWindowViewController.h"
#import "NVMTextView.h"


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

- (void)redraw_layout:(NSDictionary *)event_data
{
    NSNumber *height = event_data[@"height"];
    NSNumber *width = event_data[@"width"];
    NSSize cellSize = self.textView.cellSize;
    self.textViewHeight.constant = height.intValue * cellSize.height + 2;
    self.textViewWidth.constant = width.intValue * cellSize.width + 2;
}

@end
