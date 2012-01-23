//
//  BaseController.h
//
//  Created by Torin Nguyen on 10/12/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FloatingPanelAppDelegate.h"
#import "DataStorage.h"
#import "AppConfig.h"
#import "FBConnect.h"

@interface BaseController : UIViewController <FBSessionDelegate>
{
    //Store user's settings
    DataStorage *_dataStorage;
    
    //Reference to app delegate, mainly for Facebook integration
    FloatingPanelAppDelegate *_myAppDelegate;
}

- (DataStorage*)getDataStorageInstance;

- (Facebook*)getFacebookInstance;
- (void)showFacebookAuthentication;
- (BOOL)isFacebookSessionValid;

@end
