//
//  FloatingPanelViewController.m
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import "FloatingPanelViewController.h"
#import "NSString+Extension.h"

@interface FloatingPanelViewController ()
{
    NSTimer *animationTimer;
    int scrollViewIndex;
    int scrollViewIndexInteractive;
    BOOL isManualDragging;
    SinglePanel *activePanel;
    
    int retryCounter;
    NSTimer *timeoutTimer;
    BOOL receivedUserInfo;
    BOOL receivedUserPhoto;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void) onAnimationTimer;

@end

#define SLIGHT_ROTATION         NO
#define SCROLLING_SPEED         1
#define HORIZONTAL_VARIATION    YES
#define VERTICAL_VARIATION      YES
#define SCALE_ACTIVE_ROW        YES

@interface FloatingPanelViewController ()
{
    BOOL facebookSessionValid;
}
@end
@implementation FloatingPanelViewController

@synthesize imgDarkCover, btnFacebook;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Get the version number
    NSString *versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSLog(@"Version %@", versionStr);
    //lblVersion.text = versionStr;
    
    //Setup Facebook integration
    Facebook *facebook = [self getFacebookInstance];
    if ([[self getDataStorageInstance] getFBAccessToken] && [[self getDataStorageInstance] getFBExpirationDate])
    {
        facebook.accessToken = [[self getDataStorageInstance] getFBAccessToken];
        facebook.expirationDate = [[self getDataStorageInstance] getFBExpirationDate];
    }
    facebookSessionValid = [facebook isSessionValid];
    self.btnFacebook.alpha = facebookSessionValid ? 0 : 1;
    
    //Storage
    if (scrollViewPointers == nil)
        scrollViewPointers = [[NSMutableArray alloc] initWithCapacity:5];
    if (dataPointer == nil)
        dataPointer = [[NSMutableDictionary alloc] initWithCapacity:20];
    if (panelPointers == nil)
        panelPointers = [[NSMutableDictionary alloc] initWithCapacity:20];
       
    //Search for all ScrollView
    for (UIView *subview in self.view.subviews)
    {
        if (![subview isKindOfClass:[UIScrollView class]])
            continue;
        [scrollViewPointers addObject:subview];
    }
    NSLog(@"Number of rows: %d", [self numScrollView]);
    
    //UI flags
    scrollViewIndex = 0;
    isManualDragging = NO;
    activePanel = nil;
    [self setActiveScrollView: [scrollViewPointers objectAtIndex:0]];
    
    //Ops flags
    receivedUserInfo = NO;
    receivedUserPhoto = NO;
    
    //Inject dummy data for testing
    for (int i=1; i <= 9; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"%d.jpg", i];
        PanelData *data = [[PanelData alloc] init];
        data.tag = imageName;
        data.photoPath = imageName;
        data.title = imageName;
        data.detailedURL = @"http://www.youtube.com/watch?v=y2Hz8dhQw8Q";
        [dataPointer setObject:data forKey:data.tag];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    [panelPointers release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    retryCounter = 0;
    
    //Populate all panels UI from data array
    [self populateAllPanel];
    
    //Initialize animation timer
    [self startAnimation];
    
    //Request Facebook user info
    if (facebookSessionValid) {
        retryCounter = 0;
        [self requestFacebookUserInfo];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    
	[super viewWillDisappear:animated];  
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - UI Events

- (IBAction)onBtnFacebook:(id)sender
{
    //FadeIn Loading icon
    [self showBusyUI];
    
    [self showFacebookAuthentication];  
}



#pragma mark - UI Helpers

- (void) showBusyUI
{
    //FadeIn dark cover
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.imgDarkCover.alpha = 0.5f;
    [UIView commitAnimations];
}

- (void) hideBusyUI
{
    //FadeOut dark cover
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.imgDarkCover.alpha = 0.0f;
    [UIView commitAnimations];
}

- (void) onTimeout:(NSTimer *) theTimer
{
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    
    //Retry 2 times
    if (retryCounter < 3)
    {
        if (!receivedUserInfo)          [self requestFacebookUserInfo];
        else if (!receivedUserPhoto)    [self requestFacebookUserPhoto];
        return;
    }
    
    //Give up
    [self hideBusyUI];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Error connecting to Facebook. Please try again."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (int)random:(int)min max:(int)max
{
    return min + arc4random() % (max + 1 - min);
}



#pragma mark - ScrollView implementation

- (int)numScrollView
{
    return [scrollViewPointers count];
}

- (int)incrementScrollViewIndex
{
    int newValue = scrollViewIndex + 1;
    if (newValue >= [self numScrollView])
        newValue = 0;
    scrollViewIndex = newValue;
    return scrollViewIndex;
}

- (UIScrollView*)getScrollView:(int)index
{
    if (index < 0 || index >= [self numScrollView])
        return nil;
    return [scrollViewPointers objectAtIndex:index];
}

//
// Set scrollview's height = content height so that it doesn't scroll vertically
//
- (void)fixScrollViewHeight:(int)index
{
    UIScrollView *theScrollView = [self getScrollView:index];
    CGRect frame = theScrollView.frame;
    
    frame.size.height = theScrollView.contentSize.height;
    theScrollView.frame = frame;
}

- (void)scrollViewByOffSet:(int)index x:(int)x y:(int)y
{
    UIScrollView *theScrollView = [self getScrollView:index];
    CGRect frame = theScrollView.frame;
    CGPoint offset = theScrollView.contentOffset;
    
    int contentX = offset.x;
    int contentWidth = theScrollView.contentSize.width;
    
    //Check if it has reached the end
    if (contentX + x + frame.size.width >= contentWidth)
        return;
    
    offset.x += x;
    theScrollView.contentOffset = offset;
}

- (void)scrollViewByPercentage:(int)index x:(float)x y:(float)y
{
    UIScrollView *theScrollView = [self getScrollView:index];   
    int contentX = (int)( x * theScrollView.contentSize.width );
    int contentY = (int)( y * theScrollView.contentSize.height );
    theScrollView.contentOffset = CGPointMake(contentX,contentY);
}



#pragma mark - Helper functions

- (void) populateAllPanel
{
    NSEnumerator *enumerator = [dataPointer keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        PanelData *oneData = [dataPointer objectForKey:key];
        [self populatePanel:oneData panelIndex:scrollViewIndex];
        
        //Switch to another panel
        [self incrementScrollViewIndex];
    }
}

- (void)populatePanel:(PanelData*)data panelIndex:(int)index
{
    //Sanity check
    if (data == nil || data.tag == nil)
        return;
    
    //A panel was already populated for this tag before
    if ([panelPointers objectForKey:data.tag] != nil)
        return;

    //Init
    SinglePanel *singlePanel = [[SinglePanel alloc] initWithNibName:@"SinglePanel" bundle:[NSBundle mainBundle]];
    [singlePanel setPanelData:data];
    [singlePanel.view setAutoresizingMask:UIViewAutoresizingNone];
    singlePanel.delegate = self;
    
    //Which scrollview to add
    UIScrollView *theScrollView = [self getScrollView:index];
    BOOL isActive = (theScrollView == [self getScrollView:scrollViewIndexInteractive]);
    data.isActive = isActive;
    [singlePanel setActive:isActive];

    //Adjust position
    CGRect currentContentSize = [self getAllPanelSize:index];
    CGRect frame = singlePanel.view.frame;
    int horzVariation = [self random:frame.size.width/6 max:frame.size.width];
    int vertVariation = [self random:-20 max:20];
    if (!HORIZONTAL_VARIATION)
        horzVariation = frame.size.width / 2;
    if (!VERTICAL_VARIATION)
        vertVariation = 0;
        
    frame.origin.x = currentContentSize.size.width + horzVariation;
    frame.origin.y = vertVariation;
    singlePanel.view.frame = frame;
    
    //Add to scrollview
    [theScrollView addSubview:singlePanel.view];
    
    //Slight rotation
    if (SLIGHT_ROTATION)
    {
        int rotation = -20 + arc4random() % (30 + 20);
        float rad_rotation = rotation / 1800.0f * M_PI;
        [singlePanel.view setTransform:CGAffineTransformMakeRotation( rad_rotation )];
    }
    
    //Store a pointer of it
    [panelPointers setObject:singlePanel forKey:data.tag];
    
    //Update scrollView contentSize & frame
    theScrollView.contentSize = [self getAllPanelSize:index].size;   
    [self fixScrollViewHeight:index];
    
    //Fade in
    singlePanel.view.alpha = 0;
    float duration = [self random:6 max:20] / 10.0f;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationDelegate:self];
    singlePanel.view.alpha = 1;
    [UIView commitAnimations];
}

- (BOOL)isPanelVisible:(PanelData*)data
{
    //Sanity check
    if (data == nil || data.tag == nil)
        return NO;
    if ([panelPointers objectForKey:data.tag] == nil)
        return NO;

    SinglePanel *singlePanel = [panelPointers objectForKey:data.tag];
    
    CGRect frame = singlePanel.view.frame;
    if (frame.origin.x > self.view.frame.size.width || frame.origin.y > self.view.frame.size.height)
        return NO;
    if (frame.origin.x+frame.size.width < 0 || frame.origin.y+frame.size.height < 0)
        return NO;
    
    return YES;
}

- (CGRect)getAllPanelSize:(int)index
{
    if (index < 0 && index > 1)
        return self.view.frame;
    
    UIScrollView *theScrollView = [self getScrollView:index];
    
    CGRect finalFrame = CGRectMake(1024,768,0,0);
       
    for (UIView *subview in theScrollView.subviews)
    {
        CGRect frame = subview.frame;
        
        if (finalFrame.origin.x > frame.origin.x)
            finalFrame.origin.x = frame.origin.x;
        if (finalFrame.origin.y > frame.origin.y)
            finalFrame.origin.y = frame.origin.y;

        if (finalFrame.size.width < frame.origin.x + frame.size.width)
            finalFrame.size.width = frame.origin.x + frame.size.width;
        if (finalFrame.size.height < frame.origin.y + frame.size.height)
            finalFrame.size.height = frame.origin.y + frame.size.height;
    }
    return finalFrame;
}

- (void)refreshAllPanel
{
    //Active scrollview
    UIScrollView *activeScrollView = [self getScrollView:scrollViewIndexInteractive];
    
    NSEnumerator *enumerator = [dataPointer keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        PanelData *oneData = [dataPointer objectForKey:key];
        SinglePanel *panel = [panelPointers objectForKey:oneData.tag];
        if (panel == nil)
            continue;
        if (![panel.view.superview isKindOfClass:[UIScrollView class]])
            continue;
        
        BOOL isActive = (panel.view.superview == activeScrollView);
        oneData.isActive = isActive;       
        [panel setPanelData:oneData];
        
        //[panel setActive:isActive];
    }
}

- (void)setActiveScrollView:(UIScrollView*)whichScrollView
{
    for (int i=0; i<[self numScrollView]; i++)
        if ([self getScrollView:i] == whichScrollView)
            scrollViewIndexInteractive = i;
    
    [self.view bringSubviewToFront:whichScrollView];
    
    //Safety precaution
    if (activePanel != nil) {
        [self.view bringSubviewToFront:imgDarkCover];
        [self.view bringSubviewToFront:activePanel.view];
    }
    
    //Active scrollview is slightly larger than the rest
    if (SCALE_ACTIVE_ROW)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.7];
        [UIView setAnimationDelegate:self];
        for (int i=0; i<[self numScrollView]; i++)
        {
            UIScrollView *scrollview = [self getScrollView:i];
            CGPoint contentOffset = scrollview.contentOffset;
            
            if (i == scrollViewIndexInteractive)
                [[self getScrollView:i] setZoomScale:1.0];
            else
                [[self getScrollView:i] setZoomScale:0.8];
            
            //New scrollview size
            CGRect frame = scrollview.frame;
            frame.size.height = scrollview.contentSize.height;
            scrollview.frame = frame;
            
            //For some reasons, scrollview reset its contentSize & contentOffset while zooming
            //So we need to reassign the previous value before zoom
            
            //Update scrollView contentSize & frame
            scrollview.contentSize = [self getAllPanelSize:i].size;   
            [self fixScrollViewHeight:i];
            scrollview.contentOffset = contentOffset;        
        }
        [UIView commitAnimations];
    }
    
    //Refresh child panels
    NSEnumerator *enumerator = [dataPointer keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        PanelData *oneData = [dataPointer objectForKey:key];
        SinglePanel *panel = [panelPointers objectForKey:oneData.tag];
        if (panel == nil)
            continue;
        if (![panel.view.superview isKindOfClass:[UIScrollView class]])
            continue;
        
        BOOL isActive = (panel.view.superview == whichScrollView);
        oneData.isActive = isActive;       
        [panel setActive:isActive];
    }
}

- (void) deleteAllPanel
{   
    //Detach all panels from scrollviews
    NSEnumerator *enumerator = [panelPointers keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        SinglePanel *panel = [panelPointers objectForKey:key];
        if (panel == nil)
            continue;
        
        [panel.view removeFromSuperview];
    }
    [panelPointers removeAllObjects];
    [dataPointer removeAllObjects];
    
    if (activePanel != nil)
        [activePanel.view removeFromSuperview];
    activePanel = nil;
}



#pragma mark - ScrollViewDeledate

- (void)scrollViewDidScroll:(UIScrollView *)whichScrollView
{
    float percentageX = (float) whichScrollView.contentOffset.x / whichScrollView.contentSize.width;
    float percentageY = (float) whichScrollView.contentOffset.y / whichScrollView.contentSize.height;
    percentageY = 0;

    if (whichScrollView != [self getScrollView:scrollViewIndexInteractive])
        return;

    //Synchronize scrolling the other scrollviews
    for (int i=0; i<[self numScrollView]; i++)
        if ([self getScrollView:i] != whichScrollView)
            [self scrollViewByPercentage:i x:percentageX y:percentageY];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)whichScrollView
{
    [self setActiveScrollView:whichScrollView];
    
    [self stopAnimation];
    isManualDragging = YES;
        
    NSLog(@"Active row: %d", scrollViewIndexInteractive);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)whichScrollView willDecelerate:(BOOL)decelerate
{
    NSLog(@"willDecelerate %@", decelerate ? @"YES" : @"NO");
    if (decelerate)
        return;
    isManualDragging = NO;
    [self startAnimation];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)whichScrollView
{
    isManualDragging = NO;
    [self startAnimation];
}

/*
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)whichSCrollView
{
    //on iOS 5.0, we cannot return the scrollView itself
    return whichSCrollView;
}
 */


#pragma mark - Animation

- (void) startAnimation
{
    if (animationTimer != nil)
        [animationTimer invalidate];
    animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.025 
                                                       target:self 
                                                     selector:@selector(onAnimationTimer) 
                                                     userInfo:nil 
                                                      repeats:TRUE] retain];
}

- (void) stopAnimation
{
    if (animationTimer == nil)
        return;
    [animationTimer invalidate];
    animationTimer = nil;
}

- (void) onAnimationTimer
{
    [self scrollViewByOffSet:scrollViewIndexInteractive x:SCROLLING_SPEED y:0];
}



#pragma mark - SinglePanelDelegate

- (void) didClickOnBtnMark:(SinglePanel *)whichPanel withData:(PanelData *)data
{
    NSLog(@"A mark button (within panel) was clicked: %@", data.tag);
    [dataPointer setObject:data forKey:data.tag];
}

- (void) didClickOnBtnClose:(SinglePanel *)whichPanel withData:(PanelData *)data
{
    NSLog(@"A close button (within panel) was clicked: %@", data.tag);
    [dataPointer setObject:data forKey:data.tag];
    
    [self startAnimation];
    
    if (activePanel == nil)
        return;
    [activePanel setNormalView];
    activePanel = nil;
    
    //Hide dark cover
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.7];
    [UIView setAnimationDelegate:self];
    imgDarkCover.alpha = 0;
    [UIView commitAnimations];
}

- (void) didClickOnThePanel:(SinglePanel *)whichPanel withData:(PanelData *)data
{
    UIView *parent = whichPanel.view.superview;
    if (![parent isKindOfClass:[UIScrollView class]])
        return;
    
    UIScrollView *whichScrollView = (UIScrollView*)parent;
    [self.view bringSubviewToFront:whichScrollView];   
    
    //Simply activate the scrollview on first press
    if (whichScrollView != [self getScrollView:scrollViewIndexInteractive]) {
        [self setActiveScrollView:whichScrollView];
        return;
    }

    NSLog(@"A panel was clicked: %@", data.tag);
    [dataPointer setObject:data forKey:data.tag];
    [self refreshAllPanel];
    
    //Scroll to selected item (bad UX)
    /*
    CGRect frame = whichPanel.view.frame;
    int centerX = frame.origin.x + frame.size.width/2;
    int contentX = centerX - whichScrollView.frame.size.width/2;
    int contentY = whichScrollView.contentOffset.y;
    [whichScrollView setContentOffset:CGPointMake(contentX, contentY) animated:YES];
     */
    
    //Activate large view of SinglePanel
    activePanel = whichPanel;
    [whichPanel setZoomInView:self.view];
    
    [self.view bringSubviewToFront:imgDarkCover];
    [self.view bringSubviewToFront:activePanel.view];
    
    //Show dark cover
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.7];
    [UIView setAnimationDelegate:self];
    imgDarkCover.alpha = 1.0;
    [UIView commitAnimations];
}


#pragma mark - Facebook integration

- (void) fbDidLogin
{
    [super fbDidLogin];
    
    retryCounter = 0;
    [self requestFacebookUserInfo];
    
    self.btnFacebook.alpha = 0;
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    [super fbDidNotLogin:cancelled];
    [self hideBusyUI];
}

//
// Get information about the currently logged in user
//
- (void) requestFacebookUserInfo
{
    retryCounter++;
    
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:25.0
                                                    target:self 
                                                  selector:@selector(onTimeout:) 
                                                  userInfo:nil 
                                                   repeats:NO];
    
    NSLog(@"Requesting Facebook user info");
    Facebook *facebook = [self getFacebookInstance];
    [facebook requestWithGraphPath:@"me" andDelegate:self];   
}

//
// Get user's photo stream
//
- (void) requestFacebookUserPhoto
{
    retryCounter++;
    
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:25.0
                                                    target:self 
                                                  selector:@selector(onTimeout:) 
                                                  userInfo:nil 
                                                   repeats:NO];
    
    NSLog(@"Requesting Facebook user photos");
    Facebook *facebook = [self getFacebookInstance];
    [facebook requestWithGraphPath:@"me/photos" andDelegate:self];   
}

- (void) parseFacebookPhotoArray:(NSArray*)dataArray
{
    if (dataArray == nil || [dataArray count] <= 0)
        return;
    
    for (int i=0; i<[dataArray count]; i++)
    {
        if ([dataArray objectAtIndex:i] == nil || ![[dataArray objectAtIndex:i] isKindOfClass:[NSDictionary class]])
            continue;
        NSDictionary *photoDict = [dataArray objectAtIndex:i];
        
        PanelData *data = [[PanelData alloc] init];
        data.tag = [photoDict objectForKey:@"id"];
        data.title = [photoDict objectForKey:@"name"];
        data.photoPath = [photoDict objectForKey:@"source"];
        data.numLikes = [[[photoDict objectForKey:@"likes"] objectForKey:@"data"] count];
        data.detailedURL = [photoDict objectForKey:@"link"];
        
        if (data.title == nil)
            data.title = [NSString stringWithFormat:@"From %@ - %@", [[photoDict objectForKey:@"from"] objectForKey:@"name"]
                                                                      , [photoDict objectForKey:@"created_time"] ];
        [dataPointer setObject:data forKey:data.tag];
    }
}



#pragma mark - Facebook request delegate

//
// Called just before response is received
//
- (void) request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"Receiving reponse: start (%@)", request.url);
}

- (void) request:(FBRequest *)request didFailWithError:(NSError *)error;
{
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    retryCounter = 999;
    
    [self hideBusyUI];
	NSLog(@"FBRequest reponse: failed (%@)", request.url);
}

- (void) request:(FBRequest *)request didLoad:(id)result
{
    if (timeoutTimer != nil) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    retryCounter = 999;
    
	NSLog(@"FBRequest reponse: end (%@)", request.url);
    if (![result isKindOfClass:[NSDictionary class]])
        return;
    NSDictionary *dict = (NSDictionary*)result;
    
    //Receiving user info
    if ([request.url endsWith:@"/me"])
    {
        receivedUserInfo = YES;
        
        NSString * UserID = [dict objectForKey:@"id"];
        NSString * UserName = [dict objectForKey:@"name"];
        NSString * UserNickName = [dict objectForKey:@"username"];
        NSString * gender = [dict objectForKey:@"gender"];
        NSString * Email = [dict objectForKey:@"email"];
        
        //Some users does not have a username/alias
        if (UserNickName == nil || [UserNickName length] < 1) {
            UserNickName = [NSString stringWithString:UserName];
            NSLog(@"Facebook UserID:%@, UserName:%@, UserNickName:(copied), Gender:%@, Email:%@", UserID, UserName, gender, Email);
        }
        else {
            NSLog(@"Facebook UserID:%@, UserName:%@, UserNickName:%@, Gender:%@, Email:%@", UserID, UserName, UserNickName, gender, Email);
        }
        
        self.btnFacebook.alpha = 0;
        [self hideBusyUI];
        
        //Continue to request for Facebook photos
        retryCounter = 0;
        receivedUserPhoto = NO;
        [self requestFacebookUserPhoto];
        return;
    }
    
    //Receiving user photos
    if ([request.url endsWith:@"/me/photos"])
    {
        receivedUserPhoto = YES;
        
        if ([dict objectForKey:@"data"] == nil || ![[dict objectForKey:@"data"] isKindOfClass:[NSArray class]]) {
            NSLog(@"Receiving Facebook photos - ERROR - wrong format");
            return;
        }
        NSArray *dataArray = (NSArray*)[dict objectForKey:@"data"];
        NSLog(@"Receiving Facebook photos: %d", [dataArray count]);
        [self deleteAllPanel];
        [self parseFacebookPhotoArray:dataArray];
        [self populateAllPanel];
        return;
    }
    
    NSLog(@"Unexpected response");
    NSLog(@"%@", dict);
}


@end
