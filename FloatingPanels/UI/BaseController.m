//
//  BaseController.m
//
//  Created by Torin Nguyen on 10/12/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import "BaseController.h"

@implementation BaseController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    _myAppDelegate = (FloatingPanelAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Setup Data storage (NSUserDefault)
    _dataStorage = [[DataStorage alloc] init];
    
    //Hide the standard navigation bar, we implemented our own
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

//Check Target settings
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Implementations

- (DataStorage*)getDataStorageInstance
{
    return _dataStorage;
}



#pragma mark - Facebook integration

- (Facebook*)getFacebookInstance
{
    return _myAppDelegate.facebook;
}

- (void)showFacebookAuthentication
{
    if ([self isFacebookSessionValid])
        return;
    
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email", 
                            @"user_photos",
                            @"user_videos",
                            @"publish_stream",
                            nil];
    [[self getFacebookInstance] authorize:permissions andDelegate:self];
    [permissions release];
    return;
}

- (BOOL)isFacebookSessionValid
{
    Facebook *facebook = [self getFacebookInstance];
    if ([[self getDataStorageInstance] getFBAccessToken] && [[self getDataStorageInstance] getFBExpirationDate])
    {
        facebook.accessToken = [[self getDataStorageInstance] getFBAccessToken];
        facebook.expirationDate = [[self getDataStorageInstance] getFBExpirationDate];
    }
    return [facebook isSessionValid];
}



#pragma mark - Facebook integration

// For 4.2+ support
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url
   sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[self getFacebookInstance] handleOpenURL:url]; 
}

- (void) fbDidLogin
{
    [[self getDataStorageInstance] setFBAccessToken:[self getFacebookInstance].accessToken];
    [[self getDataStorageInstance] setFBExpirationDate:[self getFacebookInstance].expirationDate];
    NSLog(@"Facebook did login");
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    NSLog(@"Facebook did NOT login");
}

- (void) fbDidLogout
{
    // Remove saved authorization information if it exists
    [[self getDataStorageInstance] clearFacebook];
    NSLog(@"Facebook did logout");
}


@end
