//
//  NewVaultViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Enums.h"

@interface PasswordGenerateViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    @private
    IBOutlet UILabel* _useNumberLabel;
    IBOutlet UILabel* _useLetterLabel;
    IBOutlet UILabel* _useSymbolLabel;
    IBOutlet UILabel* _useUppercaseLabel;
    IBOutlet UILabel* _useLowercaseLabel;
    IBOutlet UILabel* _minPasswordLabel;
    IBOutlet UILabel* _maxPasswordLabel;
    IBOutlet UITextField* _passwordTextField;
    IBOutlet UIButton* _generateButton;
    IBOutlet UIButton* _acceptButton;
    IBOutlet UISwitch* _useNumberSwitch;
    IBOutlet UISwitch* _useLetterSwitch;
    IBOutlet UISwitch* _useSymbolSwitch;
    IBOutlet UISwitch* _useUppercaseSwitch;
    IBOutlet UISwitch* _useLowercaseSwitch;
    IBOutlet UISlider* _passwordLengthSlider;
    IBOutlet UIImageView* _backgroundImage;
    
    UILabel* _passwordLengthLabel;
    AlertType _currentAlertType;
    int _passwordLength;
    UIColor* _weakColor;
    UIColor* _okayColor;
    UIColor* _strongColor;
    
    @public
    NSString* _lastGeneratedPassword;
}

@property (nonatomic, readonly) NSString* LastGeneratedPassword;

-(IBAction)generatePassword:(id)sender;
-(IBAction)acceptPassword:(id)sender;
-(IBAction)sliderAdjusted:(id)sender;

@end
