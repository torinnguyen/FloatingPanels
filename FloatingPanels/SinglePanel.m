//
//  SinglePanel.m
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import "SinglePanel.h"
#import "NSString+Extension.h"

@interface SinglePanel ()
    @property (nonatomic, retain) PanelData *data;
    @property (nonatomic, assign) UIView *originalSuperview;
    @property (nonatomic, assign) CGRect originalRect;
@end

@implementation SinglePanel

@synthesize delegate;
@synthesize btnMark, btnClose, btnVideo;
@synthesize btnThePanel, lblTitle;
@synthesize imgTheImage, webview, indicator, imgFrame;
@synthesize data;
@synthesize originalSuperview, originalRect;

#define kWebViewYoutubeHTML @"<html><head> \
<meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = wwwwww\"/></head> \
<body style=\"background:#FFFFFF;margin-top:0px;margin-left:0px\"> \
<object style=\"height: hhhhhhpx; width: wwwwwwpx\"> \
<param name=\"movie\" value=\"%@?version=3\"> \
<param name=\"allowFullScreen\" value=\"true\"> \
<param name=\"autoPlay\" value=\"true\"> \
<param name=\"allowScriptAccess\" value=\"always\"> \
<embed src=\"%@?version=3\"  \
type=\"application/x-shockwave-flash\" allowfullscreen=\"true\" \
allowScriptAccess=\"always\" width=\"wwwwww\" height=\"hhhhhh\"> \
</object></div></body></html>"

#define kWebViewClearHTML @"<html><head> \
<meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = wwwwww\"/></head> \
<body> \
</body></html>"

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setPanelData:self.data];
    
    self.btnClose.alpha = 0;
    self.btnVideo.alpha = 0;
    self.webview.alpha = 0;
    self.webview.delegate = self;
    self.indicator.alpha = 0;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.delegate = nil;
    self.lblTitle = nil;
    self.btnMark = nil;
    self.btnClose = nil;
    self.btnVideo = nil;
    self.btnThePanel = nil;
    self.webview = nil;
    self.imgTheImage = nil;
    
    self.data = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - UI Events

- (IBAction) onBtnMark: (id) sender
{
    if (self.delegate == nil)
        return;
    
    self.data.isMarked = !self.data.isMarked;
    self.btnMark.selected = self.data.isMarked;
    
    if ([self.delegate respondsToSelector:@selector(didClickOnBtnMark:withData:)])
        [delegate didClickOnBtnMark:self withData:self.data];
}

- (IBAction) onBtnClose: (id) sender
{
    if (self.delegate == nil)
        return;
    
    self.data.isActive = NO;
    self.imgTheImage.highlighted = self.data.isActive;
    
    if ([self.delegate respondsToSelector:@selector(didClickOnBtnClose:withData:)])
        [delegate didClickOnBtnClose:self withData:self.data];
}

- (IBAction) onBtnVideo: (id) sender
{
    //No delegate event for this button
    if (data.detailedURL == nil)
        return;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.7];
	[UIView setAnimationDelegate:self];
    self.webview.alpha = 1;
	[UIView commitAnimations];
    
    if ([data.detailedURL contains:@"youtube.com"])
    {
        //Load dummy YouTube video for demo purpose
        CGRect webFrame = self.webview.frame;
        NSString *htmlString = [NSString stringWithFormat: kWebViewYoutubeHTML, 
                                [self modifyYouTubeUrl:data.detailedURL],
                                [self modifyYouTubeUrl:data.detailedURL]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"wwwwww" withString:[NSString stringWithFormat:@"%d", (int)webFrame.size.width]];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"hhhhhh" withString:[NSString stringWithFormat:@"%d", (int)webFrame.size.height]];
        [self.webview stopLoading];
        [self.webview loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://www.youtube.com"]];
    }
    else if ([data.detailedURL startsWith:@"http://"] || [data.detailedURL startsWith:@"https://"])
    {
        NSLog(@"Opening a website: %@", data.detailedURL);
        [self.webview stopLoading];
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:data.detailedURL]]];
    }
    else
    {
        NSLog(@"Unable to handle this URL: %@", data.detailedURL);
    }
}

- (IBAction) onBtnThePanel: (id) sender
{
    if (self.delegate == nil)
        return;
    
    self.data.isActive = YES;
    [self setActive:YES];
    
    if ([self.delegate respondsToSelector:@selector(didClickOnThePanel:withData:)])
        [delegate didClickOnThePanel:self withData:self.data];
}



#pragma mark - Helper functions

- (void) setPanelData:(PanelData*)newData
{
    self.data = newData;
    
    if (newData.imageData != nil)
    {
        self.imgTheImage.image = data.imageData;
    }
    else if (newData.photoPath != nil)
    {
        if ([newData.photoPath startsWith:@"http://"] || [newData.photoPath startsWith:@"https://"])
            [self.imgTheImage loadImageFromPath:data.photoPath];
        else
            self.imgTheImage.image = [UIImage imageNamed:newData.photoPath];
    }
    
    //Title
    if (data.title == nil)      lblTitle.text = @"";
    else                        lblTitle.text = newData.title;
    
    //Mark
    self.btnMark.selected = newData.isMarked;
    
    //Active row
    [self setActive:newData.isActive];
}

- (void) setZoomInView:(UIView*)whichView
{
    //Save current geometry for going back later
    CGRect frame = self.view.frame;
    self.originalSuperview = self.view.superview;
    self.originalRect = self.view.frame;
        
    //Workout the global position of panel (convertRect doesn't work)
    if ([self.view.superview isKindOfClass:[UIScrollView class]])
    {
        UIScrollView *whichScrollView = (UIScrollView*)self.view.superview;
        int global_x = whichScrollView.frame.origin.x + frame.origin.x - whichScrollView.contentOffset.x;
        int global_y = whichScrollView.frame.origin.y + frame.origin.y - whichScrollView.contentOffset.y;
        frame.origin.x = global_x * whichScrollView.zoomScale;
        frame.origin.y = global_y;      // * whichScrollView.zoomScale;
        frame.size.width *= whichScrollView.zoomScale;
        frame.size.height *= whichScrollView.zoomScale;
    }
    
    //Detach it from current superview & add it to new view, on top
    UIView *selfView = self.view;
    [selfView retain];
    [selfView removeFromSuperview];
    [whichView addSubview:selfView];
    [whichView bringSubviewToFront:selfView];
    [selfView release];
    selfView.frame = frame;
    
    //Animate to bigger frame
    frame.size.width *= 1.5;
    frame.size.height *= 1.5;
    frame.origin.x = whichView.frame.size.height/2 - frame.size.width/2;        //width & height seem to be swapped here. Why??
    frame.origin.y = whichView.frame.size.width/2 - frame.size.height/2;        //width & height seem to be swapped here. Why??

	[UIView beginAnimations:nil context:nil];
    //[UIView setAnimationBeginsFromCurrentState:YES];      //this is wrong because current state has not been updated yet
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.7];
	[UIView setAnimationDelegate:self];
    selfView.frame = frame;
    self.btnMark.alpha = 0;
    self.btnClose.alpha = 1;
    self.btnVideo.alpha = (self.data.detailedURL == nil) ? 0 : 1;
    self.btnThePanel.alpha = 0;
    self.imgTheImage.alpha = 1;
    self.webview.alpha = 0;
	[UIView commitAnimations];
}

- (void) setNormalView
{
    if (self.originalSuperview == nil)
        return;
    if (![self.originalSuperview isKindOfClass:[UIScrollView class]])
        return;
    
    UIScrollView *superScrollView = (UIScrollView*)self.originalSuperview;
    
    UIView *selfView = self.view;
    CGRect frame = selfView.frame;
    
    //Convert global coordinates to scrollview coordinates
    int x = selfView.frame.origin.x - superScrollView.frame.origin.x + superScrollView.contentOffset.x;
    int y = selfView.frame.origin.y - superScrollView.frame.origin.y + superScrollView.contentOffset.y;
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.width /= superScrollView.zoomScale;
    frame.size.height /= superScrollView.zoomScale;
    
    //Detach it from current superview & add it to original scroll view
    [selfView retain];
    [selfView removeFromSuperview];
    [self.originalSuperview addSubview:selfView];
    [self.originalSuperview bringSubviewToFront:selfView];
    [selfView release];
    selfView.frame = frame;
    
    [UIView beginAnimations:nil context:nil];
    //[UIView setAnimationBeginsFromCurrentState:YES];      //this is wrong because current state has not been updated yet
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.8];
	[UIView setAnimationDelegate:self];
    selfView.frame = self.originalRect;
    self.btnMark.alpha = 1;
    self.btnClose.alpha = 0;
    self.btnVideo.alpha = 0;
    self.btnThePanel.alpha = 1;
    self.imgTheImage.alpha = 1;
    self.webview.alpha = 0;
	[UIView commitAnimations];  
    
    //Clear webview memory usage
    [self.webview stopLoading];
    [self.webview loadHTMLString:kWebViewClearHTML baseURL:[NSURL URLWithString:@"http://www.google.com"]];
}

- (void) setActive:(BOOL)active
{
    self.imgFrame.highlighted = active;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.8];
	[UIView setAnimationDelegate:self];
    self.imgTheImage.alpha = active ? 1.0 : 0.8;
	[UIView commitAnimations];
}

//
// Convert link for embedded player into chromeless player
//
- (NSString *) modifyYouTubeUrl: (NSString *) tyurl
{
	return [tyurl stringByReplacingOccurrencesOfString:@"embed" withString:@"v"];
}



#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
    self.indicator.alpha = 0;
	[UIView commitAnimations];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationDelegate:self];
    self.indicator.alpha = 1;
	[UIView commitAnimations];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
    self.indicator.alpha = 0;
	[UIView commitAnimations];
}

@end
