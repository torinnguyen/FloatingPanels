//
//  DatStorage.h
//
//  Created by Torin on 5/12/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataStorage : NSObject
{
    NSUserDefaults *prefs;
}

- (void) resetAll;

- (NSString *) getUserNickName;
- (void) setUserNickName:(NSString *)newValue;

- (NSString *) getUserPassword;
- (void) setUserPassword:(NSString *)newValue;

- (NSString *) getUserEmail;
- (void) setUserEmail:(NSString *)newValue;

- (NSDate *) getLastLogin;
- (void) setLastLogin:(NSDate *)newValue;

- (int) getUserID;
- (void) setUserID:(int)newValue;

- (int) getUserTypeID;
- (void) setUserTypeID:(int)newValue;

- (BOOL) getRememberLogin;
- (void) setRememberLogin:(BOOL)newValue;

- (NSString *) getFBAccessToken;
- (void) setFBAccessToken:(NSString*)newValue;

- (NSDate *) getFBExpirationDate;
- (void) setFBExpirationDate:(NSDate *)newValue;

- (void) clearFacebook;

- (NSString *) getTwitterToken;
- (void) setTwitterToken:(NSString*)newValue;

@end
