//
//  PanelData.h
//
//  Created by Torin Nguyen on 29/12/11.
//  Copyright (c) 2011 Torin Nguyen. All rights reserved.
//

#import "PanelData.h"

@implementation PanelData

@synthesize tag;
@synthesize title;
@synthesize photoPath;
@synthesize detailedURL;
@synthesize imageData;
@synthesize isMarked;
@synthesize isActive;
@synthesize scrollViewIndex;
@synthesize numLikes;

- (id) init
{
    [super init];
    
	if (self)
    {
        self.isMarked = NO;
        self.isActive = NO;
	}
	return self;
}

- (void) dealloc
{  
	[tag release];
	[photoPath release];
    [detailedURL release];
    [imageData release];
    self.isMarked = NO;
    self.isActive = NO;
    [super dealloc];
}

@end
