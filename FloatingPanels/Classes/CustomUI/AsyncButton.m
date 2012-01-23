//
//  AsyncButton.m
//  This is a class to replace UIButton that loads image asynchronously
//
//  Created by Torin on 4/27/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import "AsyncButton.h"
#import "ImageCache.h"

@implementation AsyncButton

@synthesize delegate;
@synthesize path;
@synthesize enableCache;

- (AsyncButton *) init
{
    self = [super init];
    if (self)
    {
        connection = nil;
        self.enableCache = YES;
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {        
        connection = nil;
        self.enableCache = YES;
        self.clipsToBounds = YES;
//        self.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"AsyncButton dealloc");
    self.delegate = nil;
    self.path = nil;
    
    //Already release
    /*
    if (connection != nil)
        [connection cancel];
    [connection release];
    connection = nil;
    
    if (connectionBackground != nil)
        [connectionBackground cancel];
    [connectionBackground release];
    connectionBackground = nil;
    
    [data release];
    data = nil;
     */
    
    [loadedImage release];
    [super dealloc];
}


//
// Load foreground image asynchronously with default FadeIn animation
//
- (BOOL) loadImageFromPath:(NSString*)imagePath
{   
    return [self loadImageFromPath:imagePath useFadeInAnimation:YES];
}


//
// Load foreground image asynchronously with FadeIn animation option
//
- (BOOL) loadImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable
{
    if (imagePath == nil)
        return NO;
    
    self.path = imagePath;
    enableFadeIn = isEnable;
    
    //Load from cache if available
    if (self.enableCache && [[ImageCache sharedImageCache] hasImageWithKey:self.path])
    {
        [loadedImage release];
        loadedImage = [[[ImageCache sharedImageCache] imageForKey:self.path] retain];
        [self setImage:loadedImage];
        
        //Request to redraw
        [self setNeedsLayout];
        
        [self connectionDidFinishLoading:nil];
        return YES;
    }
    
    //Busy loading
    if (connection != nil)
        return NO;
    
    //Normal loading from network
    NSURL *url = [NSURL URLWithString:self.path];
    NSURLRequest* request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:20.0];
    [connection release];
    connection = nil;
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    connectionBackground = nil;
    return YES;
}


//
// Load background image asynchronously with default FadeIn animation
//
- (BOOL) loadBackgroundImageFromPath:(NSString*)imagePath
{   
    return [self loadBackgroundImageFromPath:imagePath useFadeInAnimation:YES];
}


//
// Load background image asynchronously with FadeIn animation option
//
- (BOOL) loadBackgroundImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable
{
    if (imagePath == nil)
        return NO;
    
    self.path = imagePath;
    enableFadeIn = isEnable;
    
    //Load from cache if available
    if ([[ImageCache sharedImageCache] hasImageWithKey:self.path])
    {
        [loadedImage release];
        loadedImage = [[[ImageCache sharedImageCache] imageForKey:self.path] retain];
        [self setBackgroundImage:loadedImage];
        //NSLog(@"ImageCache used: %@", self.path);
        
        [self connectionDidFinishLoading:nil];
        return YES;
    }
    
    //Busy loading
    if (connection != nil)
        return NO;
    
    //Normal loading from network
    NSURL *url = [NSURL URLWithString:self.path];
    NSURLRequest* request = [NSURLRequest requestWithURL: url
                                          cachePolicy: NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval: 15.0];
    [connectionBackground release];
    connectionBackground = nil;
    connectionBackground = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    connection = nil;
    return YES;
}


//
// Return the current image object being used as background image
//
- (UIImage *) getBackgroundImage
{
    return loadedImage;
}


//
// Return the current image object being used as foreground image
//
- (UIImage *) getImage
{
    return [self imageForState:UIControlStateNormal];
}


//
//
//
- (void) setBackgroundImage:(UIImage*)img
{
    //[loadedImage release];
    //loadedImage = [img retain];
    [self setBackgroundImage:img forState:UIControlStateNormal];
}


//
//
//
- (void) setImage:(UIImage*)img
{
    [self setImage:img forState:UIControlStateNormal];
}


#pragma mark --
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)])
    {
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];       
        if (statusCode == 404 || statusCode == 503)
        {
            if (conn == connection)                 connection = nil;
            if (conn == connectionBackground)       connectionBackground = nil;
            
            [conn cancel];
            [conn release];
            conn = nil;
            NSLog(@"Loading async image failed (%d): %@", statusCode, path);
            
            [self setBackgroundImage:[UIImage imageNamed:@"continent_page_pin_error"] forState:UIControlStateNormal];
        }
    }
}


- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData
{
    if (data==nil)
        data = [[NSMutableData alloc] initWithCapacity:2048];
    
    [data appendData:incrementalData];
}


- (void)connectionDidFinishLoading:(NSURLConnection*)conn
{
    if (conn != nil)
    {
        [loadedImage release];
        loadedImage = [[UIImage alloc] initWithData:data];
        
        // Put it into cache
        [[ImageCache sharedImageCache] storeImage:loadedImage withKey:path];
        
        if (conn == connectionBackground)       [self setBackgroundImage:loadedImage];          
        else                                    [self setImage:loadedImage];
 
        if (conn == connection)                 connection = nil;
        if (conn == connectionBackground)       connectionBackground = nil;
        
        [data release];     data = nil;
        [conn release];     conn = nil;
    }
    
    self.clipsToBounds = YES;
    self.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    
    //Request to redraw
    [self setNeedsLayout];
    
    //If we have a loading icon as subview
    for (UIView *view in self.subviews)
    {
        if ([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            [(UIActivityIndicatorView*)view stopAnimating];
            [view removeFromSuperview];
            [view release];
        }
    }
        
    //No FadeIn, just show and return
    if (!enableFadeIn)
    {
        self.alpha = 1.0;
        return;
    }
    
    //Set up a FadeIn animation on alpha property (from 0 to 1)
    self.alpha = 0.0;    
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.4];
	self.alpha = 1.0;
	[UIView commitAnimations];
    
    //Raise an event
    if (delegate != nil && [delegate respondsToSelector:(@selector(AsyncImageView:didFinishLoading:withImage:))])
        [delegate AsyncButton:self didFinishLoading:path withImage:loadedImage];
}


- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"Failed to load async image: %@", path);
    NSLog(@"With error: %@", [error localizedDescription]);
    
    //If we have a loading icon as subview
    for (UIView *view in self.subviews)
        if ([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            [(UIActivityIndicatorView*)view stopAnimating];
            [view removeFromSuperview];
            [view release];
        }

    if (conn == connection)                 connection = nil;
    if (conn == connectionBackground)       connectionBackground = nil;
        
    [data release];     data = nil;
    [conn release];     conn = nil;
    
    //Raise an event
    if (delegate != nil && [delegate respondsToSelector:(@selector(AsyncImageView:didErrorLoading:))])
        [delegate AsyncButton:self didErrorLoading:path];
}


@end
