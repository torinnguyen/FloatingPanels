//
//  NSString+Extension.m
//  Extend NSString with more convenient functions such as those in PHP or JavaScript
//
//  Created by Torin Nguyen on 31 Dec 2011
//

#import "NSString+Extension.h"


@implementation NSString (NSStringExtension)

#pragma mark - Test functions

- (BOOL)contains:(NSString*)needle
{
    if (needle == nil || [needle length] <= 0)
        return NO;
	NSRange range = [self rangeOfString:needle options:NSCaseInsensitiveSearch];
    if (range.length <= 0 || range.length != [needle length])
        return NO;
    return YES;
}

- (BOOL)startsWith:(NSString*)needle
{
    if (needle == nil || [needle length] <= 0)
        return NO;
    NSRange range = [self rangeOfString:needle options:NSCaseInsensitiveSearch];
    if (range.length <= 0 || range.length != [needle length])
        return NO;
    return (range.location == 0 && range.length == [needle length]) ? YES : NO;
}

- (BOOL)endsWith:(NSString*)needle
{
    if (needle == nil || [needle length] <= 0)
        return NO;
    NSRange range = [self rangeOfString:needle options:NSCaseInsensitiveSearch];
    if (range.length <= 0 || range.length != [needle length])
        return NO;
    return ((range.location+range.length) == [self length]) ? YES : NO;
}

- (NSUInteger)count:(NSString *)candidate
{
    NSUInteger count = 0;
    NSUInteger length = [self length];
    NSRange range = NSMakeRange(0, length); 
    while(range.location != NSNotFound)
    {
        range = [self rangeOfString:candidate options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++; 
        }
    }
    return count;
}



#pragma mark - Replacement functions

- (NSString*)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*)replace:(NSString*)candidate with:(NSString*)replacement
{
    NSMutableString *new_string = [NSMutableString stringWithString:self];
    NSRange wholeString = NSMakeRange(0, [self length]);
    
    [new_string replaceOccurrencesOfString: candidate
                             withString: replacement
                                options: 0
                                  range: wholeString];
    
    return [NSString stringWithString: new_string];
}



#pragma mark - Array functions

- (NSArray*)split:(NSString*)splitter
{
    return [self componentsSeparatedByString: splitter];
}

@end
