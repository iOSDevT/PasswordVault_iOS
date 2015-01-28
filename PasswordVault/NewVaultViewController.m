//
//  NewVaultViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "NewVaultViewController.h"
#import "PasswordVault.h"
#import "PasswordVaultViewController.h"
#import "Strings.h"
#import "Utility.h"
#import "QuartzCore/QuartzCore.h"

// static data
const int kVaultNameMaxLimit = 16;
const int KVaultNameMinLimit = 4;
const int kVaultPasswordMaxLimit = 24;
const int kVaultPasswordMinLimit = 8;

// private functions
@interface NewVaultViewController(Private)
-(BOOL)shouldHideCreateButton;
-(void)createNewVault;
@end

@implementation NewVaultViewController

@synthesize CreateVaultButton = _createVaultButton;

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
    }
    return self;
}

// custom delete routine
-(void)dealloc
{
    [super dealloc];
}

// Handle the case when we receive a memory warning
-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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

    self.title = @"New Vault";
    
    UIImage* backImage = [[UIImage imageNamed:@"JumpBackIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setBackgroundImage:backImage forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(handleNavigationBackButton:) forControlEvents:UIControlEventTouchUpInside];
    btnBack.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnBackItem = [[UIBarButtonItem alloc] initWithCustomView:btnBack];

    UIImage* hintImage = [[UIImage imageNamed:@"Question.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnHint = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnHint setBackgroundImage:hintImage forState:UIControlStateNormal];
    [btnHint addTarget:self action:@selector(handleHintButton:) forControlEvents:UIControlEventTouchUpInside];
    btnHint.frame = CGRectMake(32, 0, 32, 32);
    
    UIBarButtonItem *btnHintItem = [[UIBarButtonItem alloc] initWithCustomView:btnHint];

    NSArray* leftItems = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = leftItems;
    
    [btnBack release];
    [btnHint release];
    [btnBackItem release];
    [btnHintItem release];
        
    _vaultNameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _vaultPasswordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _vaultPassword2TextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _vaultNameTextField.borderStyle = UITextBorderStyleRoundedRect;
    _vaultPasswordTextField.borderStyle = UITextBorderStyleRoundedRect;
    _vaultPassword2TextField.borderStyle = UITextBorderStyleRoundedRect;
    
    [_vaultNameTextField addTarget:self 
                            action:@selector(textFieldDidChange:) 
                  forControlEvents:UIControlEventEditingChanged];
    [_vaultPasswordTextField addTarget:self 
                                action:@selector(textFieldDidChange:) 
                      forControlEvents:UIControlEventEditingChanged];
    [_vaultPassword2TextField addTarget:self 
                                action:@selector(textFieldDidChange:) 
                      forControlEvents:UIControlEventEditingChanged];
    
    UIImage* disabled = [UIImage imageNamed:@"DefaultButtonDisabled.png"];
    UIImage* alphaDisabled = [[Utility sharedInstance] addImageAlpha:disabled withAlpha:0.4f];
    
    // Set button images for various states
    [_createVaultButton setBackgroundImage:[UIImage imageNamed:@"DefaultButton.png"] forState:UIControlStateSelected];
    [_createVaultButton setBackgroundImage:[UIImage imageNamed:@"DefaultButton.png"] forState:UIControlStateHighlighted];
    [_createVaultButton setBackgroundImage:[UIImage imageNamed:@"DefaultButton.png"] forState:UIControlStateHighlighted];
    [_createVaultButton setBackgroundImage:alphaDisabled forState:UIControlStateDisabled];
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [super viewDidUnload];
    
    [_vaultNameTextField removeTarget:self 
                               action:@selector(textFieldDidChange:) 
                     forControlEvents:UIControlEventEditingChanged];
    [_vaultPasswordTextField removeTarget:self 
                                   action:@selector(textFieldDidChange:) 
                         forControlEvents:UIControlEventEditingChanged];
    [_vaultPassword2TextField removeTarget:self 
                                   action:@selector(textFieldDidChange:) 
                         forControlEvents:UIControlEventEditingChanged];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
            
    // Reset the text on the textfield
    [_vaultNameTextField setText:@""];
    [_vaultPasswordTextField setText:@""];
    [_vaultPassword2TextField setText:@""];
    
    // Update the create button enabled state
    [_createVaultButton setEnabled:![self shouldHideCreateButton]];
    
    float screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGRect cur = _vaultNameTextField.frame;
    CGRect start = CGRectMake(-1000, cur.origin.y, cur.size.width, cur.size.height);
    CGRect end = _vaultNameTextField.frame;
    [[Utility sharedInstance] animateControl:_vaultNameTextField
                                   withStart:start
                                     withEnd:end
                                    withTime:0.5f
                                    andDelay:-1.0f];

    CGRect cur1 = _vaultPasswordTextField.frame;
    CGRect start1 = CGRectMake(-1000, cur1.origin.y, cur1.size.width, cur1.size.height);
    CGRect end1 = _vaultPasswordTextField.frame;
    [[Utility sharedInstance] animateControl:_vaultPasswordTextField
                                   withStart:start1
                                     withEnd:end1
                                    withTime:0.5f
                                    andDelay:0.1f];

    CGRect cur2 = _vaultPassword2TextField.frame;
    CGRect start2 = CGRectMake(-1000, cur2.origin.y, cur2.size.width, cur2.size.height);
    CGRect end2 = _vaultPassword2TextField.frame;
    [[Utility sharedInstance] animateControl:_vaultPassword2TextField
                                   withStart:start2
                                     withEnd:end2
                                    withTime:0.5f
                                    andDelay:0.2f];
    
    CGRect cur3 = _createVaultButton.frame;
    CGRect start3 = CGRectMake(cur3.origin.x, screenHeight + 40.0f, cur3.size.width, cur3.size.height);
    CGRect end3 = _createVaultButton.frame;
    [[Utility sharedInstance] animateControl:_createVaultButton
                                   withStart:start3
                                     withEnd:end3
                                    withTime:0.52f
                                    andDelay:-1.0f];
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"newVaultViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    // Update textfield's font
    [[Utility sharedInstance] determineAndSetFontForTextfield:_vaultNameTextField
                                                     withText:[[Strings sharedInstance] lookupString:@"enterVaultName"]
                                                  andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    _vaultNameTextField.placeholder = [[Strings sharedInstance] lookupString:@"enterVaultName"];
    
    [[Utility sharedInstance] determineAndSetFontForTextfield:_vaultPasswordTextField
                                                     withText:[[Strings sharedInstance] lookupString:@"enterVaultName"]
                                                  andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    _vaultPasswordTextField.placeholder = [[Strings sharedInstance] lookupString:@"enterVaultPassword"];
    
    [[Utility sharedInstance] determineAndSetFontForTextfield:_vaultPassword2TextField
                                                     withText:[[Strings sharedInstance] lookupString:@"enterVaultName"]
                                                  andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    _vaultPassword2TextField.placeholder = [[Strings sharedInstance] lookupString:@"reenterVaultPassword"];
    
    // Update button's font
    [[Utility sharedInstance] determineAndSetFontForButton:_createVaultButton
                                                  withText:[[Strings sharedInstance] lookupString:@"createVaultButton"]
                                               andMaxWidth:[Utility sharedInstance].buttonTextWidth andIsTip:FALSE];
    [self.CreateVaultButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [self.CreateVaultButton titleLabel].text = [[Strings sharedInstance] lookupString:@"createVaultButton"];
    [self.CreateVaultButton setTitle:[[Strings sharedInstance] lookupString:@"createVaultButton"] forState:UIControlStateNormal];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
}

// Defines how to handle the rotation of the scene
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Handles closing the keyboard when the user is done entering their vault name
-(IBAction)vaultNamePressDone:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_vaultNameTextField resignFirstResponder];
    
    // alert the player to the fact that their vault name is too short
    if (_vaultNameTextField.text.length < KVaultNameMinLimit)
    {
        NSString* message = 
        [NSString stringWithFormat:@"Vault name must be greater than or equal to %d in length.", KVaultNameMinLimit];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Enter Vault Name" 
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        _currentAlertType = kAlertType_Generic;
    }
}

// Handle closing the keyboard when the user is done entering their password
-(IBAction)vaultPasswordPressDone:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_vaultPasswordTextField resignFirstResponder];
    
    // alert the player to the fact that their vault name is too short
    if (_vaultPasswordTextField.text.length < kVaultPasswordMinLimit)
    {
        NSString* message = 
        [NSString stringWithFormat:@"Vault password must be greater than or equal to %d in length.", kVaultPasswordMinLimit];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Enter Vault Password" 
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        _currentAlertType = kAlertType_Generic;
    }
}

// Handle closing the keyboard when the user is done entering their password
-(IBAction)vaultPassword2PressDone:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_vaultPassword2TextField resignFirstResponder];
    
    // alert the player to the fact that their vault name is too short
    if (_vaultPasswordTextField.text.length >= kVaultPasswordMinLimit && 
        (_vaultPassword2TextField.text.length < kVaultPasswordMinLimit ||
        [_vaultPassword2TextField.text isEqualToString:_vaultPasswordTextField.text] == FALSE))
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Enter Vault Password" 
                                                            message:@"Passwords do not match! Re-enter password."
                                                           delegate:nil 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
}

// determines if the button should be enabled or not
-(BOOL)shouldHideCreateButton
{
    return [_vaultNameTextField.text length] < KVaultNameMinLimit ||
    [_vaultPasswordTextField.text length] < kVaultPasswordMinLimit ||
    [_vaultPassword2TextField.text length] < kVaultPasswordMinLimit ||
    [_vaultPasswordTextField.text isEqualToString:_vaultPassword2TextField.text] == FALSE;
}

// Handle responding to the text field
- (void)textFieldDidChange:(UITextField*)textField
{
    [_createVaultButton setEnabled:![self shouldHideCreateButton]];
}

// Handles limiting the number of characters allowed
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
    if (textField == _vaultNameTextField)
    {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > kVaultNameMaxLimit) ? NO : YES;
    }
    else if (textField == _vaultPasswordTextField || textField == _vaultPassword2TextField)
    {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > kVaultPasswordMaxLimit) ? NO : YES;      
    }
    
    return TRUE;
}


// Handle when the user clicks on the create vault button
-(IBAction)handleCreateVaultButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // close an open keyboard
    [_vaultNameTextField resignFirstResponder];
    [_vaultPasswordTextField resignFirstResponder];
    [_vaultPassword2TextField resignFirstResponder];
    
    NSString* basefilename = _vaultNameTextField.text;
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, basefilename, kPasswordVaultExtension];
    
    // Notify the user that they are about to overwrite an existing file
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPath])
    {
        NSString* title = [NSString stringWithFormat:@"%@\n%@", [[Strings sharedInstance] lookupString:@"overwriteFile"], basefilename];
        NSString* message = [[Strings sharedInstance] lookupString:@"overwriteFileMessage"];
        
        // Create a popup to enter the password for the file selected
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self 
                                                  cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                                  otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
        [alertView show];
        [alertView release];
        
        _currentAlertType = kAlertType_OverwriteVault;
    }
    else
    {
        [self createNewVault];
    }
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // the user cancelled, do nothing
    if (buttonIndex == 0)
    {
    }
    // The user chose to overwrite the file
    else if (buttonIndex == 1)
    {
        // Save the new vault once created
        if (_currentAlertType == kAlertType_OverwriteVault) {
            [self createNewVault];
        }
    }
}

// creates the new vault with the name provided
-(void)createNewVault
{
    // create the new vault
    [[PasswordVault sharedInstance] createNewVault:_vaultNameTextField.text withPassword:_vaultPasswordTextField.text];
    
    // animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    PasswordVaultViewController* pPasswordVaultViewController = [pDelegate mainViewController].PasswordVaultViewController;
    [[pDelegate navigationController] pushViewController:pPasswordVaultViewController animated:YES];
}

// Handle when the user clicks on the back button
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

// Handle when the user clicks the hint button
-(IBAction)handleHintButton:(id)sender;
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"newVaultViewControllerHint"],KVaultNameMinLimit, kVaultNameMaxLimit, kVaultPasswordMinLimit, kVaultPasswordMaxLimit];
    
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
