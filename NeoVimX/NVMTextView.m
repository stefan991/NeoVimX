//
//  NVMTextView.m
//  NeoVimX
//
//  Created by Stefan Hoffmann on 11.06.14.
//  Copyright (c) 2014 neovim. All rights reserved.
//

#import "NVMTextView.h"
#import "NSColor+NeoVimX.h"


@interface NVMTextView ()

@property (retain) NSDictionary *baseAttributes;
@property NSMutableDictionary *attributesCache;

@end


@implementation NVMTextView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void)initCommon
{
    // Disable line wrapping as it causes flicker while resizing.
    // The real line wrapping is handled by nvim.
    self.textContainer.containerSize = NSMakeSize(FLT_MAX, FLT_MAX);
    self.textContainer.widthTracksTextView = NO;

    // Remove the margin around the text inside the textview.
    self.textContainerInset = NSMakeSize(0, 0);
    self.textContainer.lineFragmentPadding = 0;

    self.string = @"";
    NSFont *font = [NSFont fontWithName:@"Menlo" size:13.0];
    self.baseAttributes = @{NSFontAttributeName: font};
    self.attributesCache = [NSMutableDictionary new];
}

- (NSColor *)foregroundColor
{
    return self.baseAttributes[NSForegroundColorAttributeName];
}

- (void)setForegroundColor:(NSColor *)color
{
    NSMutableDictionary *newbaseAttributes = [self.baseAttributes mutableCopy];
    newbaseAttributes[NSForegroundColorAttributeName] = color;
    self.baseAttributes = [newbaseAttributes copy];
}

- (void)redrawUpdateLine:(NSDictionary *)eventData
{
    NSNumber *row = eventData[@"row"];
    NSRange lineRange = [self getRangeForLine:row.intValue + 1];
    NSMutableString *updatedLine = [@"" mutableCopy];
    NSArray *sections = eventData[@"line"];
    for (NSDictionary *section in sections) {
        [updatedLine appendString:section[@"content"]];
    }
    [updatedLine appendString:@"\n"];
    [self.textStorage replaceCharactersInRange:lineRange
                                    withString:updatedLine];
    NSRange newRange = NSMakeRange(lineRange.location, updatedLine.length);
    // Remove Attributes
    [self.textStorage setAttributes:self.baseAttributes
                              range:newRange];

    NSDictionary *attributes = eventData[@"attributes"];
    for (NSString *attrName in attributes) {
        NSDictionary *textAttributes = [self getAttributesForName:attrName];
        for (id attrPosition in attributes[attrName]) {
            int startInt;
            int endInt;
            if ([attrPosition isKindOfClass:[NSNumber class]]) {
                startInt = ((NSNumber *)attrPosition).intValue;
                endInt = startInt + 1;
            } else {
                NSArray *attPositionArray = attrPosition;
                NSNumber *start = attPositionArray[0];
                NSNumber *end = attPositionArray[1];
                startInt = start.intValue;
                endInt = end.intValue;
            }
            NSRange attrRange =
            NSMakeRange(lineRange.location + startInt,
                        endInt - startInt);
            [self.textStorage setAttributes:textAttributes
                                      range:attrRange];
        }
    }

}

- (void)redrawInsertLine:(NSDictionary *)eventData
{
    NSNumber *row = eventData[@"row"];
    NSNumber *count = eventData[@"count"];
    for (int i = 0; i < count.intValue; i++) {
        NSRange lineRange = [self getRangeForLine:row.intValue + 1];
        NSAttributedString *attrString =
        [[NSAttributedString alloc] initWithString:@"\n"
                                        attributes:self.baseAttributes];
        [self.textStorage insertAttributedString:attrString
                                         atIndex:lineRange.location];
        [self setNeedsDisplay:YES];
    }
}

- (void)redrawDeleteLine:(NSDictionary *)eventData
{
    NSNumber *row = eventData[@"row"];
    NSNumber *count = eventData[@"count"];
    for (int i = 0; i < count.intValue; i++) {
        NSRange lineRange = [self getRangeForLine:row.intValue + 1];
        [self.textStorage replaceCharactersInRange:lineRange withString:@""];
    }
}

- (void)redrawWindowEnd:(NSDictionary *)eventData
{
    NSNumber *row = eventData[@"row"];
    NSNumber *endRow = eventData[@"endrow"];
    NSAssert(row.integerValue >= 0, @"row not positive");
    NSAssert(row.integerValue >= 0, @"endrow not positive");
    NSString *marker = eventData[@"marker"];
    // TODO(stefan991) handle fill
    for (int line = row.intValue; line < endRow.intValue; line++) {
        NSRange lineRange = [self getRangeForLine:line + 1];
        NSString *updatedLine = [NSString stringWithFormat:@"%@\n", marker];
        [self.textStorage replaceCharactersInRange:lineRange
                                        withString:updatedLine];
    }
    // delete everything after the end of the "window"
    NSRange firstLineAfterEnd = [self getRangeForLine:endRow.intValue + 1];
    NSRange afterEnd = NSMakeRange(firstLineAfterEnd.location,
                                   self.textStorage.length
                                        - firstLineAfterEnd.location);
    [self.textStorage deleteCharactersInRange:afterEnd];
}

- (void)redrawCursor:(NSDictionary *)eventData
{
    NSNumber *row = eventData[@"row"];
    NSNumber *col = eventData[@"col"];
    NSRange startOfLine = [self getRangeForLine:row.intValue + 1];
    NSRange range = NSMakeRange(startOfLine.location + col.intValue, 0);
    [self.window makeFirstResponder:self];
    [self setSelectedRange:range];
}

- (NSRange)getRangeForLine:(int)lineNumber
{
    NSString *string = self.textStorage.string;
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
        [self.textStorage appendAttributedString:
         [[NSAttributedString alloc] initWithString:@"\n"
                                         attributes:self.baseAttributes]];
        NSString *string = self.textStorage.string;
        range = [string lineRangeForRange:NSMakeRange(index, 0)];
        index = NSMaxRange(range);
    }

    return range;
}

- (NSDictionary *)getAttributesForName:(NSString *)name
{
    NSDictionary *attributes = self.attributesCache[name];
    if (attributes) {
        return attributes;
    }
    NSString *prefix = [name substringToIndex:2];
    if ([prefix isEqualToString:@"fg"]
        || [prefix isEqualToString:@"bg"]) {

        if (name.length < 10) {
            NSLog(@"Attribute name to short: %@", name);
            return [self.baseAttributes copy];
        }
        NSString *colorStr = [name substringWithRange:NSMakeRange(4, 6)];
        NSColor *color = [NSColor NVM_colorWithHexColorString:colorStr];
        if ([prefix isEqualToString:@"fg"]) {
            NSMutableDictionary *attributesMut =
                [self.baseAttributes mutableCopy];
            attributesMut[NSForegroundColorAttributeName] = color;
            self.attributesCache[name] = attributesMut;
            return [attributesMut copy];
        }
        if ([prefix isEqualToString:@"bg"]) {
            NSMutableDictionary *attributesMut =
                [self.baseAttributes mutableCopy];
            attributesMut[NSBackgroundColorAttributeName] = color;
            self.attributesCache[name] = attributesMut;
            return [attributesMut copy];
        }
    }

    if ([name isEqualToString:@"bold"]) {
        NSMutableDictionary *attributesMut = [self.baseAttributes mutableCopy];
        attributesMut[NSFontAttributeName] =
            [NSFont fontWithName:@"Menlo-Bold" size:13.0];
        return [attributesMut copy];
    }

    // TODO(stefan991): Handle bold and italic at the same time
    if ([name isEqualToString:@"italic"]) {
        NSMutableDictionary *attributesMut = [self.baseAttributes mutableCopy];
        attributesMut[NSFontAttributeName] =
            [NSFont fontWithName:@"Menlo-Italic" size:13.0];
        return [attributesMut copy];
    }

    if ([name isEqualToString:@"underline"]) {
        NSMutableDictionary *attributesMut = [self.baseAttributes mutableCopy];
        attributesMut[NSUnderlineStyleAttributeName] =
            @(NSUnderlineStyleSingle);
        return [attributesMut copy];
    }

    NSLog(@"unknown attribute: %@", name);

    return [self.baseAttributes copy];
}

@end
