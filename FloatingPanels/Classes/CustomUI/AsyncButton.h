//
//  AsyncButton.h
//  This is a class to replace UIButton that loads background image asynchronously
//
//  Created by Torin on 4/27/11.
//  Copyright 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class AsyncButton;

//////////////////////////////////////////////////////////////////////////////////////

@protocol AsyncButtonDelegate <NSObject>
@optional
- (void) AsyncButton:(AsyncButton *)asyncButton didFinishLoading:(NSString *)path withImage:(UIImage *)image;
- (void) AsyncButton:(AsyncButton *)asyncButton didErrorLoading:(NSString *)path;
@end

//////////////////////////////////////////////////////////////////////////////////////

@interface AsyncButton : UIButton
{
    //keep a reference to the connection so we can cancel download in dealloc
	NSURLConnection* connection;
	NSURLConnection* connectionBackground;
    
    //keep reference to the data so we can collect it as it downloads
    NSMutableData* data;
    
    //Delegate
	id<AsyncButtonDelegate> delegate;
    
    //keep reference to the image path so we can print out error nicely
    //NSString* path;
    
    //flag to setup animation or not after image finishes loading
    BOOL enableFadeIn;
    
    BOOL enableCache;
    
    //keep reference to the loaded image object for re-use purpose
    UIImage * loadedImage;
}

@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) id<AsyncButtonDelegate> delegate;
@property (nonatomic, assign) BOOL enableCache;

- (BOOL) loadImageFromPath:(NSString*)imagePath;
- (BOOL) loadImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable;
- (BOOL) loadBackgroundImageFromPath:(NSString*)imagePath;
- (BOOL) loadBackgroundImageFromPath:(NSString*)imagePath useFadeInAnimation:(BOOL)isEnable;
- (UIImage *) getImage;
- (UIImage *) getBackgroundImage;
- (void) setImage:(UIImage*)img;
- (void) setBackgroundImage:(UIImage*)img;
- (void)connectionDidFinishLoading:(NSURLConnection*)conn;

@end
