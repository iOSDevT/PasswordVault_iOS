//
//  AutoLockViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AutoLockViewController.h"
#import "MainViewController.h"
#import "Strings.h"
#import "Utility.h"
#import "UIKit/UIKit.h"

#define AUTOLOCK_TIME_INCREMENT 15
#define MAX_AUTOLOCK_TIME (AUTOLOCK_TIME_INCREMENT * 4 * 15)
#define TIMEOUT_CHECK 3.0
#define BUTTON_REPEAT_TIME 0.075

@interface AutoLockViewController(Private)
-(void)handleBackButtonInternal;
-(void)handleForwardButtonInternal;
-(void)popToRootViewController;
-(void)setTitle;
@end 

@implementation AutoLockViewController

// This function will not be called currently, since the view controller is set
// as the root view controller of the window.
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _autoLockTimeInSeconds = 0;
        _autoLockType = kAutoLockType_None;
        _startTime = -1.0;
        _repeatButtonTimer = nil;
    }
    return self;
}

// handle when we receive a low memory warning
-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

// custom delete routine
-(void)dealloc
{
    [self cancelRepeatTimer];
    [super dealloc];
}

#pragma mark - View lifecycle

// Handle when the view is about to be displayed
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateAutoLockType:kAutoLockEvent_Load];
    
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGRect cur = _autoLockTextField.frame;
    CGRect start = CGRectMake(cur.origin.x, -40.0f, cur.size.width, cur.size.height);
    CGRect end = _autoLockTextField.frame;
    [[Utility sharedInstance] animateControl:_autoLockTextField
                                   withStart:start
                                     withEnd:end
                                    withTime:0.5f
                                    andDelay:-1.0f];
    
    CGRect cur1 = _backButton.frame;
    CGRect start1 = CGRectMake(-100.0f, cur1.origin.y, cur1.size.width, cur1.size.height);
    CGRect end1 = _backButton.frame;
    [[Utility sharedInstance] animateControl:_backButton
                                   withStart:start1
                                     withEnd:end1
                                    withTime:0.5f
                                    andDelay:-1.0f];
    
    CGRect cur2 = _forwardButton.frame;
    CGRect start2 = CGRectMake(screenWidth + 100.0f, cur2.origin.y, cur2.size.width, cur2.size.height);
    CGRect end2 = _forwardButton.frame;
    [[Utility sharedInstance] animateControl:_forwardButton
                                   withStart:start2
                                     withEnd:end2
                                    withTime:0.5f
                                    andDelay:-1.0f];
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"autoLockViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    // set the font here
    _autoLockTextField.font = [UIFont fontWithName:[Utility sharedInstance].primaryFontName size:[Utility sharedInstance].textfieldFontSize];
    
    // set the text right here to force the textfield to update the
    // text position, as changing the font adversely affects the
    // position of the text.
    _autoLockTextField.text = @"";
    [self updateAutoLockTextField];
}

// Based on the current user defaults, the autolock
// type and time are determined by their corresponding stored values
-(void)updateAutoLockType:(AutoLockEvent)event
{
    // Read the user defaults and set the auto lock type
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    // handle loading the auto lock info and update the UI
    if (event == kAutoLockEvent_Load)
    {
        int autoLockTime = [[defaults objectForKey:@"AutoLockTime"] intValue];
    
        if (autoLockTime == 0)
        {
            _autoLockType = kAutoLockType_None;
            _autoLockTimeInSeconds = 0;
            [_backButton setEnabled:FALSE];
            [_forwardButton setEnabled:TRUE];
        }
        else
        {
            _autoLockType = kAutoLockType_Timed;
            _autoLockTimeInSeconds = autoLockTime;
            [_backButton setEnabled:TRUE];
            [_forwardButton setEnabled:_autoLockTimeInSeconds < MAX_AUTOLOCK_TIME];
        }
    
        [self updateAutoLockTextField];
    }
    // Save the user's current autolock settings
    else if (event == kAutoLockEvent_Save)
    {
        [defaults setInteger:_autoLockTimeInSeconds forKey:@"AutoLockTime"];
        [defaults synchronize];
    }
}

// Handle when we are not displaying anymore
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // save the settings
    [self updateAutoLockType:kAutoLockEvent_Save];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
}

// When the view first loads create other view controllers needed for the transfer
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage* backImage = [[UIImage imageNamed:@"JumpBackIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setBackgroundImage:backImage forState:UIControlStateNormal];
    [btnBack.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnBack addTarget:self action:@selector(handleNavigationBackButton:) forControlEvents:UIControlEventTouchUpInside];
    btnBack.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnBackItem = [[UIBarButtonItem alloc]initWithCustomView:btnBack];
    
    UIImage* hintImage = [[UIImage imageNamed:@"Question.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnHint = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnHint setBackgroundImage:hintImage forState:UIControlStateNormal];
    [btnHint.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnHint addTarget:self action:@selector(handleHintButton:) forControlEvents:UIControlEventTouchUpInside];
    btnHint.frame = CGRectMake(32, 0, 32, 32);
    
    UIBarButtonItem *btnHintItem = [[UIBarButtonItem alloc] initWithCustomView:btnHint];
    
    NSArray* leftArray = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = leftArray;

    [btnBack release];
    [btnHint release];
    [btnBackItem release];
    [btnHintItem release];
}

// Handle when we unload the primary view controller
- (void)viewDidUnload
{
    [super viewDidUnload];
}

// Handle should auto rotate
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Handle when the user clicks on the back button
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

// handles the back button
-(IBAction)handleBackButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self cancelRepeatTimer];
    
    _repeatButtonTimer = [NSTimer scheduledTimerWithTimeInterval:BUTTON_REPEAT_TIME
                                                          target:self
                                                        selector:@selector(handleBackButtonInternal)
                                                        userInfo:nil
                                                         repeats:YES];
}

// Performs the actual logic for decrementing the time value
// that controls when the app will boot you to the title screen
-(void)handleBackButtonInternal
{
    if (_autoLockType == kAutoLockType_Timed && _autoLockTimeInSeconds == AUTOLOCK_TIME_INCREMENT)
    {
        _autoLockType = kAutoLockType_None;
        _autoLockTimeInSeconds = 0;
    }
    else if (_autoLockType == kAutoLockType_Timed)
    {
        _autoLockTimeInSeconds -= AUTOLOCK_TIME_INCREMENT;
    }
    
    if (_autoLockType == kAutoLockType_None)
    {
        [_autoLockTextField setText:[[Strings sharedInstance] lookupString:@"none"]];
        [_backButton setEnabled:FALSE];
        [self cancelRepeatTimer];
    }
    else
    {
        [self updateAutoLockTextField];
        [_forwardButton setEnabled:TRUE];
    }
    
    // udpate settings
    [self updateAutoLockType:kAutoLockEvent_Save];
}

// cancels the timers action preventing any further
// back button reqyests
-(IBAction)handleBackButtonRelease
{
    [self cancelRepeatTimer];
}

// handles the forward button
-(IBAction)handleForwardButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self cancelRepeatTimer];
    
    _repeatButtonTimer = [NSTimer scheduledTimerWithTimeInterval:BUTTON_REPEAT_TIME
                                                          target:self
                                                        selector:@selector(handleForwardButtonInternal)
                                                        userInfo:nil
                                                         repeats:YES];
}

// handles the actual logic when the player chooses to increase
// the value of their timeout
-(void)handleForwardButtonInternal
{
    if (_autoLockType == kAutoLockType_None)
    {
        _autoLockType = kAutoLockType_Timed;
        _autoLockTimeInSeconds = AUTOLOCK_TIME_INCREMENT;
        [_backButton setEnabled:TRUE];
    }
    else if (_autoLockType == kAutoLockType_Timed)
    {
        if (_autoLockTimeInSeconds < MAX_AUTOLOCK_TIME)
        {
            _autoLockTimeInSeconds += AUTOLOCK_TIME_INCREMENT;
            
            if (_autoLockTimeInSeconds == MAX_AUTOLOCK_TIME)
            {
                [_forwardButton setEnabled:FALSE];
                [self cancelRepeatTimer];
            }
        }
    }
    
    [self updateAutoLockTextField];
    
    // update the user's current settings
    [self updateAutoLockType:kAutoLockEvent_Save];
}

// Cancels the timer preventing any further forward button requests
-(IBAction)handleForwardButtonRelease
{
    [self cancelRepeatTimer];
}

// update the text on the text field
-(void)updateAutoLockTextField
{
    if (_autoLockType == kAutoLockType_None || _autoLockTimeInSeconds == 0)
    {
        [_autoLockTextField setText:[[Strings sharedInstance] lookupString:@"none"]];
    }
    else if (_autoLockType == kAutoLockType_Timed)
    {
        [_autoLockTextField setText:[NSString stringWithFormat:@"%.2f %@", _autoLockTimeInSeconds / 60.0f, [[Strings sharedInstance] lookupString:@"minutes"]]];
    }
}

// Helper function for navigation
-(void)popToRootViewController
{
    // reset the state of the timer
    [self cancelAutoLockTimeout];
    
    // handle our buisness and boot the user from the vault
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[pDelegate navigationController] popToRootViewControllerAnimated:YES];
}

// Callback that checks for the auto locking of the vault
-(BOOL)handleAutoLockTimeoutCheck
{
    // somehow we are checking the timeout without a valid start time
    if (_startTime < 0.0 || _autoLockType == kAutoLockType_None)
    {
        return false;
    }
    
    unsigned long long now = [[Utility sharedInstance] getCurrentTime];
    double interval = ((double)(now - _startTime) / 1000.0);
    double timeout = (double)(_autoLockTimeInSeconds);
    
    // did the user leave the app idle for too long?
    if (interval >= timeout)
    {
        [self performSelector:@selector(popToRootViewController) withObject:nil afterDelay:0.5f];
        return true;
    }
    else
    {
        [self performSelector:@selector(handleAutoLockTimeoutCheck) withObject:nil afterDelay:TIMEOUT_CHECK];
        return false;
    }
}

// check if we have timed out
-(void)evaluateAutoLockTimeout
{
    // Cancel any outdated scheduled selectors from firing
    [AutoLockViewController cancelPreviousPerformRequestsWithTarget:self];
    
    // directly call this function to force an immediate evaluation of
    // timeout conditon
    [self handleAutoLockTimeoutCheck];
}

// Kills the current timeout check
-(void)cancelAutoLockTimeout
{
    _startTime = -1.0;
    [AutoLockViewController cancelPreviousPerformRequestsWithTarget:self];
}

// Resets the auto lock timeout
-(void)resetAutoLockTimeout
{
    [self cancelAutoLockTimeout];
    
    if (_autoLockType == kAutoLockType_Timed)
    {
        _startTime = [[Utility sharedInstance] getCurrentTime];
        [self performSelector:@selector(handleAutoLockTimeoutCheck) withObject:nil afterDelay:TIMEOUT_CHECK];
    }
}

// have we started the auto lock timeout?
-(BOOL)isStarted
{
    return _startTime >= 0.0;
}

// cleans up the timer preventing any more callbacks from occurring
-(void)cancelRepeatTimer
{
    if (_repeatButtonTimer != nil)
    {
        [_repeatButtonTimer invalidate];
        _repeatButtonTimer = nil;
    }
}

// callback for alertview
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
}

// Handle when the user clicks the hint button
-(IBAction)handleHintButton:(id)sender;
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"hintTitle"]
                                                        message:[[Strings sharedInstance] lookupString:@"autoLockViewControllerHint"]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
}

@end
