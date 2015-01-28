//
//  MainViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 11/29/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "PasswordVault.h"
#import "Strings.h"
#import "TipManager.h"
#import "UILabelExtension.h"
#import "Utility.h"
#import "QuartzCore/QuartzCore.h"

static const float tipFadeTime = 0.25f;
static const float tipCycleTime = 10.0f;
static BOOL useFallbackDirectory;
static NSString* fallbackDirectory = @"/Users/dleistiko/Dropbox/My Files/PasswordVault";

// Private functions
@interface MainViewController (Private)
-(void)showNextTip:(NSNumber*)immediate;
-(void)fadeTip:(NSNumber*)fadeOut;
-(void)initializeData:(BOOL)load;
-(void)showLoadingUI:(BOOL)show;
+(void)setCurrentLanguage;
@end

@implementation MainViewController

@synthesize NewVaultButton = _newVaultButton;
@synthesize LoadVaultButton = _loadVaultButton;
@synthesize AutoLockVaultButton = _autoLockVaultButton;
@synthesize SettingsButton = _settingsButton;
@synthesize TipLabel = _tipLabel;
@synthesize LoadingLabel = _loadingLabel;
@synthesize NewVaultViewController = _newVaultViewContoller;
@synthesize LoadVaultViewController = _loadVaultViewController;
@synthesize PasswordVaultViewController = _passwordVaultViewController;
@synthesize AddVaultItemViewController = _addVaultItemViewController;
@synthesize EditVaultItemViewController = _editVaultItemViewController;
@synthesize WebViewController = _webViewController;
@synthesize IconSelectionViewController = _iconSelectionViewController;
@synthesize LastViewController = _lastViewController;
@synthesize AutoLockViewController = _autoLockViewController;
@synthesize SettingsViewController = _settingsViewController;
@synthesize PasswordGenerateViewController = _passwordGenerateViewController;

// This function will not be called currently, since the view controller is set
// as the root view controller of the window.
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        useFallbackDirectory = FALSE;
        
        _lastViewController = nil;
        _hasInitializedData = FALSE;
        
        [[TipManager sharedInstance] init];
    }
    return self;
}

// handle when we receive a low memory warning
-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// custom delete routine
-(void)dealloc
{
    [_newVaultViewContoller removeFromParentViewController];
    [_newVaultViewContoller release];
    [_loadVaultViewController removeFromParentViewController];
    [_loadVaultViewController release];
    [_passwordVaultViewController removeFromParentViewController];
    [_passwordVaultViewController release];
    [_addVaultItemViewController removeFromParentViewController];
    [_addVaultItemViewController release];
    [_editVaultItemViewController removeFromParentViewController];
    [_editVaultItemViewController release];
    [_webViewController removeFromParentViewController];
    [_webViewController release];
    [_iconSelectionViewController removeFromParentViewController];
    [_iconSelectionViewController release];
    [_autoLockViewController removeFromParentViewController];
    [_autoLockViewController release];
    [_settingsViewController removeFromParentViewController];
    [_settingsViewController release];
    [_passwordGenerateViewController removeFromParentViewController];
    [_passwordGenerateViewController release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

// Handle when the view is about to be displayed
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_hasInitializedData == FALSE && ([[Strings sharedInstance] needsTranslation] || [[TipManager sharedInstance] needsTranslation])) {
        [self showLoadingUI:TRUE];
        [self initializeData:TRUE];
        _hasInitializedData = TRUE;
    }
    else {
        [[Strings sharedInstance] buildStrings:FALSE];
        [[TipManager sharedInstance] buildTips:FALSE];
        [MainViewController setCurrentLanguage];
        [self showLoadingUI:FALSE];
        [self refresh];
        [self showNextTip:[NSNumber numberWithBool:TRUE]];
        _hasInitializedData = TRUE;
    }
}

// shows the loading UI or the regular UI
-(void)showLoadingUI:(BOOL)show
{
    self.LoadingLabel.hidden = !show;
    self.TipLabel.hidden = show;
    self.NewVaultButton.hidden = show;
    self.LoadVaultButton.hidden = show;
    self.AutoLockVaultButton.hidden = show;
    self.SettingsButton.hidden = show;
}

// updates the visuals for this view
-(void)refresh
{
    [self.AutoLockViewController cancelAutoLockTimeout];
    
    // load the font from saved prefs
    struct FontInfo fontInfoPrimary = [_settingsViewController getSelectedPrimaryFont];
    struct FontInfo fontInfoTip = [_settingsViewController getSelectedTipFont];
    
    // NOTE: this must occur before we change the primary font
    [_settingsViewController validateFontMetrics:fontInfoPrimary._fontName];
    [_settingsViewController validateFontMetrics:fontInfoTip._fontName];
    
    [[Utility sharedInstance] changePrimaryFont:fontInfoPrimary._fontName withSize:fontInfoPrimary._fontSize];
    [[Utility sharedInstance] changeTipFont:fontInfoTip._fontName withSize:fontInfoTip._fontSize];
    
    // retrieve all vault file names
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // If we have 0 files found then as a fallback look at hardcoded patg
    if ([passwordVaultFiles count] == 0) {
        
        // Determine the fallback directory to use... either accept the command line arg
        // if it exists, otherwise use the hard-coded value at the top of this file
        NSArray* args = [[NSProcessInfo processInfo] arguments];
        NSString* argDir = [args count] > 1 ? (NSString*)[args objectAtIndex:1] : (NSString*)nil;
        
        directory = argDir != nil ? argDir : fallbackDirectory;
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
        
        fallbackDirectory = directory;
        useFallbackDirectory = [passwordVaultFiles count] > 0;
    }
    
    // if we have no vault files then we disable the load vault button
    self.LoadVaultButton.hidden = [passwordVaultFiles count] == 0;
    
    float screenHeight = [UIScreen mainScreen].bounds.size.height;
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGRect loadVaultFrame = CGRectMake(0, 0, 10, 10);
    loadVaultFrame = self.LoadVaultButton.frame;
    
    CGRect newVaultFrame = CGRectMake(0, 0, 10, 10);
    newVaultFrame = self.NewVaultButton.frame;
    
    CGRect autoVaultFrame = CGRectMake(0, 0, 10, 10);
    autoVaultFrame = self.AutoLockVaultButton.frame;
    
    CGRect settingsFrame = CGRectMake(0, 0, 10, 10);
    settingsFrame = self.SettingsButton.frame;
    
    CGRect start = CGRectMake(loadVaultFrame.origin.x, screenHeight + 40, loadVaultFrame.size.width, loadVaultFrame.size.height);
    [[Utility sharedInstance] animateControl:self.LoadVaultButton
                                   withStart:start
                                     withEnd:self.LoadVaultButton.frame
                                    withTime:0.5
                                    andDelay:-1.0f];
    
    CGRect start1 = CGRectMake(-75, newVaultFrame.origin.y, newVaultFrame.size.width, newVaultFrame.size.height);
    [[Utility sharedInstance] animateControl:self.NewVaultButton
                                   withStart:start1
                                     withEnd:self.NewVaultButton.frame
                                    withTime:0.5
                                    andDelay:-1.0f];
    
    CGRect start2 = CGRectMake(screenWidth + 75, autoVaultFrame.origin.y, autoVaultFrame.size.width, autoVaultFrame.size.height);
    [[Utility sharedInstance] animateControl:self.AutoLockVaultButton
                                   withStart:start2
                                     withEnd:self.AutoLockVaultButton.frame
                                    withTime:0.5
                                    andDelay:-1.0f];
    
    CGRect start3 = CGRectMake(settingsFrame.origin.x, -75, settingsFrame.size.width, settingsFrame.size.height);
    [[Utility sharedInstance] animateControl:self.SettingsButton
                                   withStart:start3
                                     withEnd:self.SettingsButton.frame
                                    withTime:0.5
                                    andDelay:-1.0f];
    
    // update buttons
    [[Utility sharedInstance] determineAndSetFontForButton:_newVaultButton
                                                  withText:[[Strings sharedInstance] lookupString:@"newVaultButton"]
                                               andMaxWidth:[Utility sharedInstance].buttonTextWidth andIsTip:FALSE];
    [self.NewVaultButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [self.NewVaultButton titleLabel].text = [[Strings sharedInstance] lookupString:@"newVaultButton"];
    [self.NewVaultButton setTitle:[[Strings sharedInstance] lookupString:@"newVaultButton"] forState:UIControlStateNormal];
    
    [[Utility sharedInstance] determineAndSetFontForButton:_loadVaultButton
                                                  withText:[[Strings sharedInstance] lookupString:@"loadVaultButton"]
                                               andMaxWidth:[Utility sharedInstance].buttonTextWidth andIsTip:FALSE];
    [self.LoadVaultButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [self.LoadVaultButton titleLabel].text = [[Strings sharedInstance] lookupString:@"loadVaultButton"];
    [self.LoadVaultButton setTitle:[[Strings sharedInstance] lookupString:@"loadVaultButton"] forState:UIControlStateNormal];
    
    [[Utility sharedInstance] determineAndSetFontForButton:_autoLockVaultButton
                                                  withText:[[Strings sharedInstance] lookupString:@"autoLockVaultButton"]
                                               andMaxWidth:[Utility sharedInstance].buttonTextWidth andIsTip:FALSE];
    [self.AutoLockVaultButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [self.AutoLockVaultButton titleLabel].text = [[Strings sharedInstance] lookupString:@"autoLockVaultButton"];
    [self.AutoLockVaultButton setTitle:[[Strings sharedInstance] lookupString:@"autoLockVaultButton"] forState:UIControlStateNormal];
    
    [[Utility sharedInstance] determineAndSetFontForButton:_settingsButton
                                                  withText:[[Strings sharedInstance] lookupString:@"settingsButton"]
                                               andMaxWidth:[Utility sharedInstance].buttonTextWidth andIsTip:FALSE];
    [self.SettingsButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [self.SettingsButton titleLabel].text = [[Strings sharedInstance] lookupString:@"settingsButton"];
    [self.SettingsButton setTitle:[[Strings sharedInstance] lookupString:@"settingsButton"] forState:UIControlStateNormal];
    
    // Adjust title view
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"mainViewController"
                                 withMaxWidth:225.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentCenter];
}

// Handle when we are not displaying anymore
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // cancel any scheduled selectors, such as the selector for cycling through tips
    [MainViewController cancelPreviousPerformRequestsWithTarget:self];
    
    _lastViewController = self;
}

// When the view first loads create other view controllers needed for the transfer
-(void)viewDidLoad
{
    // Create the settings first so that we can use the fonts
    _settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    
    // load the font from saved prefs
    struct FontInfo fontInfoPrimary = [_settingsViewController getSelectedPrimaryFont];
    struct FontInfo fontInfoTip = [_settingsViewController getSelectedTipFont];
    
    // NOTE: this must occur before we change the primary font
    [_settingsViewController validateFontMetrics:fontInfoPrimary._fontName];
    [_settingsViewController validateFontMetrics:fontInfoTip._fontName];
    
    [[Utility sharedInstance] changePrimaryFont:fontInfoPrimary._fontName withSize:fontInfoPrimary._fontSize];
    [[Utility sharedInstance] changeTipFont:fontInfoTip._fontName withSize:fontInfoTip._fontSize];
    
    _newVaultViewContoller = [[NewVaultViewController alloc] initWithNibName:@"NewVaultViewController"
                                                                      bundle:nil];
    _loadVaultViewController = [[LoadVaultViewController alloc] initWithNibName:@"LoadVaultViewController" 
                                                                         bundle:nil];
    _passwordVaultViewController = [[PasswordVaultViewController alloc] initWithNibName:@"PasswordVaultViewController" 
                                                                                 bundle:nil];
    _addVaultItemViewController = [[AddVaultItemViewController alloc] initWithNibName:@"AddVaultItemViewController" 
                                                                               bundle:nil];
    _editVaultItemViewController = [[EditVaultItemViewController alloc] initWithNibName:@"EditVaultItemViewController" 
                                                                               bundle:nil];
    _webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" 
                                                             bundle:nil];
    _iconSelectionViewController = [[IconSelectionViewController alloc] initWithNibName:@"IconSelectionViewController"
                                                                                 bundle:nil];
    _autoLockViewController = [[AutoLockViewController alloc] initWithNibName:@"AutoLockViewController" bundle:nil];
    

    
    _passwordGenerateViewController = [[PasswordGenerateViewController alloc] initWithNibName:@"PasswordGenerateViewController" bundle:nil];

    [super viewDidLoad];
}

// Handle when we unload the primary view controller
- (void)viewDidUnload
{
    [_newVaultViewContoller removeFromParentViewController];
    [_newVaultViewContoller release];
    [_loadVaultViewController removeFromParentViewController];
    [_loadVaultViewController release];
    [_passwordVaultViewController removeFromParentViewController];
    [_passwordVaultViewController release];
    [_addVaultItemViewController removeFromParentViewController];
    [_addVaultItemViewController release];
    [_editVaultItemViewController removeFromParentViewController];
    [_editVaultItemViewController release];
    [_webViewController removeFromParentViewController];
    [_webViewController release];
    [_iconSelectionViewController removeFromParentViewController];
    [_iconSelectionViewController release];
    [_settingsViewController removeFromParentViewController];
    [_settingsViewController release];
    [_passwordGenerateViewController removeFromParentViewController];
    [_passwordGenerateViewController release];
    
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Handles switching to the new vault view controller
-(IBAction)handleNewVaultButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // Animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[pDelegate navigationController] pushViewController:self.NewVaultViewController animated:YES];
}

// Handles switching to the load vault view controller
-(IBAction)handleLoadVaultButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // Animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[pDelegate navigationController] pushViewController:self.LoadVaultViewController animated:YES];
}

// Handles switching to the autolock view controller
-(IBAction)handleAutoLockButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // Animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[pDelegate navigationController] pushViewController:self.AutoLockViewController animated:YES];
}

// Handles swapping to the settings page
-(IBAction)handleSettingsButton
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // Animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[pDelegate navigationController] pushViewController:self.SettingsViewController animated:YES];
}

// Accessor function to get fallback dir
+(NSString*)fallbackDirectory
{
    return fallbackDirectory;
}

// Accessor function to check if we should use fallback dir
+(BOOL)useFallbackDirectory
{
    return useFallbackDirectory;
}

// Sets the current language
+(void)setCurrentLanguage
{
    // NOTE:
    // Since this is the first place we get to where we need to use translation
    // set the current language here
    //[[Strings sharedInstance] setCurrentLanguageFromSettings];
    
    // Apply saved language
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    int selectedLang = [[defaults objectForKey:@"SelectedLanguage"] intValue];
    [[Strings sharedInstance] changeCurrentLanguage:(Language)selectedLang];
}

// Attempts to retrieve the next unseen tip and then adjusts the tip label
// for proper formatting and then finally displays the tip by setting the text on the
// tip label.
-(void)showNextTip:(NSNumber*)immediate
{
    if ([immediate boolValue]) {
        
        NSString* tip = [[TipManager sharedInstance] showRandomNextTip:TRUE forLanguage:[Strings sharedInstance].CurrentLanguage];
        [self updateTipLabel:tip];
        
        _tipLabel.alpha = 0.0f;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:tipFadeTime];
        _tipLabel.alpha = 1.0f;
        [UIView commitAnimations];
        
        [self performSelector:@selector(showNextTip:) withObject:[NSNumber numberWithBool:FALSE] afterDelay:tipCycleTime + tipFadeTime];
        
        return;
    }
    
    [self fadeTip:[NSNumber numberWithBool:TRUE]];
  
    // schedule the fade in after the fade out completes
    [self performSelector:@selector(fadeTip:) withObject:[NSNumber numberWithBool:FALSE] afterDelay:tipFadeTime];
    
    // schedule all call to this function in order to cycle through the tips
    [self performSelector:@selector(showNextTip:) withObject:[NSNumber numberWithBool:FALSE] afterDelay:tipCycleTime];
}

// Sets the tip on the label and then updates the label bounds to better
// format the text
-(void)updateTipLabel:(NSString*)tip
{
    NSString* tipFontName = [Utility sharedInstance].tipFontName;
    UIFont* tipFont = [Utility sharedInstance].tipFont;
    
    // reset the font and assign new text
    _tipLabel.font = tipFont;
    _tipLabel.text = [NSString stringWithFormat:@"%@\n%@", [[Strings sharedInstance] lookupString:@"tipTitle"], tip];
    
    const float maxLabelHeight = 110.0f;
    CGSize tipSize = [[Utility sharedInstance] measureString:_tipLabel.text withFont:tipFont];
    float curFontSize = [Utility sharedInstance].tipFontSize;
    int lineCount = ceil(tipSize.width / _tipLabel.frame.size.width);
    float height = lineCount * [[Utility sharedInstance].tipFont lineHeight];
    
    // while the text is too big adjust the font and retry
    while (height >= maxLabelHeight && curFontSize > 5.0f) {
        
        curFontSize -= 1.0f;
        _tipLabel.font = [UIFont fontWithName:tipFontName size:curFontSize];
        tipSize = [[Utility sharedInstance] measureString:_tipLabel.text withFont:tipFont];
        lineCount = ceil(tipSize.width / _tipLabel.frame.size.width);
        height = lineCount * [_tipLabel.font lineHeight];
    }
}

// Handles calling the animation to fade the tip out
-(void)fadeTip:(NSNumber *)fadeOut
{
    BOOL shouldFadeOut = [fadeOut boolValue];
    
    if (shouldFadeOut) {
        _tipLabel.alpha = 1.0f;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:tipFadeTime];
        _tipLabel.alpha = 0.0f;
        [UIView commitAnimations];
    }
    else {
        _tipLabel.alpha = 0.0f;
        
        NSString* tip = [[TipManager sharedInstance] showRandomNextTip:TRUE forLanguage:[Strings sharedInstance].CurrentLanguage];
        [self updateTipLabel:tip];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:tipFadeTime];
        _tipLabel.alpha = 1.0f;
        [UIView commitAnimations];
    }
}

// load strings and tips
-(void)initializeData:(BOOL)load
{
    if (load == TRUE) {
        
        [[Utility sharedInstance] showSpinner:TRUE onView:self.view];
        
        [[Strings sharedInstance] buildStrings:TRUE];
        [[TipManager sharedInstance] buildTips:TRUE];
        
        // check if we have anything translating??
        BOOL processingStrings = [Strings sharedInstance].isLoading;
        BOOL processingTips = [TipManager sharedInstance].isLoading;
        
        // Make it so that we wait here for the loading of the strings to complete
        // before moving on
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^ {
            
            
            while ([[Utility sharedInstance] translateQueuedInfo]) {
                sleep(1/5000);
                
                dispatch_async(dispatch_get_main_queue(),^{
                });
            }
            
            // complete the string translation process
            if (processingStrings) {
                [[Strings sharedInstance] finishTranslations];
            }
            
            // complete the tip translation process
            if (processingTips) {
                [[TipManager sharedInstance] finishTranslations];
            }
            
            // Now that we have completed the translations, update the UI
            // and setup the tip
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                [[Utility sharedInstance] showSpinner:FALSE onView:nil];
                [MainViewController setCurrentLanguage];
                [self showLoadingUI:FALSE];
                [self refresh];
                [self showNextTip:[NSNumber numberWithBool:TRUE]];
            });
        });
    }
}

@end
