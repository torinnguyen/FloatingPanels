//
//  DataStorage.m
//
//  Created by Torin on 5/12/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import "DataStorage.h"


@implementation DataStorage

-(DataStorage*) init
{
    self = [super init];
    prefs = nil;
    if(self)
    {
        prefs = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void) resetAll
{
    if (prefs == nil)
        return;
    [self setRememberLogin:NO];
    [self setUserID:-1];
    [self setUserTypeID:-1];
    [self setUserNickName:@""];
    [self setUserPassword:@""];
}

- (NSString *) getUserNickName
{
    if (prefs == nil)
        return @"";
    return [prefs stringForKey:@"UserNickName"];
}

- (void) setUserNickName:(NSString *)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"UserNickName"];
    [prefs synchronize];
}


- (NSString *) getUserPassword
{
    if (prefs == nil)
        return @"";
    return [prefs stringForKey:@"UserPassword"];
}

- (void) setUserPassword:(NSString *)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"UserPassword"];
    [prefs synchronize];
}


- (NSString *) getUserEmail
{
    if (prefs == nil)
        return @"";
    return [prefs stringForKey:@"UserEmail"];
}

- (void) setUserEmail:(NSString *)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"UserEmail"];
    [prefs synchronize];
}


- (NSDate *) getLastLogin
{
    if (prefs == nil)
        return [NSDate date];
    return (NSDate *)[prefs objectForKey:@"LastLogin"];    
}

- (void) setLastLogin:(NSDate *)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"LastLogin"];
    [prefs synchronize];
}


- (int) getUserID
{
    if (prefs == nil)
        return -1;
    return [prefs integerForKey:@"UserID"];
}

- (void) setUserID:(int)newValue
{
    if (prefs == nil)
        return;
    [prefs setInteger:newValue forKey:@"UserID"];
    [prefs synchronize];
}


- (int) getUserTypeID
{
    if (prefs == nil)
        return -1;
    return [prefs integerForKey:@"UserTypeID"];
}

- (void) setUserTypeID:(int)newValue
{
    if (prefs == nil)
        return;
    [prefs setInteger:newValue forKey:@"UserTypeID"];
    [prefs synchronize];
}


- (BOOL) getRememberLogin
{
    if (prefs == nil)
        return NO;
    return [prefs boolForKey:@"RememberLogin"];    
}

- (void) setRememberLogin:(BOOL)newValue
{
    if (prefs == nil)
        return;
    [prefs setBool:newValue forKey:@"RememberLogin"];
    [prefs synchronize];
}


- (NSString *) getFBAccessToken
{
    if (prefs == nil)
        return nil;
    return [prefs objectForKey:@"FBAccessTokenKey"];
}

- (void) setFBAccessToken:(NSString*)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"FBAccessTokenKey"];
    [prefs synchronize];
}


- (NSDate *) getFBExpirationDate
{
    if (prefs == nil)
        return nil;
    return [prefs objectForKey:@"FBExpirationDateKey"];
}

- (void) setFBExpirationDate:(NSDate *)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"FBExpirationDateKey"];
    [prefs synchronize];
}

- (void) clearFacebook
{
    if (prefs == nil)
        return;
    if ([prefs objectForKey:@"FBAccessTokenKey"])
    {
        [prefs removeObjectForKey:@"FBAccessTokenKey"];
        [prefs removeObjectForKey:@"FBExpirationDateKey"];
        [prefs synchronize];
    }
}

- (NSString *) getTwitterToken
{
    if (prefs == nil)
        return nil;
    return [prefs objectForKey:@"TwitterAuth"];
}

- (void) setTwitterToken:(NSString*)newValue
{
    if (prefs == nil)
        return;
    [prefs setObject:newValue forKey:@"TwitterAuth"];
    [prefs synchronize];
}

@end
