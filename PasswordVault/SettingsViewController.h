//
//  NewVaultViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Enums.h"

// Structure that stores font info
struct FontInfo
{
    NSString* _displayName;
    NSString* _fontName;
    float _fontSize;
};

@interface SettingsViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    IBOutlet UIPickerView* _fontPicker;
    IBOutlet UIPickerView* _fontTipPicker;
    IBOutlet UIPickerView* _languagePicker;
    IBOutlet UIPickerView* _fontSizePicker;
    IBOutlet UITextField* _fontTextfield;
    IBOutlet UITextField* _fontTipTextfield;
    IBOutlet UITextField* _languageTextfield;
    IBOutlet UITextField* _fontSizeTextfield;
    IBOutlet UILabel* _selectFontLabel;
    IBOutlet UILabel* _selectTipFontLabel;
    IBOutlet UILabel* _selectLanguageLabel;
    IBOutlet UILabel* _selectFontSizeLabel;
    IBOutlet UILabel* _fontTextfieldLabel;
    IBOutlet UILabel* _fontTipTextfieldLabel;
    IBOutlet UILabel* _languageTextfieldLabel;
    IBOutlet UILabel* _fontSizeTextfieldLabel;
    UIButton* _createVaultButton;
    AlertType _currentAlertType;
    NSMutableDictionary* _primaryFonts;
    NSMutableDictionary* _tipFonts;
    UITextField* _activeTextfield;
    NSArray* _languageInfo;
    NSArray* _fontSizeInfo;
    UIToolbar* _pickerToolbar;
}

// Functions
-(struct FontInfo)getSelectedPrimaryFont;
-(struct FontInfo)getSelectedTipFont;
-(IBAction)handleHintButton:(id)sender;
-(BOOL)validateFontMetrics:(NSString *)fontName;
+(void)loadPreferences;
+(int)getPreferenceFont;
+(int)getPreferenceTipFont;
+(int)getPreferenceFontSize;
+(void)setPreferenceFont:(int)index;
+(void)setPreferenceTipFont:(int)index;
+(void)savePreferences;
@end
