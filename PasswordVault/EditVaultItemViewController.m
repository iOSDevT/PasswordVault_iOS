//
//  EditVaultItemViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 1/4/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "EditVaultItemViewController.h"
#import "MainViewController.h"
#import "NSStringExtension.h"
#import "PasswordVault.h"
#import "PasswordVaultItem.h"
#import "Strings.h"
#import "Utility.h"
#import "WebViewController.h"

#import "QuartzCore/QuartzCore.h"

BOOL keyboardShown2 = FALSE;
static const float kCellHeight = 32.0f;

@interface EditVaultItemViewController(Private)
-(void)updatePasswordVaultItem;
-(void)showWebHasChangesAlert;
-(void)showCancelHasChangesAlert;
-(void)showBackHasChangesAlert;
-(void)showForwardHasChangesAlert;
-(void)showAreYouSureAlert;
-(void)createChangesAlert;
-(void)updateBarButtons;
@end

@implementation EditVaultItemViewController

@synthesize activeItem = _activeItem;

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _notesTextViewPlaceHolderText = [NSString stringWithString:@"Enter Notes..."];
        _activeTextField = nil;
        _selectedIcon = [[NSString stringWithString:@""] retain];
        _currentAlertType = kAlertType_None;
        _autoCompleteData = [[NSMutableArray array] retain];
    }
    return self;
}

// custom delete method
-(void)dealloc
{
    [_autoCompleteData release];
    [super dealloc];
}

// Handle the case when we receive a memory warning
-(void)didReceiveMemoryWarning
{
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
    self.title = @"Edit";
    
    
    UIImage* backImage = [[UIImage imageNamed:@"JumpBackIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setBackgroundImage:backImage forState:UIControlStateNormal];
    [btnBack.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
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
    
    NSArray* leftArray = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = leftArray;
    
    UIImage* editImage = [[UIImage imageNamed:@"EditIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnEdit setBackgroundImage:editImage forState:UIControlStateNormal];
    [btnEdit.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnEdit addTarget:self action:@selector(handleNavigationEditButton:) forControlEvents:UIControlEventTouchUpInside];
    btnEdit.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnEditItem = [[UIBarButtonItem alloc] initWithCustomView:btnEdit];
    
    UIImage* webImage = [[UIImage imageNamed:@"WebIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnWeb = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnWeb setBackgroundImage:webImage forState:UIControlStateNormal];
    [btnWeb.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnWeb addTarget:self action:@selector(handleNavigationWebButton:) forControlEvents:UIControlEventTouchUpInside];
    btnWeb.frame = CGRectMake(32, 0.0, 32, 32);
    
    UIBarButtonItem *btnWebItem = [[UIBarButtonItem alloc] initWithCustomView:btnWeb];
    
    UIImage* forwardImage = [[UIImage imageNamed:@"JumpForwardIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnFwd = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnFwd setBackgroundImage:forwardImage forState:UIControlStateNormal];
    [btnFwd.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [btnFwd addTarget:self action:@selector(handleNavigationForwardButton:) forControlEvents:UIControlEventTouchUpInside];
    btnFwd.frame = CGRectMake(64, 0.0, 32, 32);
    
    UIBarButtonItem* btnFwdItem = [[UIBarButtonItem alloc] initWithCustomView:btnFwd];

    // store the web button
    _webButtonItem = btnWebItem;
    _forwardButtonItem = btnFwdItem;
    _editedButtonItem = btnEditItem;
    _webButton = btnWeb;
    _forwardButton = btnFwd;
    _editButton = btnEdit;
    
    [btnBack release];
    [btnHint release];
    [btnHintItem release];
    [btnBackItem release];
    
    [self updateBarButtons];
    
    // Let the user click on the image view
    _iconImageView.userInteractionEnabled = TRUE;
    _iconTapGestureRecognizer =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [_iconImageView addGestureRecognizer:_iconTapGestureRecognizer];
    
    // Build the auto complete view
    _autoCompleteTableView = [[[UITableView alloc] initWithFrame:
                               CGRectMake(0, 80, 310, 120) style:UITableViewStylePlain] retain];
    _autoCompleteTableView.delegate = self;
    _autoCompleteTableView.dataSource = self;
    _autoCompleteTableView.scrollEnabled = YES;
    _autoCompleteTableView.hidden = YES;
    _autoCompleteTableView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.25f];
    _autoCompleteTableView.backgroundView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.25f];
    
    _autoCompleteTableView.layer.borderWidth = 2;
    _autoCompleteTableView.layer.borderColor = [[UIColor blueColor] CGColor];
    _autoCompleteTableView.layer.cornerRadius = 8;
    
    [self.view addSubview:_autoCompleteTableView];
    
    // Create toolbar for over the top of the keyboard... used for UITextView since we don't have a done
    // button, but instead use the return key for new lines...
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    NSString* buttonTitle = [[Strings sharedInstance] lookupString:@"doneButton"];
    UIToolbar* doneToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, screenWidth, 40)];
    doneToolbar.barStyle = UIBarStyleBlackTranslucent;
    doneToolbar.items = [NSArray arrayWithObjects:
                         [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStylePlain target:self action:@selector(doneWithKeyboard)],
                         nil];
    [doneToolbar sizeToFit];
    _notesTextView.inputAccessoryView = doneToolbar;
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [super viewDidUnload];
    
    [_iconImageView removeGestureRecognizer:_iconTapGestureRecognizer];
    [_iconTapGestureRecognizer release];
    [_autoCompleteTableView release];
    [_webButton release];
    [_forwardButton release];
    [_editButton release];
    [_webButtonItem release];
    [_forwardButtonItem release];
    [_editedButtonItem release];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Setup the notes text view...
    [[_notesTextView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[_notesTextView layer] setBorderWidth:2.3];
    [[_notesTextView layer] setCornerRadius:10];
    [_notesTextView setClipsToBounds: YES];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (pDelegate.mainViewController.LastViewController != pDelegate.mainViewController.IconSelectionViewController &&
        pDelegate.mainViewController.LastViewController != pDelegate.mainViewController.WebViewController &&
        pDelegate.mainViewController.LastViewController != pDelegate.mainViewController.PasswordGenerateViewController)
    {
        // Reset text on textfields...
        [_categoryTextField setText:@""];
        [_titleTextField setText:@""];
        [_userNameTextField setText:@""];
        [_passwordTextField setText:@""];
        [_urlTextField setText:@""];
        [_accountTextField setText:@""];
        [_notesTextView setText:_notesTextViewPlaceHolderText];
        [_notesTextView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
        _iconImageView.image = [UIImage imageNamed:@"StopIcon.png"];
        
        [_selectedIcon release];
        _selectedIcon = [[NSString stringWithString:@""] retain];
    }
    else if (pDelegate.mainViewController.LastViewController == pDelegate.mainViewController.IconSelectionViewController)
    {        
        IconSelectionViewController* pIconViewController = [pDelegate mainViewController].IconSelectionViewController;
        if ([pIconViewController.ImageNameSelected isEqualToString:@""] == FALSE)
        {
            _iconImageView.image = [UIImage imageNamed:pIconViewController.ImageNameSelected];
            
            if ([pIconViewController.ImageNameSelected isEqualToString:@"StopIcon.png"])
            {
                [_selectedIcon release];
                _selectedIcon = [[NSString stringWithString:@""] retain];
            }
            else
            {
                [_selectedIcon release];
                _selectedIcon = [pIconViewController.ImageNameSelected copy];
            }
        }
        
        if ([_notesTextView.text isEqualToString:_notesTextViewPlaceHolderText])
        {
            [_notesTextView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
        }
    }
    else if (pDelegate.mainViewController.LastViewController == pDelegate.mainViewController.WebViewController ||
             pDelegate.mainViewController.LastViewController == pDelegate.mainViewController.PasswordGenerateViewController)
    {        
        [self applyPasswordVaultItem:_activeItem];
        
        if ([_notesTextView.text isEqualToString:_notesTextViewPlaceHolderText])
        {
            [_notesTextView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
        }
        
        // Apply the new password if we have one
        if (pDelegate.mainViewController.LastViewController == pDelegate.mainViewController.PasswordGenerateViewController) {
        
            // Set the new password
            if ([pDelegate.mainViewController.PasswordGenerateViewController.LastGeneratedPassword isEqualToString:@""] == FALSE) {
                _passwordTextField.text = pDelegate.mainViewController.PasswordGenerateViewController.LastGeneratedPassword;
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    // Reset the scrollview
    [_scrollView setContentOffset:CGPointZero];
    
    _categoryTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _accountTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _userNameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [self setupLabels];
    
    _categoryLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"categoryLabel"]];
    _titleLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"titleLabel"]];
    _accountLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"accountLabel"]];
    _usernameLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"usernameLabel"]];
    _passwordLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"passwordLabel"]];
    _urlLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"urlLabel"]];
    _notesLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"notesLabel"]];
    _iconLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"iconLabel"]];
    _tapIconLabel.text = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"tapIconLabel"]];
    
    // Adjust title view
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"editVaultItemViewController"
                                 withMaxWidth:90.0f
                              andIsLargeTitle:FALSE
                                 andAlignment:NSTextAlignmentLeft];
    
    // begin the auto-lock timeout
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the view will disapper
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)setupLabels
{
    // Category label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_categoryLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"categoryLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _categoryLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"categoryLabel"]];
    
    // Title label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_titleLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"titleLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _titleLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"titleLabel"]];
    
    // Account label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_accountLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"accountLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _accountLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"accountLabel"]];
    
    // Username label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_usernameLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"usernameLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _usernameLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"usernameLabel"]];
    
    // Password label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_passwordLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"passwordLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _passwordLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"passwordLabel"]];
    
    // URL label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_urlLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"urlLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _urlLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"urlLabel"]];
    
    // Notes label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_notesLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"notesLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _notesLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"notesLabel"]];
    
    // Icon label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_iconLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"iconLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _iconLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"iconLabel"]];
    
    // TapIcon label
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_tapIconLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"tapIconLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    _tapIconLabel.text = [NSString stringWithFormat:@" %@", [[Strings sharedInstance] lookupString:@"tapIconLabel"]];
    
    
    [[Utility sharedInstance] determineAndSetFontForTextfield:_categoryTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextfield:_titleTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextfield:_accountTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextfield:_userNameTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextfield:_passwordTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextfield:_urlTextField withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textfieldTextWidth andIsTip:FALSE];
    [[Utility sharedInstance] determineAndSetFontForTextview:_notesTextView withText:@"TEST STRING TEST STRING TEST" andMaxWidth:[Utility sharedInstance].textviewTextWidth andIsTip:FALSE];
}

// Updates the bar buttons based on the active item
-(void)updateBarButtons
{
    NSArray* rightButtonArray = nil;
    if ([_urlTextField.text length] > 0)
    {
        rightButtonArray = [NSArray arrayWithObjects:_forwardButtonItem, _webButtonItem, _editedButtonItem, nil];
    }
    else
    {
        rightButtonArray = [NSArray arrayWithObjects:_editedButtonItem, nil];
    }
    self.navigationItem.rightBarButtonItems = rightButtonArray;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Handle when we scroll the scroll view
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

-(IBAction)handleNavigationForwardButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if ([self hasChanges])
    {
        [self showForwardHasChangesAlert];
    }
    else
    {
        [_activeTextField resignFirstResponder];
        [_notesTextView resignFirstResponder];
        
        AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        WebViewController* pWebViewController = [pDelegate mainViewController].WebViewController;
        [[pDelegate navigationController] pushViewController:pWebViewController animated:YES];
    }
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the back button is clicked
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if ([self hasChanges])
    {
        [self showBackHasChangesAlert];
    }
    else
    {
        [_activeTextField resignFirstResponder];
        [_notesTextView resignFirstResponder];
    
        _activeItem = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the user clicks the edit button and we want to display
// an action sheet for use
-(IBAction)handleNavigationEditButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIActionSheet *actionSheet = nil;
    
    NSString* cancelButton = [[Strings sharedInstance] lookupString:@"cancelButton"];
    NSString* submitButton = [[Strings sharedInstance] lookupString:@"submitButton"];
    NSString* deleteButton = [[Strings sharedInstance] lookupString:@"deleteButton"];
    
    if ([self hasChanges]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelButton
                                    destructiveButtonTitle:deleteButton
                                         otherButtonTitles:submitButton, nil];
        
        UIColor* color = [UIColor colorWithRed:0.1255f green:0.5490f blue:0.1608f alpha:1.0f];
        [[Utility sharedInstance] adjustActionSheetButtonColor:actionSheet withButtonTitle:submitButton andColor:color];
    }
    else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelButton
                                    destructiveButtonTitle:deleteButton
                                         otherButtonTitles:nil];
    }
    
    // store the active sheet
    _activeActionSheet = actionSheet;
    
    // show the action sheet
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the user presses the web button
-(IBAction)handleNavigationWebButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if ([self hasChanges])
    {
        [self showWebHasChangesAlert];
    }
    else
    {
        [_activeTextField resignFirstResponder];
        [_notesTextView resignFirstResponder];
        
        // animate to the new vault view controller...
        AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        WebViewController* pWebViewController = [pDelegate mainViewController].WebViewController;
        [[pDelegate navigationController] pushViewController:pWebViewController animated:YES];
        
        // Load the web page for this item
        // Schedule this after a delay to ensure that the UIWebView has been created within
        // the WebViewController
        [pWebViewController performSelector:@selector(loadPage:) withObject:_urlTextField.text afterDelay:0.15f];
    }
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the user closes the action sheet
-(void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    switch (buttonIndex)
    {
        // The user decided to delete the item
        case 0:
            {
                // show this with a delay to prevent the alert from slightly budging
                [self performSelector:@selector(showAreYouSureAlert) withObject:nil afterDelay:0.10f];
            }
            break;
        // the user chose to submit the item
        case 1:
            {
                // if we have no changes then button 1 is the cancel button
                if ([self hasChanges] == FALSE) {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    //_activeItem = nil;
                    [self.navigationController popViewControllerAnimated:YES];
                    break;
                }
                else {
                    
                    // Validate that we have the correct fields set
                    if (_categoryTextField.text.length == 0 || _titleTextField.text.length == 0)
                    {
                        // show this with a delay to prevent the alert from slightly budging
                        [self performSelector:@selector(showInvalidFieldAlert) withObject:nil afterDelay:0.10f];
                        break;
                    }
                    
                    [self performSelector:@selector(showConfirmChangesAlert) withObject:nil afterDelay:0.10f];
                }
            }
            break;
        // The user decided to cancle the item
        case 2:
            if ([self hasChanges])
            {
                [self performSelector:@selector(showCancelHasChangesAlert) withObject:nil afterDelay:0.10f];
            }
            else
            {
                [_activeTextField resignFirstResponder];
                [_notesTextView resignFirstResponder];
                
                //_activeItem = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            break;
    }
}

// shows the invalid field alert dialog
-(void)showInvalidFieldAlert
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertEditInvalidFieldTitle"];
    NSString* message = [[Strings sharedInstance] lookupString:@"alertEditInvalidField"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    _currentAlertType = kAlertType_InvalidField;
}

// shows the are you sure dialog
-(void)showAreYouSureAlert
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertEditAreYouSureDeleteTitle"];
    NSString* message = [NSString stringWithFormat:
                         [[Strings sharedInstance] lookupString:@"alertEditAreYouSureDelete"], _activeItem.title];

    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"deleteButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _currentAlertType = kAlertType_AreYouSureAlert;
}

// shows the alert for confimring submission of changes
-(void)showConfirmChangesAlert
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertEditConfirmChangesTitle"];
    NSString* message = [NSString stringWithFormat:
                         [[Strings sharedInstance] lookupString:@"alertEditConfirmChanges"], _activeItem.title];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"applyButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _currentAlertType = kAlertType_ConfirmChanges;
}

// Show the cancel has change alert
-(void)showCancelHasChangesAlert
{
    [self createChangesAlert];
    _currentAlertType = kAlertType_CancelHasChanges; 
}

// Show the cancel has change alert
-(void)showBackHasChangesAlert
{
    [self createChangesAlert];
    _currentAlertType = kAlertType_BackHasChanges; 
}

// Show the cancel has change alert
-(void)showWebHasChangesAlert
{
    [self createChangesAlert];
    _currentAlertType = kAlertType_WebHasChanges; 
}

-(void)showForwardHasChangesAlert
{
    [self createChangesAlert];
    _currentAlertType = kAlertType_ForwardHasChanges;
}

// Show the you have changes alert
-(void)createChangesAlert
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertEditUnsubmittedChangesTitle"];
    NSString* message = [[Strings sharedInstance] lookupString:@"alertEditUnsubmittedChanges"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"proceedButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    _currentAlertType = kAlertType_UnsubmittedChanges;
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    switch (_currentAlertType)
    {
        case kAlertType_ConfirmChanges:
            {
                // the user cancelled, do nothing
                if (buttonIndex == 0) {
                
                }
                else if (buttonIndex == 1) {

                    // retain a ref before deleting
                    [_activeItem retain];
                    
                    [[PasswordVault sharedInstance] removeItem:_activeItem];
                    
                    NSString* curNotes = _notesTextView.text;
                    if ([curNotes isEqualToString:_notesTextViewPlaceHolderText]) {
                        curNotes = @"";
                    }
                    
                    // Create the vault item
                    PasswordVaultItem* item = [PasswordVaultItem passwordVaultItem];
                    [item setCategory:_categoryTextField.text];
                    [item setTitle:_titleTextField.text];
                    [item setUrl:_urlTextField.text];
                    [item setUsername:_userNameTextField.text];
                    [item setPassword:_passwordTextField.text];
                    [item setNotes:curNotes];
                    [item setIcon:_selectedIcon];
                    [item setAccount:_accountTextField.text];
                    
                    // apply the update to the item
                    [self updatePasswordVaultItem];
                    
                    // Add the item to the vault
                    [[PasswordVault sharedInstance] addItem:_activeItem];
                    
                    [_activeItem release];
                    
                    [self updateBarButtons];
                    
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            break;
        case kAlertType_AreYouSureAlert:
            {
                // the user cancelled, do nothing
                if (buttonIndex == 0)
                {
                }
                // try to load the vault file selected with the password given
                else if (buttonIndex == 1)
                {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    [[PasswordVault sharedInstance] removeItem:_activeItem];
                    _activeItem = nil;
                    
                    [self.navigationController popViewControllerAnimated:YES];
                    
                    // begin the auto-lock timeout
                    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
                }
            }
            break;
        case kAlertType_CancelHasChanges:
            {
                // the user cancelled, do nothing
                if (buttonIndex == 0)
                {
                }
                // try to load the vault file selected with the password given
                else if (buttonIndex == 1)
                {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    _activeItem = nil;
                    
                    [self.navigationController popViewControllerAnimated:YES];
                    
                    // begin the auto-lock timeout
                    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
                }
            }
            break;
        case kAlertType_WebHasChanges:
            {   
                // the user cancelled, do nothing
                if (buttonIndex == 0)
                {
                }
                // proceed on to the web
                else if (buttonIndex == 1)
                {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    // animate to the new vault view controller...
                    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    WebViewController* pWebViewController = [pDelegate mainViewController].WebViewController;
                    [[pDelegate navigationController] pushViewController:pWebViewController animated:YES];
                    
                    // Load the web page for this item
                    // Schedule this after a delay to ensure that the UIWebView has been created within
                    // the WebViewController
                    [pWebViewController performSelector:@selector(loadPage:) withObject:_urlTextField.text afterDelay:0.15f];

                    // begin the auto-lock timeout
                    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
                }
            }
            break;
        case kAlertType_BackHasChanges:
            {
                // the user cancelled do nothing...
                if (buttonIndex == 0)
                {
                }
                else if (buttonIndex == 1)
                {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    _activeItem = nil;
                    [self.navigationController popViewControllerAnimated:YES];
                    
                    // begin the auto-lock timeout
                    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
                }
            }
            break;
        case kAlertType_ForwardHasChanges:
            {
                // the user cancelled do nothing...
                if (buttonIndex == 0)
                {
                }
                else if (buttonIndex == 1)
                {
                    [_activeTextField resignFirstResponder];
                    [_notesTextView resignFirstResponder];
                    
                    // animate to the new vault view controller...
                    WebViewController* pWebViewController = [pDelegate mainViewController].WebViewController;
                    [[pDelegate navigationController] pushViewController:pWebViewController animated:YES];
                    
                    // begin the auto-lock timeout
                    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];

                    
                }
            }
            break;
        case kAlertType_Hint:
        {
            
        }
        default:
            break;
    }
}


// Handle pressing the return key or done button on the textfield's
-(IBAction)textFieldPressDone:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UITextField* textField = (UITextField*)sender;
    [textField resignFirstResponder];
}

// Handle the user clicking on a text field
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeTextField = textField;
    
    if (_notesTextView.text.length == 0)
    {
        _notesTextView.text = _notesTextViewPlaceHolderText;
        [_notesTextView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
    }
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the user is done editing a textfield
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    _activeTextField = nil;
    
    // handle enabling the web button or not
    if (textField == _urlTextField)
    {
        [self updateBarButtons];
    }
}

// Handle when the textview is about to first begin editing
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:_notesTextViewPlaceHolderText])
    {
        [textView setText:@""];
    }
}

// Handle how we should change the text based on what the input is
-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length == 1 && [string isEqualToString:@""])
    {
        textField.text = @"";
        //[textField resignFirstResponder];
    }
    
    [self setupAutoComplete:string withTextField:textField andRange:range];
    return TRUE;
}

// Handle when the text view is done editing
-(void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:_notesTextViewPlaceHolderText] || [NSString isEmptyOrNull:textView.text]) {
        [textView setText:_notesTextViewPlaceHolderText];
        [textView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
    }
    else {
        [textView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];
    }
}

// Handle people pressing the done button and the retuen key...
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView.text.length == 1 && [text isEqualToString:@""])
    {
//        [textView setText:_notesTextViewPlaceHolderText];
//        [textView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
//        [textView resignFirstResponder];
    }
    
    // If the user presses the return key then end their editing adventures
    if ([text isEqualToString:@"\n"]) 
    {
        /*[textView resignFirstResponder];
        
        // If there is no text then so the placeholder...
        if ([textView.text isEqualToString:@""])
        {
            [textView setText:_notesTextViewPlaceHolderText];
            [textView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
        }
        return FALSE;*/
        return TRUE;
    }
    // If we have entered the placeholder string then shwo it
    else if ([text isEqualToString:_notesTextViewPlaceHolderText])
    {
        return TRUE;
    }
    // Otherwise reset the text when we type and the placeholder is visible
    else if ([textView.text isEqualToString:@""])
    {
        [textView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];
    }
    return TRUE;
}

// Handle setting up the auto complete data
-(void)setupAutoComplete:(NSString*)string withTextField:(UITextField*)textField andRange:(NSRange)range
{
    // Respond to the user entering text or deleting a character by checking range.length
    if ([string isEqualToString:@""] == FALSE || (range.location > 0 && range.length == 1))
    {
        NSMutableArray* autoStrings = nil;
        NSString* substring = nil;
        BOOL validTextField = NO;
        
        // Handle category auto complete
        if (textField == _categoryTextField)
        {
            _autoCompleteType = kAutoCompleteType_Category;
            validTextField = YES;
        }
        else if (textField == _titleTextField)
        {
            _autoCompleteType = kAutoCompleteType_Title;
            validTextField = YES;
        }
        else if (textField == _userNameTextField)
        {
            _autoCompleteType = kAutoCompleteType_Username;
            validTextField = YES;
        }
        
        // if we have a supported text field then set that up
        if (validTextField == YES)
        {
            substring = [NSString stringWithString:textField.text];
            substring = [substring stringByReplacingCharactersInRange:range withString:string];
            autoStrings = [[[PasswordVault sharedInstance] getAutoCompleteStrings:_autoCompleteType] retain];
            
            _autoCompleteTableView.hidden = [autoStrings count] == 0;
            [self searchAutocompleteEntriesWithSubstring:substring withData:autoStrings];
            [autoStrings release];
        }
    }
}

// Handle when the user clicks on the textfield
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    static const float kTopOffset = 111.0f;
    
    _autoCompleteTableView.hidden = TRUE;
    
    // scroll the text field to the top of the screen
    CGPoint pt;
    CGRect bounds = [textField bounds];
    bounds = [textField convertRect:bounds toView:_scrollView];
    pt = bounds.origin;
    pt.x = 0;
    pt.y -= kTopOffset;
    [_scrollView setContentOffset:pt animated:YES];
    
    return TRUE;
}

// Handle when the user clicks on the textview
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    static const float kTopOffset = 111.0f;
    
    _autoCompleteTableView.hidden = TRUE;
    
    // scroll the text field to the top of the screen
    CGPoint pt;
    CGRect bounds = [textView bounds];
    bounds = [textView convertRect:bounds toView:_scrollView];
    pt = bounds.origin;
    pt.x = 0;
    pt.y -= kTopOffset;
    [_scrollView setContentOffset:pt animated:YES];
    
    return TRUE;
}

// Callback when the keyboard will appear
-(void)keyboardWillShow:(NSNotification*)notification
{
    static const float kDefaultOffset = 8.0f;
    static const float kTopOffset = 111.0f;
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    if (keyboardShown2)
    {
        return;
    }
    
    // Store the content offset for future use
    _scrollOffset = _scrollView.contentOffset;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    if (_activeTextField != nil)
    {
//        CGRect aRect = self.view.frame;
//        aRect.size.height -= kbSize.height + _activeTextField.frame.size.height + kDefaultOffset;
//        CGPoint origin = _activeTextField.frame.origin;
//        origin.y -= _scrollView.contentOffset.y;
//        
//        if (!CGRectContainsPoint(aRect, origin)) 
//        {
//            CGPoint scrollPoint = CGPointMake(0.0, _activeTextField.frame.origin.y-(aRect.size.height)); 
//            [_scrollView setContentOffset:scrollPoint animated:YES];
//        }
        
        // scroll the text field to the top of the screen
        CGPoint pt;
        CGRect bounds = [_activeTextField bounds];
        bounds = [_activeTextField convertRect:bounds toView:_scrollView];
        pt = bounds.origin;
        pt.x = 0;
        pt.y -= kTopOffset;
        [_scrollView setContentOffset:pt animated:YES];
    }
    // The only UI we have that is not a textfield
    // is our notes textview... so if the activeField
    // is nil then we know that we want to use the
    // _notesTextView
    else
    {
//        CGRect aRect = self.view.frame;
//        aRect.size.height -= kbSize.height + _notesTextView.frame.size.height + kDefaultOffset;
//        CGPoint origin = _notesTextView.frame.origin;
//        origin.y -= _scrollView.contentOffset.y;
//        
//        if (!CGRectContainsPoint(aRect, origin)) 
//        {
//            CGPoint scrollPoint = CGPointMake(0.0, _notesTextView.frame.origin.y-(aRect.size.height)); 
//            [_scrollView setContentOffset:scrollPoint animated:YES];
//        }
        
        CGPoint pt;
        CGRect bounds = [_notesTextView bounds];
        bounds = [_notesTextView convertRect:bounds toView:_scrollView];
        pt = bounds.origin;
        pt.x = 0;
        pt.y -= kTopOffset;
        [_scrollView setContentOffset:pt animated:YES];

    }
    
    keyboardShown2 = TRUE;
}

// Handle when the keyboard will be shown
-(void)keyboardWillHide:(NSNotification*)notification
{
    _autoCompleteTableView.hidden = TRUE;
    
    [_scrollView setContentOffset:_scrollOffset animated:YES];
    keyboardShown2 = FALSE;
}

// Hide keyboard on tap
-(IBAction)dismissKeyboardOnTap:(id)sender
{
    [[self view] endEditing:YES];
}

// Handle the search for auto complete
-(void)searchAutocompleteEntriesWithSubstring:(NSString *)substring withData:(NSMutableArray*)data
{
    [_autoCompleteData removeAllObjects];
    
    for (NSString* autoString in data)
    {
        NSRange substringRange = [autoString rangeOfString:substring options:NSCaseInsensitiveSearch];
        
        if (substringRange.location == 0)
        {
            [_autoCompleteData addObject:autoString];
        }
    }
    
    // if we have no matches then hide the table view
    if ([_autoCompleteData count] == 0)
    {
        _autoCompleteTableView.hidden = YES;
    }
    // Since we are showing the table view then set its position
    // so that it sits right below the textfield it is working with
    else
    {
        _autoCompleteTableView.hidden = NO;
        
        CGRect frame;
        switch (_autoCompleteType)
        {
            case kAutoCompleteType_Category:    frame = _categoryTextField.frame;   break;
            case kAutoCompleteType_Title:       frame = _titleTextField.frame;      break;
            case kAutoCompleteType_Username:    frame = _userNameTextField.frame;   break;
        }
        
        float maxHeight = MIN(4 * kCellHeight, [_autoCompleteData count] * kCellHeight);
        _autoCompleteTableView.frame = CGRectMake(0, frame.origin.y + frame.size.height + 8, 320, maxHeight);
        
        // rebuild the table with the new data
        [_autoCompleteTableView reloadData];
    }
}

// Applies the values of the password vault item to the fields
-(void)applyPasswordVaultItem:(PasswordVaultItem*)item
{
    _activeItem = item;
    
    _categoryTextField.text = item.category;
    _titleTextField.text = item.title;
    _urlTextField.text = item.url;
    _userNameTextField.text = item.username;
    _passwordTextField.text = item.password;
    _notesTextView.text = item.notes;
    _accountTextField.text = item.account;
    
    NSLog(@"Icon:%@", item.icon);
    
    if ([item.icon isEqualToString:@""] == TRUE)
    {
        _iconImageView.image = [UIImage imageNamed:@"StopIcon.png"];
    }
    else
    {
        _iconImageView.image = [UIImage imageNamed:item.icon];
        [_selectedIcon release];
        _selectedIcon = [item.icon copy];
    }
    
    // set the placeholder text
    if (_notesTextView.text.length == 0)
    {
        _notesTextView.text = _notesTextViewPlaceHolderText;
    }
    
    // set the text view color correctly when applying the notes
    if (item.notes.length > 0 && [item.notes isEqualToString:_notesTextViewPlaceHolderText] == FALSE)
    {
        [_notesTextView setTextColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];
    }
    
    // handle enabling the web button or not
    [self updateBarButtons];
}

// Applies the textfields to the item
-(void)updatePasswordVaultItem
{
    [_activeItem setCategory:_categoryTextField.text];
    [_activeItem setTitle:_titleTextField.text];
    [_activeItem setUrl:_urlTextField.text];
    [_activeItem setUsername:_userNameTextField.text];
    [_activeItem setPassword:_passwordTextField.text];
    [_activeItem setIcon:_selectedIcon];
    [_activeItem setAccount:_accountTextField.text];
    
    if ([_notesTextView.text isEqualToString:_notesTextViewPlaceHolderText] == FALSE)
    {
        [_activeItem setNotes:_notesTextView.text];
    }
    else
    {
        [_activeItem setNotes:@""];
    }
}

// detect changes on the item
-(BOOL)hasChanges
{
    if (_activeItem == nil)
    {
        return FALSE;
    }
    else if ([_activeItem.category isEqualToString:_categoryTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if ([_activeItem.title isEqualToString:_titleTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if ([_activeItem.account isEqualToString:_accountTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if ([_activeItem.username isEqualToString:_userNameTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if ([_activeItem.password isEqualToString:_passwordTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if ([_activeItem.url isEqualToString:_urlTextField.text] == FALSE)
    {
        return TRUE;
    }
    else if (([_activeItem.notes isEqualToString:_notesTextView.text] == FALSE) &&
             ([_activeItem.notes isEqualToString:@""] == FALSE ||
              [_notesTextView.text isEqualToString:_notesTextViewPlaceHolderText] == FALSE))

    {
        return TRUE;
    }
    else if ([_activeItem.icon isEqualToString:_selectedIcon] == FALSE)
    {
        return TRUE;
    }
    return FALSE;
}

// Handle tap callback for the image view
-(void)handleTap:(UITapGestureRecognizer*)sender 
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (sender.view == _iconImageView)
    {
        [_activeTextField resignFirstResponder];
        [_notesTextView resignFirstResponder];
        
        // animate to the new vault view controller...
        AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        IconSelectionViewController* pIconViewController = [pDelegate mainViewController].IconSelectionViewController;
        [[pDelegate navigationController] pushViewController:pIconViewController animated:YES];
    }
}

// Handles generating an automatic password
-(IBAction)generatePassword:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    //    NSString* result = [[PasswordVault sharedInstance] populatePassword];
    //
    //    // set the text for the password
    //    _passwordTextField.text = result;
    
    // Push the password generate page for creating a password
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    PasswordGenerateViewController* pPasswordViewController = [pDelegate mainViewController].PasswordGenerateViewController;
    [[pDelegate navigationController] pushViewController:pPasswordViewController animated:YES];
}

// Table view delegate method
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell* cell = nil;
    static NSString* autoCompleteRowIdentifier = @"AutoCompleteRowIdentifier";
    
    cell = [tableView dequeueReusableCellWithIdentifier:autoCompleteRowIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:autoCompleteRowIdentifier] autorelease];
        cell.backgroundColor = [UIColor colorWithRed:0.2862f green:0.5765f blue:0.8902f alpha:0.3f];
    }
    
    int row = indexPath.row;
    int count = [_autoCompleteData count];
    if (row < count)
    {
        cell.textLabel.text = [_autoCompleteData objectAtIndex:row];
    }
    else
    {
        cell.textLabel.text = @"";
    }
    return cell;
}

// Returns the number of rows we should have based on the table view
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (_autoCompleteType)
    {
        case kAutoCompleteType_Category:
        case kAutoCompleteType_Title:
        case kAutoCompleteType_Username:
        {
            return [_autoCompleteData count];
        }
    }
    return 0;
}

// Handle selecting an object from the table view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    switch (_autoCompleteType)
    {
        case kAutoCompleteType_Category:
        {
            _categoryTextField.text = selectedCell.textLabel.text;
            [_categoryTextField resignFirstResponder];
            break;
        }
        case kAutoCompleteType_Title:
        {
            _titleTextField.text = selectedCell.textLabel.text;
            [_titleTextField resignFirstResponder];
            break;
        }
        case kAutoCompleteType_Username:
        {
            _userNameTextField.text = selectedCell.textLabel.text;
            [_userNameTextField resignFirstResponder];
            break;
        }
    }
    
    _autoCompleteTableView.hidden = YES;
}

// Returns the height of a table view cell
-(float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return kCellHeight;
}

// Dismiss the keyboard for notes
-(void)doneWithKeyboard
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_notesTextView resignFirstResponder];
}

-(IBAction)handleHintButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [[Strings sharedInstance] lookupString:@"editVaultItemViewControllerHint"];
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
