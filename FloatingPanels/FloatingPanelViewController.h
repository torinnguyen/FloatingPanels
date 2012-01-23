//
//  FloatingPanelViewController.h
//  FloatingPanels
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BaseController.h"
#import "SinglePanel.h"

@interface FloatingPanelViewController : BaseController <SinglePanelDelegate, UIScrollViewDelegate, FBRequestDelegate>
{
    NSMutableDictionary * panelPointers;
    NSMutableDictionary * dataPointer;
    NSMutableArray * scrollViewPointers;
}

@property (nonatomic, retain) IBOutlet UIImageView *imgDarkCover;
@property (nonatomic, retain) IBOutlet UIButton *btnFacebook;

//UI Events
- (IBAction) onBtnFacebook:(id)sender;

//UI Helper
- (void) showBusyUI;
- (void) hideBusyUI;
- (void) onTimeout:(NSTimer *) theTimer;
- (int) random:(int)min max:(int)max;

//ScrollView implementation
- (int) numScrollView;
- (int) incrementScrollViewIndex;
- (UIScrollView*) getScrollView:(int)index;
- (void) fixScrollViewHeight:(int)index;
- (void) scrollViewByOffSet:(int)index x:(int)x y:(int)y;
- (void) scrollViewByPercentage:(int)index x:(float)x y:(float)y;

//Helper functions
- (void) populateAllPanel;
- (void) populatePanel:(PanelData*)data panelIndex:(int)index;
- (CGRect) getAllPanelSize:(int)index;
- (void) refreshAllPanel;
- (void) setActiveScrollView:(UIScrollView*)whichScrollView;
- (void) deleteAllPanel;

//Facebook integration
- (void) requestFacebookUserInfo;
- (void) requestFacebookUserPhoto;
- (void) parseFacebookPhotoArray:(NSArray*)dataArray;

@end
