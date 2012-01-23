//
//  main.m
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FloatingPanelAppDelegate.h"

int main(int argc, char *argv[])
{
    /* iOS SDK 4.3 */
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([FloatingPanelAppDelegate class]));
    [pool release];
    return retVal;
    
    /* iOS SDK 5.0
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([FloatingPanelAppDelegate class]));
    }
     */
}
