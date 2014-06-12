//
//  NVMTextView.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NVMTextView : NSTextView

@property (readonly) NSSize cellSize;

- (void)redraw_foreground_color:(NSDictionary *)event_data;
- (void)redraw_background_color:(NSDictionary *)event_data;
- (void)redraw_update_line:(NSDictionary *)event_data;
- (void)redraw_insert_line:(NSDictionary *)event_data;
- (void)redraw_delete_line:(NSDictionary *)event_data;
- (void)redraw_window_end:(NSDictionary *)event_data;
- (void)redraw_cursor:(NSDictionary *)event_data;

@end
