//
//  FloatingPanelAppDelegate.h
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class FloatingPanelViewController;

@interface FloatingPanelAppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>
{
    Facebook *facebook;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) FloatingPanelViewController *viewController;
@property (nonatomic, retain) Facebook *facebook;

@end
