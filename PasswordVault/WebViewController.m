//
//  WebViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 1/6/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "EditVaultItemViewController.h"
#import "PasswordVault.h"
#import "Strings.h"
#import "Utility.h"
#import "WebViewController.h"

#import <QuartzCore/QuartzCore.h>

static const float kCheckLoadingTime = 0.1f;

// private functions
@interface WebViewController(Private)
-(void)showSpinner;
-(void)hideSpinner;
-(void)updateBottomToolBar;
-(UIImage*)setImageColor:(UIImage*)image withColor:(UIColor*)color;
@end

@implementation WebViewController

@synthesize webView = _webView;

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _internetConnectionFound = TRUE;
        
        // Register for network status change
        [[NSNotificationCenter defaultCenter] addObserver:self	
                                                 selector:@selector(handleNetworkStatusChange:) 
                                                     name:@"networkStatusChange" 
                                                   object:nil];
    }
    return self;
}

// custom delete method
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_address != nil)
    {
        [_address release];
        _address = nil;
    }
    
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
    self.title = @"Vault Web";
    
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
    
    UIImage* userImage = [[UIImage imageNamed:@"UserIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnU = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnU setBackgroundImage:userImage forState:UIControlStateNormal];
    [btnU addTarget:self action:@selector(handleUsernameButton:) forControlEvents:UIControlEventTouchUpInside];
    btnU.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnUItem = [[UIBarButtonItem alloc] initWithCustomView:btnU];
    
    UIImage* passImage = [[UIImage imageNamed:@"PasswordIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnP = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnP setBackgroundImage:passImage forState:UIControlStateNormal];
    [btnP addTarget:self action:@selector(handlePasswordButton:) forControlEvents:UIControlEventTouchUpInside];
    btnP.frame = CGRectMake(32, 0, 32, 32);
    
    UIBarButtonItem *btnPItem = [[UIBarButtonItem alloc] initWithCustomView:btnP];
    
    NSArray* btnArray = [NSArray arrayWithObjects:btnPItem, btnUItem, nil];
    self.navigationItem.rightBarButtonItems = btnArray;
    NSArray* btnArray2 = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = btnArray2;

    [btnU release];
    [btnP release];
    [btnBack release];
    [btnUItem release];
    [btnPItem release];
    [btnBackItem release];
    
    UIImage* borderImage = [[UIImage imageNamed:@"blank"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    borderImage = [self setImageColor:borderImage withColor:[UIColor colorWithRed:0.0f green:0.35f blue:0.78f alpha:1.0f]];
    
    _imageView = [[UIImageView alloc] initWithImage:borderImage];
    _imageView.layer.cornerRadius = 5.0;
    _imageView.layer.masksToBounds = YES;
    _imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _imageView.layer.borderWidth = 2.0;
    [self.view addSubview:_imageView];
    
    // Create the spinner for the web view
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.color = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    [self.view addSubview:_spinner];
    
    _loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    _loadingLabel.font = [UIFont fontWithName:[Utility sharedInstance].primaryFontName size:14.0f];
    _loadingLabel.text = [[Strings sharedInstance] lookupString:@"loadingStatus"];
    _loadingLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_loadingLabel];
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [_spinner removeFromSuperview];
    [_spinner release];
    [_loadingLabel removeFromSuperview];
    [_loadingLabel release];
    [_imageView removeFromSuperview];
    [_imageView release];
    [super viewDidUnload];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([PasswordVault sharedInstance].internetActive == FALSE)
    {
        // Create a popup to enter the password for the file selected
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Internet Status" 
                                                            message:@"There is currently no reachable internet connection." 
                                                           delegate:self 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
    
    // set the edit mode on the text field
    _webTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
    
    [self updateBottomToolBar];
    
    // update the loading text
    _loadingLabel.text = [[Strings sharedInstance] lookupString:@"loadingStatus"];
    
    // Get the font for textfields used in search bar
    UIFont* font = [pDelegate.mainViewController.PasswordVaultViewController getSearchBarTextfield].font;
    font = [UITextField appearanceWhenContainedIn:[UISearchBar class], nil].font;
    _webTextField.placeholder = [[Strings sharedInstance] lookupString:@"enterWebAddress"];
    
    [[UITextField appearanceWhenContainedIn:[UIToolbar class], nil] setFont:[UIFont fontWithName:font.fontName size:11.0f]];
    [UITextField appearanceWhenContainedIn:[UIToolbar class], nil].textColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
    [UITextField appearanceWhenContainedIn:[UIToolbar class], nil].tintColor = [UIColor blueColor];

    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"webViewController"
                                 withMaxWidth:160.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
}

// Handle when the view will disapper
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
}

// Handle auto rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Handle when text is being entered
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the back button is clicked
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// Loads a web page based on the address given
-(void)loadPage:(NSString *)address
{
    if (_address != nil)
    {
        [_address release];
        _address = nil;
    }
    
    // store the address in the case that we fail to load the page
    // and want to try again under a different domain
    _address = [[NSString stringWithString:address] retain];
    
    NSURL* url = [NSURL URLWithString:_address];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
    _triedHttp = FALSE;
    _triedHttps = FALSE;
    
    [self updateBottomToolBar];
}

// get address from webview
-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request 
navigationType:(UIWebViewNavigationType)navigationType 
{
    NSURL *url = [request URL];
    _webTextField.text = [url absoluteString];
    return YES;   
}

// Handle when the webview does not load
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error with code %i and domain %@ and description %@!", [error code], [error domain], [error description]);
    
    // for this error we just ignore it
    if ([error code] == -999)
    {
        return;
    }
    
    NSString* message = [NSString stringWithFormat:@"The address '%@' is invalid, please try again!", _address];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Web View"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView autorelease];
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    // Actually show the alert view
    [alertView show];
}

// Handles when the user is done clicking in the text field
-(IBAction)textFieldPressDone:(id)sender;
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [sender resignFirstResponder];
    [self loadPage:_webTextField.text];
}

// copies the username to the pasteboard
-(IBAction)handleUsernameButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    EditVaultItemViewController* pEditItemViewController = [pDelegate mainViewController].EditVaultItemViewController;
    
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = pEditItemViewController.activeItem.username;
    
    // begin the auto-lock timeout
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// copies the password to the pasteboard
-(IBAction)handlePasswordButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    EditVaultItemViewController* pEditItemViewController = [pDelegate mainViewController].EditVaultItemViewController;
    
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = pEditItemViewController.activeItem.password;
    
    // begin the auto-lock timeout
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// called when the network status changes
-(void)handleNetworkStatusChange:(NSNotification*)notice
{
    if ([PasswordVault sharedInstance].internetActive == FALSE && _internetConnectionFound == TRUE)
    {
        // Create a popup to enter the password for the file selected
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Internet Status" 
                                                            message:@"There is currently no reachable internet connection." 
                                                           delegate:self 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        _internetConnectionFound = FALSE;
    }
    else if ([PasswordVault sharedInstance].internetActive == TRUE && _internetConnectionFound == FALSE)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Internet Status" 
                                                            message:@"An internet connection has been found." 
                                                           delegate:self 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
        
        _internetConnectionFound = TRUE;
    }
}

// Handles the back button
-(IBAction)handleWebBackButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_webView goBack];
    [self updateBottomToolBar];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handles the forward button
-(IBAction)handleWebForwardButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_webView goForward];
    [self updateBottomToolBar];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handles the refresh button
-(IBAction)handleWebRefreshButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_webView reload];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handles the web stop button
-(IBAction)handleWebStopButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_webView stopLoading];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the web view begins a load page
-(void)webViewDidStartLoad:(UIWebView*)webView
{
    [self showSpinner];
}

// Handle when the web view loads a page
-(void)webViewDidFinishLoad:(UIWebView*)webView
{
    [self hideSpinner];
    [self updateBottomToolBar];
}

// Shows the spinner in view
-(void)showSpinner
{
    _spinner.hidden = NO;
    _loadingLabel.hidden = NO;
    _imageView.hidden = NO;
    
    [_spinner startAnimating];
    
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat width = CGRectGetWidth(screen);
    CGFloat height = CGRectGetHeight(screen);
    
    _spinner.center = CGPointMake(width / 2.0f - 38, height / 2.0f);
    _loadingLabel.frame = CGRectMake(width / 2.0f - 24, height / 2.0f - 16, 128, 32);
    _imageView.frame = CGRectMake(width / 2.0f - 192.0f / 2.0f, height / 2.0f - 32.0f, 192.0f, 64.0f);
}

// Hides the spinner from view
-(void)hideSpinner
{
    _spinner.hidden = YES;
    _loadingLabel.hidden = YES;
    _imageView.hidden = YES;
    
    [_spinner stopAnimating];
}

// Update the buttons for the bottom toolbar
-(void)updateBottomToolBar
{
    NSMutableArray* buttons = [NSMutableArray array];
    
    if ([_webView canGoBack]) {
        _backButton.enabled = TRUE;
        _backButton.image = [UIImage imageNamed:@"InternetBackward.png"];
    }
    else {
        _backButton.enabled = FALSE;
        _backButton.image = [UIImage imageNamed:@"InternetBackwardDisabled.png"];
    }
    
    if ([_webView canGoForward]) {
        _forwardButton.enabled = TRUE;
        _forwardButton.image = [UIImage imageNamed:@"InternetForward.png"];
    }
    else {
        _forwardButton.enabled = FALSE;
        _forwardButton.image = [UIImage imageNamed:@"InternetForwardDisabled.png"];
    }

    [buttons addObject:_backButton];
    [buttons addObject:_forwardButton];
    [buttons addObject:_spacer];
    [buttons addObject:_refreshButton];
    [buttons addObject:_stopButton];
    
    [_bottomToolBar setItems:buttons animated:YES];
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
}

-(IBAction)handleHintButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [[Strings sharedInstance] lookupString:@"webViewControllerHint"];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"hintTitle"]
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _currentAlertType = kAlertType_Hint;
}

// Sets the color on a UIImage
-(UIImage*)setImageColor:(UIImage*)image withColor:(UIColor*)color
{
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height));
    
    UIImage* coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

@end
