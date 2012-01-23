//
//  PanelData.h
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PanelData : NSObject
{
	NSString *tag;
	NSString *photoPath;
	NSString *detailedURL;
    UIImage *imageData;
    BOOL isMarked;
    BOOL isActive;
    int scrollViewIndex;
    int numLikes;
}

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *photoPath;
@property (nonatomic, copy) NSString *detailedURL;
@property (nonatomic, retain) UIImage *imageData;
@property (nonatomic, assign) BOOL isMarked;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) int scrollViewIndex;
@property (nonatomic, assign) int numLikes;

@end
