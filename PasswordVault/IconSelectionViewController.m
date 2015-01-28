//
//  IconSelectionViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "IconSelectionViewController.h"
#import "MainViewController.h"
#import "Strings.h"
#import "Utility.h"

@implementation IconSelectionViewController

@synthesize ImageNameSelected = _imageNameSelected;

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _imageNameSelected = [@"" retain];
    }
    return self;
}

// custom delete method
-(void)dealloc
{
    [_imageNameSelected release];
    [super dealloc];
}

// Handle the case when we receive a memory warning
-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

// Called when all objects have been bound and initialized
-(void)awakeFromNib
{
    [super awakeFromNib];
}

// Called when the view is first loaded in memory
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the title for the navigation item
    self.title = @"Choose Item Icon";
    
    UIImage* backImage = [[UIImage imageNamed:@"JumpBackIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setBackgroundImage:backImage forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(handleNavigationBackButton:) forControlEvents:UIControlEventTouchUpInside];
    btnBack.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnBackItem = [[UIBarButtonItem alloc] initWithCustomView:btnBack];
    
    UIImage* hintImage = [[UIImage imageNamed:@"Question.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnHint = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnHint setBackgroundImage:hintImage forState:UIControlStateNormal];
    [btnHint.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnHint addTarget:self action:@selector(handleHintButton:) forControlEvents:UIControlEventTouchUpInside];
    btnHint.frame = CGRectMake(32, 0.0, 32, 32);
    
    UIBarButtonItem *btnHintItem = [[UIBarButtonItem alloc] initWithCustomView:btnHint];

    UIImage* stopImage = [[UIImage imageNamed:@"StopIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCancel setBackgroundImage:stopImage forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(handleNavigationCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    btnCancel.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnCancelItem = [[UIBarButtonItem alloc] initWithCustomView:btnCancel];
    
    NSArray* btnArray = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = btnArray;
    self.navigationItem.rightBarButtonItem = btnCancelItem;

    [btnBack release];
    [btnCancel release];
    [btnBackItem release];
    [btnCancelItem release];
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [super viewDidUnload];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_imageNameSelected release];
    _imageNameSelected = [@"" retain];

    for (int i = 0; i < ((UIView*)_scrollView.subviews[0]).subviews.count; ++i)
    {
        UIImageView* imageView = (UIImageView*)((UIView*)_scrollView.subviews[0]).subviews[i];
        _iconTapGestureRecognizer[i] = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _iconTapGestureRecognizer[i].delegate = self;
        imageView.userInteractionEnabled = TRUE;
        [imageView addGestureRecognizer:_iconTapGestureRecognizer[i]];
    }
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"iconSelectionViewController"
                                 withMaxWidth:160.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the view will disapper
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
    
    int index = 0;
    for (UIImageView* imageView in _viewContainingImageViews.subviews)
    {
        if (index < MAX_IMAGE_VIEWS)
        {
            [imageView removeGestureRecognizer:_iconTapGestureRecognizer[index]];
            [_iconTapGestureRecognizer[index] release];
            index++;
        }
    }
}

// Defines how to handle the rotation of the scene
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// hide the instruction on scroll
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the back button is clicked
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_imageNameSelected release];
    _imageNameSelected = [@"" retain];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// Called when the back button is clicked
-(IBAction)handleNavigationCancelButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_imageNameSelected release];
    _imageNameSelected = [@"StopIcon.png" retain];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// Handle tap callback for the image view
-(void)handleTap:(UITapGestureRecognizer*)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // determine which view we have chosen by determining position
    UIImageView* imageView = (UIImageView*)sender.view;
    CGRect frame = imageView.frame;
    
    int x = frame.origin.x / 64.0f;
    int y = frame.origin.y / 64.0f;
    int index = (y * MAX_IMAGE_VIEWS_PER_ROW) + x;
    
    [_imageNameSelected release];
    _imageNameSelected = [[NSString stringWithFormat:@"image%d.png", index] retain];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
}

// Show the hint button
-(IBAction)handleHintButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [[Strings sharedInstance] lookupString:@"iconSelectionViewControllerHint"];
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"hintTitle"]
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _currentAlertType = kAlertType_Hint;
}

@end
