//
//  NewVaultViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "PasswordGenerateViewController.h"
#import "PasswordVault.h"
#import "PasswordVaultViewController.h"
#import "Strings.h"
#import "Utility.h"
#import "QuartzCore/QuartzCore.h"

static const float kPasswordLengthMin = 6.0f;
static const float kPasswordLengthMax = 24.0f;
static const float kPasswordLengthDefault = 15.0f;
static const float kPasswordLengthLabelSize = 16.0f;
static const float kWeakPasswordPercent = 0.45f;
static const float kStrongPasswordPercent = 0.85f;
static const int kStrongPasswordLength = 15;
static const int kStrongPasswordLengthWithUseAll = 10;
static const int kSymbolOnlyWeakPasswordLength = 7;

@implementation PasswordGenerateViewController

@synthesize LastGeneratedPassword = _lastGeneratedPassword;

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _lastGeneratedPassword = [@"" retain];
        _passwordLength = 0;
        _weakColor = [[UIColor colorWithRed:237.0f/255.0f green:93.0f/255.0f blue:74.0f/255.0f alpha:1.0f] retain];
        _okayColor = [[UIColor colorWithRed:237.0f/255.0f green:226.0f/255.0f blue:74.0f/255.0f alpha:1.0f] retain];
        _strongColor = [[UIColor colorWithRed:140.0f/255.0f green:237.0f/255.0f blue:158.0f/255.0f alpha:1.0f] retain];
    }
    return self;
}

// custom delete routine
-(void)dealloc
{
    [_lastGeneratedPassword release];
    [_weakColor release];
    [_okayColor release];
    [_strongColor release];
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
    
    UIImage* thumbImage = [[Utility sharedInstance] resizeImage:[UIImage imageNamed:@"SliderThumb1.png"] withSize:CGSizeMake(32.0f, 32.0f)];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
        
    _passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    
    // Build dynamic length label to move with the slider thumb image
    _passwordLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kPasswordLengthLabelSize, kPasswordLengthLabelSize)];
    _passwordLengthLabel.font = [UIFont fontWithName:[Utility sharedInstance].primaryFontName size:12.0f];
    _passwordLengthLabel.text = [NSString stringWithFormat:@"%d", _passwordLength];
    _passwordLengthLabel.numberOfLines = 1;
    _passwordLengthLabel.adjustsFontSizeToFitWidth = TRUE;
    _passwordLengthLabel.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
    _passwordLengthLabel.textColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    _passwordLengthLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_passwordLengthLabel];
    
    [_useNumberSwitch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
    [_useLetterSwitch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
    [_useSymbolSwitch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
    [_useUppercaseSwitch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
    [_useLowercaseSwitch addTarget:self action:@selector(switchToggled:) forControlEvents: UIControlEventTouchUpInside];
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
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"passwordGenerateViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    [[Utility sharedInstance] determineAndSetFontForTextfield:_passwordTextField
                                                  withText:[[Strings sharedInstance] lookupString:@"generatePasswordButton"]
                                               andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                  andIsTip:FALSE];
    
    _passwordTextField.text = @"";
    _passwordTextField.userInteractionEnabled = NO;
    _passwordTextField.backgroundColor = [UIColor whiteColor];
    
    [[Utility sharedInstance] determineAndSetFontForButton:_generateButton
                                                      withText:[[Strings sharedInstance] lookupString:@"generatePasswordButton"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [_generateButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [_generateButton titleLabel].text = [[Strings sharedInstance] lookupString:@"generatePasswordButton"];
    [_generateButton setTitle:[[Strings sharedInstance] lookupString:@"generatePasswordButton"] forState:UIControlStateNormal];
    
    [[Utility sharedInstance] determineAndSetFontForButton:_acceptButton
                                                  withText:[[Strings sharedInstance] lookupString:@"generatePasswordButton"]
                                               andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                  andIsTip:FALSE];
    
    [_acceptButton titleLabel].textAlignment = NSTextAlignmentCenter;
    [_acceptButton titleLabel].text = [[Strings sharedInstance] lookupString:@"acceptButton"];
    [_acceptButton setTitle:[[Strings sharedInstance] lookupString:@"acceptButton"] forState:UIControlStateNormal];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_useLetterLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"useLettersLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_useNumberLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"useNumbersLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_useSymbolLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"useSymbolsLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_useUppercaseLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"useUppercaseLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_useLowercaseLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"useLowercaseLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_minPasswordLabel
                                                      withText:[NSString stringWithFormat:@"%.0f", kPasswordLengthMin]
                                                   andMaxWidth:[Utility sharedInstance].smallLabelTextWidth
                                                      andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_maxPasswordLabel
                                                      withText:[NSString stringWithFormat:@"%.0f", kPasswordLengthMax]
                                                   andMaxWidth:[Utility sharedInstance].smallLabelTextWidth
                                                      andIsTip:FALSE];
    
    _useLetterLabel.text = [[Strings sharedInstance] lookupString:@"useLettersLabel"];
    _useNumberLabel.text = [[Strings sharedInstance] lookupString:@"useNumbersLabel"];
    _useSymbolLabel.text = [[Strings sharedInstance] lookupString:@"useSymbolsLabel"];
    _useUppercaseLabel.text = [[Strings sharedInstance] lookupString:@"useUppercaseLabel"];
    _useLowercaseLabel.text = [[Strings sharedInstance] lookupString:@"useLowercaseLabel"];
    
    [_lastGeneratedPassword release];
    _lastGeneratedPassword = [@"" retain];
    
    [_passwordLengthSlider setValue:kPasswordLengthDefault];
    _passwordLength = [self getCurrentPasswordLength];
    [self updatePasswordLengthLabel];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Handle when the view is about to close
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

// called when switch is toggled
-(void)switchToggled:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// returns the length of the current password to be generated
-(int)getCurrentPasswordLength
{
    return (int)floorf(_passwordLengthSlider.value);
}

// Returns the percentage of the UISlider
-(float)getPasswordSliderPercent
{
    float value = _passwordLengthSlider.value;
    return (value - kPasswordLengthMin) / (kPasswordLengthMax - kPasswordLengthMin);
}

// Moves the label to appear on top of the UISlider
-(void)updatePasswordLengthLabel
{
    CGRect sliderFrame = _passwordLengthSlider.frame;
    float sliderRange = _passwordLengthSlider.frame.size.width - _passwordLengthSlider.currentThumbImage.size.width;
    float sliderOrigin = _passwordLengthSlider.frame.origin.x + (_passwordLengthSlider.currentThumbImage.size.width / 2.0);
    float yPos = sliderFrame.origin.y;
    float xPos = ([self getPasswordSliderPercent] * sliderRange) + sliderOrigin;
    
    // Add in fudge offsets to account for custom thumb image
    yPos += 14.5f;
    xPos -= 8.0f;
    
    _passwordLengthLabel.text = [NSString stringWithFormat:@"%d", [self getCurrentPasswordLength]];
    _passwordLengthLabel.frame = CGRectMake(xPos, yPos, kPasswordLengthLabelSize, kPasswordLengthLabelSize);
}

// The user clicked on the gen password button
-(IBAction)generatePassword:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSMutableString* characterString = [NSMutableString stringWithCString:"" encoding:NSASCIIStringEncoding];

    BOOL useLetters = _useLetterSwitch.on;
    BOOL useNumbers = _useNumberSwitch.on;
    BOOL useSymbols = _useSymbolSwitch.on;
    BOOL useUppercase = _useUppercaseSwitch.on;
    BOOL useLowercase = _useLowercaseSwitch.on;
    BOOL useSymbolsOnly = !useLetters && !useNumbers && useSymbols;
    BOOL useAll = useLetters && useNumbers && useSymbols && useLowercase && useUppercase;
    BOOL useLettersOnly = useLetters && !useNumbers && !useSymbols && ((useUppercase && !useLowercase) || (!useUppercase && useLowercase));
    BOOL useNumbersOnly = useNumbers && !useLetters && !useSymbols;
    
    if (useLetters) {
        if (useUppercase) {
            [characterString appendString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        }
        if (useLowercase) {
            [characterString appendString:@"abcdefghijklmnopqrstuvwxyz"];
        }
    }
    if (useNumbers) {
        [characterString appendString:@"0123456789"];
    }
    if (useSymbols) {
        [characterString appendString:@"!@#$%&*+-_=?~[]"];
    }
    
    // reset the password strength color
    _passwordTextField.backgroundColor = [UIColor whiteColor];
    _passwordTextField.textColor = [UIColor blackColor];
    
    NSMutableString* generatedPassword = nil;
    int characterLength = characterString.length;
    const char* cCharacterString = [characterString cStringUsingEncoding:NSASCIIStringEncoding];
    BOOL success = FALSE;
    int strength = 0;
    int maxLengthStrength = 6;
    int maxStrength = 11;
    int maxSymbolCount = useSymbolsOnly ? _passwordLength * 2 : 3;

    // iterate until we meet our conditions
    while (!success && characterLength > 0) {
        
        generatedPassword = [NSMutableString stringWithCString:"" encoding:NSASCIIStringEncoding];
        strength = 0;
        
        int lengthRemain = _passwordLength;
        while (lengthRemain > 0) {
            
            int index = rand() % characterLength;
            char charToUse = cCharacterString[index];
            
            [generatedPassword appendString:[NSString stringWithFormat:@"%c", charToUse]];
            
            lengthRemain -= 1;
        }
        
        success = TRUE;
        
        NSCharacterSet* uppercaseSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        NSCharacterSet* lowercaseSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz"];
        NSCharacterSet* numberSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        NSCharacterSet* symbolSet = [NSCharacterSet characterSetWithCharactersInString:@"!@#$%&*+-_=?~[]"];
        
        if (useLetters) {
            if (useUppercase) {
                success &= [generatedPassword rangeOfCharacterFromSet:uppercaseSet].location != NSNotFound;
                strength += 1;
            }
            if (useLowercase) {
                success &= [generatedPassword rangeOfCharacterFromSet:lowercaseSet].location != NSNotFound;
                strength += 1;
            }
        }
        if (useNumbers) {
            success &= [generatedPassword rangeOfCharacterFromSet:numberSet].location != NSNotFound;
            strength += 1;
        }
        if (useSymbols) {
            success &= [generatedPassword rangeOfCharacterFromSet:symbolSet].location != NSNotFound;
            
            // Limit symbol characters used in password to 1-2 characters
            NSArray* array = [generatedPassword componentsSeparatedByCharactersInSet:symbolSet];
            success &= [array count] <= maxSymbolCount;
            strength += 2;
        }
        
        if (useLetters && !useNumbers && _passwordLength >= kStrongPasswordLength - 2) {
            strength -= 1;
        }
        
        if (useLetters && !useSymbols && _passwordLength >= kStrongPasswordLength - 2) {
            strength -= 1;
        }
        
        if (useNumbers && !useSymbols && _passwordLength >= kStrongPasswordLength - 2) {
            strength -= 1;
        }
        
        // add in strength for length of password
        strength += floorf(maxLengthStrength * MIN((float)_passwordLength / (float)(useAll ? kStrongPasswordLengthWithUseAll : kStrongPasswordLength), 1.0f));
    }
    
    // set the generated password
    _passwordTextField.text = generatedPassword != nil ? generatedPassword : @"";
    
    // Override strength value when we only use one type of character for our password
    if (useLettersOnly || useNumbersOnly) {
        strength = (int)((float)maxStrength * kWeakPasswordPercent);
    }
    else if (useSymbolsOnly && _passwordLength <= kSymbolOnlyWeakPasswordLength) {
        strength = (int)((float)maxStrength * kWeakPasswordPercent);
    }
    else if (useSymbolsOnly && _passwordLength > kSymbolOnlyWeakPasswordLength) {
        strength = (int)((float)maxStrength * kWeakPasswordPercent + 0.20f);
    }
    
    // set password strength color
    float percent = (float)strength / (float)maxStrength;
    
    UIColor* color = (percent <= kWeakPasswordPercent ? _weakColor : (percent >= kStrongPasswordPercent ? _strongColor : _okayColor));
    _passwordTextField.backgroundColor = generatedPassword != nil ? color : [UIColor whiteColor];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// the user has accepted the password
-(IBAction)acceptPassword:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [_lastGeneratedPassword release];
    _lastGeneratedPassword = [_passwordTextField.text retain];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// Called when the slider changed length
-(IBAction)sliderAdjusted:(id)sender
{
    _passwordLength = [self getCurrentPasswordLength];
    [self updatePasswordLengthLabel];
}

// Handle when the user clicks on the back button
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
}

// Handle when the user clicks the hint button
-(IBAction)handleHintButton:(id)sender;
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [[Strings sharedInstance] lookupString:@"passwordGenerateViewControllerHint"];
    
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
