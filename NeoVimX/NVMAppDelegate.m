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

	NSFont *font = [NSFont fontWithName:@"Menlo" size:13.0];
	self.baseAttributes = @{NSFontAttributeName: font};
	[self.textView.textStorage setAttributes:self.baseAttributes
									   range:NSMakeRange(0, self.textView.textStorage.length)];

	self.client = [NVMClient new];
	[self.client connectTo:@"/tmp/neovim"];

	[self.client discoverApi:^(id error, id result) {

		[self.client subscribeEvent:@"redraw:update_line" callback:^(id error, id result) {
			// NSLog(@"redraw:update_line: %@", result);
			NSNumber *row = result[@"row"];
			NSRange lineRange = [self getRangeForLine:row.intValue + 1];
			NSMutableString *updatedLine = [@"" mutableCopy];
			NSArray *sections = result[@"line"];
			for (NSDictionary *section in sections) {
				[updatedLine appendString:section[@"content"]];
			}
			[updatedLine appendString:@"\n"];
			[self.textView.textStorage replaceCharactersInRange:lineRange withString:updatedLine];
		}];

		[self.client subscribeEvent:@"redraw:insert_line" callback:^(id error, id result) {
			// NSLog(@"redraw:insert_line: %@", result);
			NSNumber *row = result[@"row"];
			NSNumber *count = result[@"count"];
			for (int i = 0; i < count.intValue; i++) {
				NSRange lineRange = [self getRangeForLine:row.intValue + 1];
				NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:@"\n"];
				[self.textView.textStorage insertAttributedString:attrString atIndex:lineRange.location];
				[self.textView setNeedsDisplay:YES];
			}
		}];

		[self.client subscribeEvent:@"redraw:delete_line" callback:^(id error, id result) {
			// NSLog(@"redraw:delete_line: %@", result);
			NSNumber *row = result[@"row"];
			NSNumber *count = result[@"count"];
			for (int i = 0; i < count.intValue; i++) {
				NSRange lineRange = [self getRangeForLine:row.intValue + 1];
				[self.textView.textStorage replaceCharactersInRange:lineRange withString:@""];
			}
		}];

		[self.client subscribeEvent:@"redraw:win_end" callback:^(id error, id result) {
			// NSLog(@"redraw:win_end: %@", result);
			NSNumber *row = result[@"row"];
			NSNumber *endRow = result[@"endrow"];
			NSString *marker = result[@"marker"];
			// TODO(stefan991) handle fill
			for (int line = row.intValue; line < endRow.intValue; line++) {
				NSRange lineRange = [self getRangeForLine:line + 1];
				NSString *updatedLine = [NSString stringWithFormat:@"%@\n", marker];
				[self.textView.textStorage replaceCharactersInRange:lineRange withString:updatedLine];
			}
			// delete everything after the end of the "window"
			NSRange firstLineAfterEnd = [self getRangeForLine:endRow.intValue + 1];
			NSRange afterEnd = NSMakeRange(firstLineAfterEnd.location,
										   self.textView.textStorage.length - firstLineAfterEnd.location);
			[self.textView.textStorage deleteCharactersInRange:afterEnd];
		}];

		/*
		[self.client subscribeEvent:@"redraw:cursor" callback:^(id error, id result) {
			NSLog(@"redraw:cursor: %@", result);
			NSNumber *row = result[@"row"];
			NSNumber *col = result[@"col"];
			NSRange startOfLine = [self getRangeForLine:row.intValue + 1];
			NSRange range = NSMakeRange(startOfLine.location + col.intValue, 0);
			// [self.textView setSelectedRange:range];
		}];
		 */

		[self.client subscribeEvent:@"redraw:layout" callback:^(id error, id result) {
			NSLog(@"redraw:layout: %@", result);
		}];

		[self.client subscribeEvent:@"redraw:tabs" callback:^(id error, id result) {
			NSLog(@"redraw:tabs: %@", result);
		}];

		[self.client callMethod:@"vim_request_screen"
						 params:nil
					   callback:^(id error, id result) {
			NSLog(@"command callback vim_request_screen: %@", result);
		}];
	}];

}

- (NSRange)getRangeForLine:(int)lineNumber
{
	NSString *string = self.textView.textStorage.string;
	NSRange range;
	NSUInteger currentLineNumber = 0;
	NSUInteger index = 0;
	NSUInteger stringLength = string.length;

	while (index < stringLength) {
		if (currentLineNumber == lineNumber) {
			return range;
		}
		range = [string lineRangeForRange:NSMakeRange(index, 0)];
		index = NSMaxRange(range);
		currentLineNumber++;
	}

	// end of textstorage
	if (lineNumber != currentLineNumber) {
		// insert line
		[self.textView.textStorage appendAttributedString:
			[[NSAttributedString alloc] initWithString:@"\n"
											attributes:self.baseAttributes]];
		NSString *string = self.textView.textStorage.string;
		range = [string lineRangeForRange:NSMakeRange(index, 0)];
		index = NSMaxRange(range);
	}

	return range;
}

@end
