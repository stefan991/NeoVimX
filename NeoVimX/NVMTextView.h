//
//  NVMTextView.h
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NVMTextView : NSTextView

- (void)redrawForegroundColor:(NSDictionary *)eventData;
- (void)redrawBackgroundColor:(NSDictionary *)eventData;
- (void)redrawUpdateLine:(NSDictionary *)eventData;
- (void)redrawInsertLine:(NSDictionary *)eventData;
- (void)redrawDeleteLine:(NSDictionary *)eventData;
- (void)redrawWindowEnd:(NSDictionary *)eventData;
- (void)redrawCursor:(NSDictionary *)eventData;

@end
