//
//  NVMAppDelegate.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 03.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMAppDelegate.h"
#import "NVMClient.h"


@implementation NVMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.client = [NVMClient new];
	[self.client connectTo:@"/tmp/neovim"];

	[self.client discoverApi:^(id error, id result) {

		[self.client callMethod:@"vim_get_current_buffer"
						 params:@[]
					   callback:^(id error, id buffer) {

			[self.client callMethod:@"buffer_get_line"
							 params:@[buffer, @(1)]
						   callback:^(id error, id result) {

				NSLog(@"line 1 in current buffer: %@", result);
			}];
		}];
	}];
}

@end
