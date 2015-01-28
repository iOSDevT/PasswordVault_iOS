//
//  NewVaultViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "Enums.h"
#import "MainViewController.h"
#import "PasswordVault.h"
#import "PasswordVaultViewController.h"
#import "SettingsViewController.h"
#import "Strings.h"
#import "TipManager.h"
#import "Utility.h"
#import "QuartzCore/QuartzCore.h"


static int selectedFont[kLanguage_COUNT] = {};
static int selectedTipFont[kLanguage_COUNT] = {};
static int selectedLanguage = 0;
static int selectedFontSize = 0;

// private functions
@interface SettingsViewController(Private)
-(BOOL)updateSelectedFont:(NSInteger)index initial:(BOOL)initial;
-(BOOL)updateSelectedTipFont:(NSInteger)index;
-(BOOL)updateSelectedFontSize:(NSInteger)index andShouldNavigate:(BOOL)navigate;
-(BOOL)updateSelectedLanguage:(NSInteger)index andShouldNavigate:(BOOL)navigate;
-(void)updateLabels;
-(void)updateTextfieldLabelFonts;
-(UIToolbar*)createPickerToolbar;
-(void)validatePreferences;
@end

@implementation SettingsViewController

// Writes preferences to disk
+(void)savePreferences
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    for (int i = 0; i < kLanguage_COUNT; ++i) {
        NSString* fontKey = [NSString stringWithFormat:@"SelectedFont_%d", i];
        [defaults setInteger:selectedFont[i] forKey:fontKey];
        
        NSString* fontTipKey = [NSString stringWithFormat:@"SelectedTipFont_%d", i];
        [defaults setInteger:selectedTipFont[i] forKey:fontTipKey];
    }

    [defaults setInteger:selectedFontSize forKey:@"SelectedFontSize"];
    
    [defaults synchronize];
}

// Reads preferences and applies them to our selections
+(void)loadPreferences
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    for (int i = 0; i < kLanguage_COUNT; ++i) {
        NSString* fontKey = [NSString stringWithFormat:@"SelectedFont_%d", i];
        selectedFont[i] = [[defaults objectForKey:fontKey] intValue];
        
        NSString* fontTipKey = [NSString stringWithFormat:@"SelectedTipFont_%d", i];
        selectedTipFont[i] = [[defaults objectForKey:fontTipKey] intValue];
    }
    
    [defaults synchronize];
    
    selectedLanguage = [[defaults objectForKey:@"SelectedLanguage"] intValue];
    
    // if we are running for the first time then set font size to medium
    if ([defaults objectForKey:@"SelectedFontSize"] == nil) {
        selectedFontSize = (int)kPrimaryFontSize_Medium;
        
        [defaults setObject:[NSNumber numberWithInt:kPrimaryFontSize_Medium] forKey:@"SelectedFontSize"];
        [defaults synchronize];
    }
    else {
        selectedFontSize = [[defaults objectForKey:@"SelectedFontSize"] intValue];
    }
}

// Return selected font
+(int)getPreferenceFont
{
    return selectedFont[[Strings sharedInstance].CurrentLanguage];
}

// Return selected tip font
+(int)getPreferenceTipFont
{
    return selectedTipFont[[Strings sharedInstance].CurrentLanguage];
}

// return the size adjustment for the font
+(int)getPreferenceFontSize
{
    return selectedFontSize;
}

// Sets the preferred font index
+(void)setPreferenceFont:(int)index
{
    selectedFont[[Strings sharedInstance].CurrentLanguage] = index;
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.SettingsViewController validatePreferences];
}

// sets the preferred tip font index
+(void)setPreferenceTipFont:(int)index
{
    selectedTipFont[[Strings sharedInstance].CurrentLanguage] = index;
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.SettingsViewController validatePreferences];
}

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [SettingsViewController loadPreferences];
        
        _primaryFonts = [[NSMutableDictionary alloc] initWithCapacity:30];
        _tipFonts = [[NSMutableDictionary alloc] initWithCapacity:30];
        _languageInfo = [[EnumHelper getLanguageInfo] retain];
        _fontSizeInfo = [[EnumHelper getFontSizeInfo] retain];

        // Build font lists
        [self buildPrimaryFonts];
        [self buildTipFonts];
        [self validatePreferences];
    }
    return self;
}

// custom delete routine
-(void)dealloc
{
    [_primaryFonts release];
    [_tipFonts release];
    [_languageInfo release];
    [_fontSizeInfo release];
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
    
    [self createPickerToolbar];
    
    _fontPicker.showsSelectionIndicator = TRUE;
    _fontPicker.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:220.0f/255.0f blue:125.0f/255.0f alpha:1.0f];
    _fontTipPicker.showsSelectionIndicator = TRUE;
    _fontTipPicker.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:220.0f/255.0f blue:125.0f/255.0f alpha:1.0f];
    _languagePicker.showsSelectionIndicator = TRUE;
    _languagePicker.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:220.0f/255.0f blue:125.0f/255.0f alpha:1.0f];
    _fontSizePicker.showsSelectionIndicator = TRUE;
    _fontSizePicker.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:220.0f/255.0f blue:125.0f/255.0f alpha:1.0f];
    
    _fontTextfield.inputView = _fontPicker;
    _fontTextfield.inputAccessoryView = _pickerToolbar;
    _fontTextfield.textAlignment = NSTextAlignmentCenter;
    _fontTextfield.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
    [[_fontTextfield valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    
    _fontTipTextfield.inputView = _fontTipPicker;
    _fontTipTextfield.textAlignment = NSTextAlignmentCenter;
    _fontTipTextfield.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
    [[_fontTipTextfield valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    
    _languageTextfield.inputView = _languagePicker;
    _languageTextfield.textAlignment = NSTextAlignmentCenter;
    _languageTextfield.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
    [[_languageTextfield valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    
    _fontSizeTextfield.inputView = _fontSizePicker;
    _fontSizeTextfield.textAlignment = NSTextAlignmentCenter;
    _fontSizeTextfield.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
    [[_fontSizeTextfield valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    
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
    
    // Read the user defaults and set the auto lock type
    [SettingsViewController loadPreferences];
    [self buildPrimaryFonts];
    [self buildTipFonts];
    [self validatePreferences];
    
    // NOTE: this must occur before we try to create any strings
    struct FontInfo info;
    NSValue* value = [_primaryFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceFont]]];
    [value getValue:&info];
    [self validateFontMetrics:info._fontName];
    
    // Updates the appearance of the button and it's title...
    [self updateSelectedFont:[SettingsViewController getPreferenceFont] initial:TRUE];
    [self updateSelectedTipFont:[SettingsViewController getPreferenceTipFont]];
    [self updateSelectedLanguage:selectedLanguage andShouldNavigate:FALSE];
    [self updateSelectedFontSize:selectedFontSize andShouldNavigate:FALSE];
    
    // update the label look
    [self updateLabels];
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"settingsViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    [_fontTextfield resignFirstResponder];
    [_fontTipTextfield resignFirstResponder];
    [_languageTextfield resignFirstResponder];
    [_fontSizeTextfield resignFirstResponder];
    
    [_fontPicker reloadAllComponents];
    [_languagePicker reloadAllComponents];
    [_fontTipPicker reloadAllComponents];
    [_fontSizePicker reloadAllComponents];
    
    // update font on these guys
    [self updateTextfieldLabelFonts];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Perform ops when view disappears
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

// Make sure we have accurate values
-(void)validatePreferences
{
    int curPrimary = selectedFont[[Strings sharedInstance].CurrentLanguage];
    if (curPrimary < 0 || curPrimary >= [_primaryFonts count]) {
        selectedFont[[Strings sharedInstance].CurrentLanguage] = 0;
        [SettingsViewController savePreferences];
    }
    
    int curTip = selectedTipFont[[Strings sharedInstance].CurrentLanguage];
    if (curTip < 0 || curTip >= [_tipFonts count]) {
        selectedTipFont[[Strings sharedInstance].CurrentLanguage] = 0;
        [SettingsViewController savePreferences];
    }
    
    int curLang = selectedLanguage;
    if (curLang < 0 || curLang >= [_languageInfo count]) {
        selectedLanguage = 0;
        [SettingsViewController savePreferences];
    }
    
    int curFontSize = selectedFontSize;
    if (curFontSize < 0 || curFontSize >= [_fontSizeInfo count]) {
        selectedFontSize = 0;
        [SettingsViewController savePreferences];
    }
}

// Rebuilds the primary font list
-(void)buildPrimaryFonts
{
    [_primaryFonts removeAllObjects];
    
    int index = 0;
    struct FontInfo fontInfo;
    NSArray* fontNamesForLang = [[Utility sharedInstance] getDefaultSupportiveFontsFor:[Strings sharedInstance].CurrentLanguage
                                                                            andForTips:FALSE];
    
    // Iterate over font names
    for (NSString* fontName in fontNamesForLang) {
        fontInfo._fontName = fontName;
        fontInfo._displayName = fontName;
        fontInfo._fontSize = [Utility sharedInstance].defaultPrimaryFontSize;
        
        NSValue* value = [NSValue valueWithBytes:&fontInfo objCType:@encode(struct FontInfo)];
        [_primaryFonts setObject:value forKey:[NSNumber numberWithInt:index]];
        
        index++;
    }
    
    // add all fonts to font file
    for (NSValue* value in [_primaryFonts allValues]) {
        struct FontInfo finfo;
        [value getValue:&finfo];
        if (![[Utility sharedInstance] doesFontMetricExist:finfo._fontName withLanguage:kLanguage_English]) {
            [[Utility sharedInstance] addFontMetric:finfo._fontName withSizeDict:nil];
        }
    }
    
    // clamp the font index
    [SettingsViewController setPreferenceFont:MIN(_primaryFonts.count - 1, [SettingsViewController getPreferenceFont])];
}

// Rebuilds the tip font list
-(void)buildTipFonts
{
    [_tipFonts removeAllObjects];
    
    int index = 0;
    struct FontInfo fontInfo;
    NSArray* fontNamesForLang = [[Utility sharedInstance] getDefaultSupportiveFontsFor:[Strings sharedInstance].CurrentLanguage
                                                                            andForTips:TRUE];
    
    // iterate over font names
    for (NSString* fontName in fontNamesForLang) {
        fontInfo._fontName = fontName;
        fontInfo._displayName = fontName;
        fontInfo._fontSize = [Utility sharedInstance].defaultTipFontSize;
        
        NSValue* value = [NSValue valueWithBytes:&fontInfo objCType:@encode(struct FontInfo)];
        [_tipFonts setObject:value forKey:[NSNumber numberWithInt:index]];
        
        index++;
    }
    
    // clamp the font index
    [SettingsViewController setPreferenceTipFont:MIN(_tipFonts.count - 1, [SettingsViewController getPreferenceTipFont])];
}

// Retrieve the selected font info for the primary font
-(struct FontInfo)getSelectedPrimaryFont
{
    if ([SettingsViewController getPreferenceFont] >= _primaryFonts.count) {
        [SettingsViewController setPreferenceFont:0];
    }
    
    struct FontInfo fontInfo;
    NSValue* value = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceFont]]];
    [value getValue:&fontInfo];
    return fontInfo;
}

// Retrieve the selected font info for the tip font
-(struct FontInfo)getSelectedTipFont
{
    if ([SettingsViewController getPreferenceTipFont] >= _tipFonts.count) {
        [SettingsViewController setPreferenceTipFont:0];
    }
    
    struct FontInfo fontInfo;
    NSValue* value = (NSValue*)[_tipFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceTipFont]]];
    [value getValue:&fontInfo];
    return fontInfo;
}

// Creates the picker toolbar
-(UIToolbar*)createPickerToolbar
{
    if (_pickerToolbar != nil) {
        [_pickerToolbar release];
    }
    
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    NSString* buttonTitle = [[Strings sharedInstance] lookupString:@"doneButton"];
    _pickerToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, screenWidth, 40)];
    _pickerToolbar.backgroundColor = [UIColor clearColor];
    _pickerToolbar.barStyle = UIBarStyleBlackTranslucent;
    _pickerToolbar.items = [NSArray arrayWithObjects:
                            [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStylePlain target:self action:@selector(doneWithPicker)],
                            nil];
    
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor],  UITextAttributeTextColor,nil];
    [((UIBarButtonItem*)[_pickerToolbar.items objectAtIndex:1]) setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [_pickerToolbar sizeToFit];
    
    _fontTextfield.inputAccessoryView = _pickerToolbar;
    _fontTipTextfield.inputAccessoryView = _pickerToolbar;
    _languageTextfield.inputAccessoryView = _pickerToolbar;
    _fontSizeTextfield.inputAccessoryView = _pickerToolbar;
    
    return _pickerToolbar;
}

// update font on labels
-(void)updateLabels
{
    // setup labels
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_selectFontLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"settingsSelectFontLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth andIsTip:FALSE];
    _selectFontLabel.text = [[Strings sharedInstance] lookupString:@"settingsSelectFontLabel"];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_selectTipFontLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"settingsSelectTipFontLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth andIsTip:TRUE];
    _selectTipFontLabel.text = [[Strings sharedInstance] lookupString:@"settingsSelectTipFontLabel"];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_selectLanguageLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"settingsSelectLanguageLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth andIsTip:FALSE];
    _selectLanguageLabel.text = [[Strings sharedInstance] lookupString:@"settingsSelectLanguageLabel"];
    
    [[Utility sharedInstance] determineAndSetFontForLargeLabel:_selectFontSizeLabel
                                                      withText:[[Strings sharedInstance] lookupString:@"settingsSelectFontSizeLabel"]
                                                   andMaxWidth:[Utility sharedInstance].largeLabelTextWidth andIsTip:FALSE];
    _selectFontSizeLabel.text = [[Strings sharedInstance] lookupString:@"settingsSelectFontSizeLabel"];
}

// Handle when user clicks on textfield
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // set which textfield is active
    _activeTextfield = textField;
    
    // we need to return yes here otherwise the inputAccessoryView will not show
    return YES;
}

// The user selected the picker
-(void)doneWithPicker
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    int index = 0;
    
    if (_activeTextfield == _fontTipTextfield) {
        index = [_fontTipPicker selectedRowInComponent:0];
        [self updateSelectedTipFont:index];
        [_fontTipTextfield resignFirstResponder];
    }
    else if (_activeTextfield == _fontTextfield){
        index = [_fontPicker selectedRowInComponent:0];
        [self updateSelectedFont:index initial:FALSE];
        [_fontTextfield resignFirstResponder];
    }
    else if (_activeTextfield == _languageTextfield) {
        index = [_languagePicker selectedRowInComponent:0];
        [self updateSelectedLanguage:index andShouldNavigate:TRUE];
        [_languageTextfield resignFirstResponder];
    }
    else if (_activeTextfield == _fontSizeTextfield) {
        index = [_fontSizePicker selectedRowInComponent:0];
        [self updateSelectedFontSize:index andShouldNavigate:TRUE];
        [_fontSizeTextfield resignFirstResponder];
    }
}

// Updates the font on the text fields
-(void)updateTextfieldLabelFonts
{
    struct FontInfo fontInfo;
    NSValue* value1 = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceFont]]];
    [value1 getValue:&fontInfo];
    
    struct FontInfo fontTipInfo;
    NSValue* value2 = (NSValue*)[_tipFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceTipFont]]];
    [value2 getValue:&fontTipInfo];
    
    [[Utility sharedInstance] determineAndSetFontForButtonLabel:_fontTextfieldLabel
                                                       withText:_fontTextfieldLabel.text
                                                    andMaxWidth:[Utility sharedInstance].buttonLabelTextWidth andIsTip:FALSE];
    
    [[Utility sharedInstance] determineAndSetFontForButtonLabel:_fontTipTextfieldLabel
                                                       withText:_fontTipTextfieldLabel.text
                                                    andMaxWidth:[Utility sharedInstance].buttonLabelTextWidth andIsTip:TRUE];
    
    [[Utility sharedInstance] determineAndSetFontForButtonLabel:_languageTextfieldLabel
                                                       withText:_languageTextfieldLabel.text
                                                    andMaxWidth:[Utility sharedInstance].buttonLabelTextWidth andIsTip:TRUE];
    
    [[Utility sharedInstance] determineAndSetFontForButtonLabel:_fontSizeTextfieldLabel
                                                       withText:_fontSizeTextfieldLabel.text
                                                    andMaxWidth:[Utility sharedInstance].buttonLabelTextWidth andIsTip:TRUE];
    
//    _fontTextfieldLabel.font = [UIFont fontWithName:fontInfo._fontName size:[Utility sharedInstance].textfieldFontSize];
//    _languageTextfieldLabel.font = [UIFont fontWithName:fontInfo._fontName size:[Utility sharedInstance].textfieldFontSize];
//    _fontSizeTextfieldLabel.font = [UIFont fontWithName:fontInfo._fontName size:[Utility sharedInstance].textfieldFontSize];
    //_fontTipTextfieldLabel.font = [UIFont fontWithName:fontTipInfo._fontName size:s];
}

// Update the title on the button and the font being used
-(BOOL)updateSelectedFont:(NSInteger)index initial:(BOOL)initial
{
    // make sure we are in bounds
    if (index < 0 || index >= [_primaryFonts count]) {
        return FALSE;
    }
    
    struct FontInfo fontInfo;
    NSValue* value = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:index]];
    [value getValue:&fontInfo];
    
    [SettingsViewController setPreferenceFont:index];
    
    // On the initial call of this function we do not want to search for available fonts
    // because we are still in the land of initialization code as this function gets called
    // from viewWillAppear
    if (initial == NO) {
        
        UIFont* curFont = [UIFont fontWithName:fontInfo._fontName size:fontInfo._fontSize];
        if (![[Utility sharedInstance] doesFontSupportLanguage:curFont withLanguague:[Strings sharedInstance].CurrentLanguage]) {
            
            NSArray* alternates = [[Utility sharedInstance] findAlternateFontsThatSupportLanguage:[Strings sharedInstance].CurrentLanguage
                                                                                     withFontSize:fontInfo._fontSize];
            // If we could not find any alternates, then use default
            if (alternates.count == 0) {
                [SettingsViewController setPreferenceFont:0];
            }
            else {
                
                // Debug: display alternate font names...
                for (UIFont* uifont in alternates) {
                    NSLog(@"%@\n", uifont.fontName);
                }
                
                UIFont* randomAlternateFont = [alternates objectAtIndex:rand() % alternates.count];
                
                // First update the font info data
                fontInfo._fontName = randomAlternateFont.fontName;
                fontInfo._displayName = fontInfo._fontName;
                fontInfo._fontSize = randomAlternateFont.pointSize;
                
                // encode the data to get a new value
                value = [NSValue valueWithBytes:&fontInfo objCType:@encode(struct FontInfo)];
                [_primaryFonts setObject:value forKey:[NSNumber numberWithInt:_primaryFonts.count]];
                
                // add the font metric for the alternate font
                if (![[Utility sharedInstance] doesFontMetricExist:fontInfo._fontName withLanguage:kLanguage_English]) {
                    [[Utility sharedInstance] addFontMetric:fontInfo._fontName withSizeDict:nil];
                }
                
                // set the selected font index
                [SettingsViewController setPreferenceFont: _primaryFonts.count - 1];
            }
        }
    }

    // Make sure we have metrics before assigning the font
    if (![self validateFontMetrics:fontInfo._fontName]) {
        return FALSE;
    }
    
    // update our selected row
    [_fontPicker selectRow:[SettingsViewController getPreferenceFont] inComponent:0 animated:FALSE];
    
    _fontTextfieldLabel.text = fontInfo._displayName;
    
    // reload all entries for language picker to have new font setting
    [_languagePicker reloadAllComponents];
    [_fontPicker reloadAllComponents];
    
    // Change the primary font to affect the look of the app
    [[Utility sharedInstance] changePrimaryFont:fontInfo._fontName withSize:fontInfo._fontSize];
    
    [self updateTextfieldLabelFonts];
    
    // NOTE: this must occur after we change the font
    [self updateLabels];
    
    [SettingsViewController savePreferences];
    
    // update the title with the new primary font
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"settingsViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
    
    return TRUE;
}

// Update the title on the button and the font being used
-(BOOL)updateSelectedTipFont:(NSInteger)index
{
    if (index < 0 || index >= [_tipFonts count]) {
        return FALSE;
    }
    
    struct FontInfo fontInfo;
    NSValue* value = (NSValue*)[_tipFonts objectForKey:[NSNumber numberWithInt:index]];
    [value getValue:&fontInfo];
    
    [SettingsViewController setPreferenceTipFont:index];
    
    // update our selected row
    [_fontTipPicker selectRow:[SettingsViewController getPreferenceTipFont] inComponent:0 animated:FALSE];
    
    _fontTipTextfieldLabel.text = fontInfo._displayName;
    
    // Change the primary font to affect the look of the app
    [[Utility sharedInstance] changeTipFont:fontInfo._fontName withSize:fontInfo._fontSize];
    
    [self updateTextfieldLabelFonts];
    
    // NOTE: this must occur after we change the font
    [self updateLabels];
    
    // Write to the player's prefs...
    [SettingsViewController savePreferences];

    return TRUE;
}

// Updates the selected  language
-(BOOL)updateSelectedLanguage:(NSInteger)index andShouldNavigate:(BOOL)navigate
{
    if (index < 0 || index >= [_languageInfo count]) {
        return FALSE;
    }
    
    // if we are the same entry do nothing
    if (index == selectedLanguage && navigate) {
        [_languageTextfield resignFirstResponder];
        return FALSE;
    }
    
    selectedLanguage = index;
    [self validatePreferences];
    
    // Write to the player's prefs...
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:selectedLanguage forKey:@"SelectedLanguage"];
    [defaults synchronize];
    
    // Get the selected language and apply it
    struct LanguageInfo info;
    NSValue* value = [_languageInfo objectAtIndex:selectedLanguage];
    [value getValue:&info];
    
    [_languagePicker selectRow:selectedLanguage inComponent:0 animated:FALSE];
    
    _languageTextfieldLabel.text = info._displayName;
    [_languageTextfield resignFirstResponder];
    
    // Write to the player's prefs...
    [SettingsViewController savePreferences];
    
    // NOTE: the change of the language must take place first
    // before we can change the fonts
    [[Strings sharedInstance] changeCurrentLanguage:info._lang];
    
    [self updateTextfieldLabelFonts];
    
    // Write to the player's prefs...
    [SettingsViewController savePreferences];
    
    [self buildPrimaryFonts];
    [self buildTipFonts];
    [self createPickerToolbar];
    [self validatePreferences];
    
    // Update the primary lang
    int langFont = [SettingsViewController getPreferenceFont];
    struct FontInfo fontInfo;
    value = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:langFont]];
    [value getValue:&fontInfo];
    [[Utility sharedInstance] changePrimaryFont:fontInfo._fontName withSize:fontInfo._fontSize];
    
    // Update the tip lang
    int langTipFont = [SettingsViewController getPreferenceTipFont];
    struct FontInfo fontTipInfo;
    value = (NSValue*)[_tipFonts objectForKey:[NSNumber numberWithInt:langTipFont]];
    [value getValue:&fontTipInfo];
    [[Utility sharedInstance] changeTipFont:fontTipInfo._fontName withSize:fontTipInfo._fontSize];
    
    // pop to root view
    if (navigate) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    return TRUE;
}

// Updates the selected  language
-(BOOL)updateSelectedFontSize:(NSInteger)index andShouldNavigate:(BOOL)navigate
{
    if (index < 0 || index >= [_fontSizeInfo count]) {
        return FALSE;
    }
    
    // if we are the same entry do nothing
    if (index == selectedFontSize && navigate) {
        [_fontSizeTextfield resignFirstResponder];
        return FALSE;
    }
    
    selectedFontSize = index;
    [self validatePreferences];
    
    // Write to the player's prefs...
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:selectedFontSize forKey:@"SelectedFontSize"];
    [defaults synchronize];
    
    // Get the selected language and apply it
    struct FontSizeInfo info;
    NSValue* value = [_fontSizeInfo objectAtIndex:selectedFontSize];
    [value getValue:&info];
    
    [_fontSizePicker selectRow:selectedFontSize inComponent:0 animated:FALSE];
    
    [self updateLabels];
    _fontSizeTextfieldLabel.text = ((UILabel*)[self pickerView:_fontSizePicker viewForRow:selectedFontSize forComponent:0 reusingView:nil]).text;
    [_fontSizeTextfield resignFirstResponder];
    [self updateTextfieldLabelFonts];
    
    // Write to the player's prefs...
    [SettingsViewController savePreferences];
    
    // pop to root view
    if (navigate) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    return TRUE;
}

// Validates the font metrics and then adds one if it is currently missing
-(BOOL)validateFontMetrics:(NSString *)fontName
{
    if (![[Utility sharedInstance] doesFontMetricExist:fontName withLanguage:[Strings sharedInstance].CurrentLanguage]) {
        [[Utility sharedInstance] addFontMetric:fontName withSizeDict:nil];
    }
    
    return [[Utility sharedInstance] doesFontMetricExist:fontName withLanguage:[Strings sharedInstance].CurrentLanguage];
}

// Dont allow text input on our field
-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    return NO;
}


// Return cell height for pickerview
-(float)pickerView:(UIPickerView*)pickerView rowHeightForComponent:(NSInteger)component
{
    return 24.0f;
}

// Return cell width for picker view
-(float)pickerView:(UIPickerView*)pickerView widthForComponent:(NSInteger)component
{
    return [UIScreen mainScreen].bounds.size.width;
}

// Creates a label to be used for the rows of the UIPicker
-(UIView*)pickerView:(UIPickerView*)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView*)view
{
    struct FontInfo fontInfo;
    struct LanguageInfo languageInfo;
    struct FontSizeInfo fontSizeInfo;
    NSValue* value = nil;
    
    if (pickerView == _fontPicker) {
        // error check
        if (row >= [_primaryFonts count]) {
            row = [_primaryFonts count] - 1;
        }
        value = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:row]];
        [value getValue:&fontInfo];
    }
    else if (pickerView == _fontTipPicker) {
        // error check
        if (row >= [_tipFonts count]) {
            row = [_tipFonts count] - 1;
        }
        value = (NSValue*)[_tipFonts objectForKey:[NSNumber numberWithInt:row]];
        [value getValue:&fontInfo];
    }
    else if (pickerView == _languagePicker) {
        // error check
        if (row >= [_languageInfo count]) {
            row = [_languageInfo count] - 1;
        }
        value = (NSValue*)[_languageInfo objectAtIndex:row];
        [value getValue:&languageInfo];
    }
    else if (pickerView == _fontSizePicker) {
        // error check
        if (row >= [_fontSizeInfo count]) {
            row = [_fontSizeInfo count] - 1;
        }
        
        NSValue* primaryFontValue = (NSValue*)[_primaryFonts objectForKey:[NSNumber numberWithInt:[SettingsViewController getPreferenceFont]]];
        [primaryFontValue getValue:&fontInfo];
        
        value = (NSValue*)[_fontSizeInfo objectAtIndex:row];
        [value getValue:&fontSizeInfo];
    }
    
    UILabel* pickerLabel = (UILabel*)view;
    NSString* fontName = pickerView == _languagePicker ? [Utility sharedInstance].primaryFontName : fontInfo._fontName;
    UIFont* font = [UIFont fontWithName:fontName size:14.0f];
    
    // If we haven't created a label yet, now is the time to do so
    if (pickerLabel == nil) {
        CGRect frame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 32.0f);
        pickerLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        pickerLabel.textAlignment = NSTextAlignmentCenter;
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setTextColor:[UIColor colorWithRed:56.0f/255.0f green:51.0f/255.0f blue:15.0f/255.0f alpha:1.0f]];
        [pickerLabel setFont:font];
    }
    
    // set the text
    if (pickerView == _languagePicker) {
        [pickerLabel setText:languageInfo._displayName];
    }
    else if (pickerView == _fontSizePicker) {
        switch (fontSizeInfo._size) {
            case kPrimaryFontSize_Extra_Small:
                [pickerLabel setText:[[Strings sharedInstance] lookupString:@"fontSizeExtraSmall"]];
                break;
            case kPrimaryFontSize_Small:
                [pickerLabel setText:[[Strings sharedInstance] lookupString:@"fontSizeSmall"]];
                break;
            case kPrimaryFontSize_Medium:
                [pickerLabel setText:[[Strings sharedInstance] lookupString:@"fontSizeMedium"]];
                break;
            case kPrimaryFontSize_Large:
                [pickerLabel setText:[[Strings sharedInstance] lookupString:@"fontSizeLarge"]];
                break;
            case kPrimaryFontSize_ExtraLarge:
                [pickerLabel setText:[[Strings sharedInstance] lookupString:@"fontSizeExtraLarge"]];
                break;
        }
    }
    else {
        [pickerLabel setText:fontInfo._displayName];
    }
    
    return pickerLabel;
}

// Returns the number of components
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// Return how many choices we have in the picker view
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _fontTipPicker) {
        return [_tipFonts count];
    }
    else if (pickerView == _fontPicker) {
        return [_primaryFonts count];
    }
    else if (pickerView == _languagePicker) {
        return [_languageInfo count];
    }
    else if (pickerView == _fontSizePicker) {
        return [_fontSizeInfo count];
    }
    
    // should not get here
    return 0;
}

// Handle when we select an element from picker view
-(void)pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // NO-OP: This is now handled when the user dismisses the input popup for the textfield
}

// Handle when the user clicks on the back button
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
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
    
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"settingsViewControllerHint"],KVaultNameMinLimit, kVaultNameMaxLimit, kVaultPasswordMinLimit, kVaultPasswordMaxLimit];
    
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
