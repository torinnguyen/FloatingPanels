//
//  SinglePanel.h
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "PanelData.h"

@class SinglePanel;

@protocol SinglePanelDelegate <NSObject>
@optional
- (void) didClickOnBtnMark:(SinglePanel *)whichPanel withData:(PanelData*)data;
- (void) didClickOnBtnClose:(SinglePanel *)whichPanel withData:(PanelData*)data;
- (void) didClickOnThePanel:(SinglePanel *)whichPanel withData:(PanelData*)data;
@end

//-------------------------------------------------------------------

@interface SinglePanel : UIViewController <UIWebViewDelegate>
{
    UILabel *lblTitle;
    AsyncImageView *imgTheImage;
    UIImageView *imgTheAltImage;
}

@property (nonatomic, assign) id<SinglePanelDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIButton *btnMark;
@property (nonatomic, retain) IBOutlet UIButton *btnClose;
@property (nonatomic, retain) IBOutlet UIButton *btnVideo;
@property (nonatomic, retain) IBOutlet UIButton *btnThePanel;
@property (nonatomic, retain) IBOutlet UIWebView *webview;
@property (nonatomic, retain) IBOutlet UILabel *lblTitle;
@property (nonatomic, retain) IBOutlet AsyncImageView *imgTheImage;
@property (nonatomic, retain) IBOutlet UIImageView *imgFrame;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *indicator;

- (IBAction) onBtnMark: (id) sender;
- (IBAction) onBtnClose: (id) sender;
- (IBAction) onBtnVideo: (id) sender;
- (IBAction) onBtnThePanel: (id) sender;
- (void) setPanelData:(PanelData*)data;
- (void) setZoomInView:(UIView*)whichView;
- (void) setNormalView;
- (void) setActive:(BOOL)active;
- (NSString *) modifyYouTubeUrl: (NSString *) tyurl;

@end

