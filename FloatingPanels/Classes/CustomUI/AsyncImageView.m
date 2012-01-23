//
//  AsyncImageView.m
//  This is a class to replace UIImageView that loads image asynchronously
//
//  Created by Torin on 4/27/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import "AsyncImageView.h"
#import "ImageCache.h"

@implementation AsyncImageView

@synthesize delegate;
@synthesize path;
@synthesize enableCache;

- (id) init
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
        //Set default image first
        [self resetImage:[UIImage imageNamed:@"continent_page_pin_dummy"]];

        connection = nil;
        self.enableCache = YES;
        self.clipsToBounds = YES;
        self.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    }
    return self;
}


- (void) resetImage:(UIImage *)img
{
    self.image = img;
}


- (BOOL) loadImageFromPath:(NSString*)imagePath
{   
    return [self loadImageFromPath:imagePath useFadeInAnimation:YES];
}


- (BOOL) loadImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable
{
    if (imagePath == nil)
        return NO;
        
    self.path = imagePath;
    enableFadeIn = isEnable;
    
    //Load from cache if available, and valid
    if ([[ImageCache sharedImageCache] hasImageWithKey:self.path])
    {
        UIImage *cachedImage = [[ImageCache sharedImageCache] imageForKey:self.path];
        if (cachedImage.size.width > 0 && cachedImage.size.height > 0)
        {
            [self setImage:cachedImage];
            [self connectionDidFinishLoading:nil];
            return YES;
        }
    }
    
    //Busy loading
    if (connection != nil)
        return NO;
    
    //Normal loading from network
    NSURL *url = [NSURL URLWithString:self.path];
    NSURLRequest* request = [NSURLRequest requestWithURL: url
                                             cachePolicy: NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval: 20.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    return YES;
}


- (void) dealloc
{   
    //NSLog(@"AsyncImageView dealloc");
    self.delegate = nil;
    self.image = nil;
    self.path = nil;
    
    //Already released
    //[connection release];
    //connection = nil;
    //[data release];
    //data = nil;
    
    [super dealloc];
}


#pragma mark --
#pragma mark NSURLConnectionDelegate

- (void) connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    if ([response respondsToSelector:@selector(statusCode)])
    {
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];       
        if (statusCode == 404 || statusCode == 503)
        {
            [connection cancel];
            [connection release];
            connection = nil;

            NSLog(@"Loading async image failed (%d): %@", statusCode, path);
            
            //Show error image
            self.image = nil;
            [self setImage:[[UIImage imageNamed:@"continent_page_pin_error"] autorelease]];
        }
    }
}


- (void) connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData
{
    if (data == nil)
        data = [[NSMutableData alloc] initWithCapacity:2048];
    
    [data appendData:incrementalData];
}


- (void) connectionDidFinishLoading:(NSURLConnection*)conn
{   
    //If we actually load from network
    if (conn != nil)
    {
        UIImage *img = [[UIImage alloc] initWithData:data];

        //Save to cache
        [[ImageCache sharedImageCache] storeImage:img withKey:path];
        [img release];         img = nil;
        
        [connection release];  connection = nil;
        [data release];        data = nil;
        
        self.image = [[ImageCache sharedImageCache] imageForKey:path];
    }
    
    //If we have a loading icon as subview
    for (UIView *view in self.subviews)
        if ([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            [(UIActivityIndicatorView*)view stopAnimating];
            [view removeFromSuperview];
            [view release];
        }

    //No FadeIn, just immediately show and return
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
        [delegate AsyncImageView:self didFinishLoading:path withImage:self.image];
}


- (void) connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"Failed to load async image: %@", path);
    
    //If we have a loading icon as subview
    for (UIView *view in self.subviews)
        if ([view isKindOfClass:[UIActivityIndicatorView class]])
        {
            [(UIActivityIndicatorView*)view stopAnimating];
            [view removeFromSuperview];
            [view release];
        }
    
    [connection release];
    connection = nil;

    [data release];
    data = nil;
    
    //Raise an event
    if (delegate != nil && [delegate respondsToSelector:(@selector(AsyncImageView:didErrorLoading:))])
        [delegate AsyncImageView:self didErrorLoading:path];
}

@end
