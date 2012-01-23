//
//  AsyncImageView.h
//  This is a class to replace UIImageView that loads image asynchronously
//
//  Example:
//  AsyncImageView *imageView = [[AsyncImageView alloc] initWithFrame:CGRectMake(5, 5, 57, 48)];
//  [imageView loadImageFromPath:imagePath];
//
//  Created by Torin on 4/27/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AsyncImageView;

//////////////////////////////////////////////////////////////////////////////////////

@protocol AsyncImageViewDelegate <NSObject>
@optional
- (void) AsyncImageView:(AsyncImageView *)asyncImageView didFinishLoading:(NSString *)path withImage:(UIImage *)image;
- (void) AsyncImageView:(AsyncImageView *)asyncImageView didErrorLoading:(NSString *)path;
@end

//////////////////////////////////////////////////////////////////////////////////////

@interface AsyncImageView : UIImageView
{    
    //Delegate
	id<AsyncImageViewDelegate> delegate;

@private
    //keep a reference to the connection so we can cancel download in dealloc
	NSURLConnection* connection;
    
    //keep reference to the data so we can collect it as it downloads
	NSMutableData* data;
       
    //keep reference to the image path so we can print out error nicely
    //NSString* path;
    
    //flag to setup animation or not after image finishes loading
    BOOL enableFadeIn;
    
    BOOL enableCache;
}

@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) id<AsyncImageViewDelegate> delegate;
@property (nonatomic, assign) BOOL enableCache;

- (void) resetImage:(UIImage *)img;
- (BOOL) loadImageFromPath:(NSString*)imagePath;
- (BOOL) loadImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable;
- (void) connectionDidFinishLoading:(NSURLConnection*)conn;

@end
