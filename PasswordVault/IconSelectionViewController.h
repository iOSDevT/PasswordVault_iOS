//
//  IconSelectionViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#define MAX_IMAGE_VIEWS 460
#define MAX_IMAGE_VIEWS_PER_ROW 5

#import "Enums.h"

@interface IconSelectionViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    IBOutlet UIView* _viewContainingImageViews;
    IBOutlet UIScrollView* _scrollView;
    UITapGestureRecognizer* _iconTapGestureRecognizer[MAX_IMAGE_VIEWS];
    NSString* _imageNameSelected;
    AlertType _currentAlertType;
    
}

@property (nonatomic, readonly) NSString* ImageNameSelected;

@end
