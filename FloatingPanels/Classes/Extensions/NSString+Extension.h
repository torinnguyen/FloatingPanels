//
//  NSString+Extension.h
//  Extend NSString with more convenient functions such as those in PHP or JavaScript
//
//  Created by Torin Nguyen on 31 Dec 2011
//

#pragma once
#import <Foundation/Foundation.h>


@interface NSString (NSStringExtension)

/**
 * returns YES if string contains a substring
 */
- (BOOL)contains:(NSString*)needle;

/**
 * returns YES if string starts with a substring
 */
- (BOOL)startsWith:(NSString*)needle;

/**
 * returns YES if string ends with a substring
 */
- (BOOL)endsWith:(NSString*)needle;

/**
 * returns number of occurrents of a substring
 */
- (NSUInteger)count:(NSString *)candidate;



/**
 * trim whitespace from ends of current string
 * returns an autorelease string
 */
- (NSString*)trim;

/**
 * replaces substrings within current string
 * returns an autorelease string
 */
- (NSString*)replace:(NSString*)candidate with:(NSString*)replacement;



/**
 * trim whitespace from ends of current string
 * returns an autorelease array
 */
- (NSArray*)split:(NSString*)splitter;

@end
