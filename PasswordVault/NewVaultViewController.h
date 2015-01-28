//
//  NewVaultViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/7/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Enums.h"

extern const int kVaultNameMaxLimit;
extern const int KVaultNameMinLimit;
extern const int kVaultPasswordMaxLimit;
extern const int kVaultPasswordMinLimit;

@interface NewVaultViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField* _vaultNameTextField;
    IBOutlet UITextField* _vaultPasswordTextField;
    IBOutlet UITextField* _vaultPassword2TextField;
    UIButton* _createVaultButton;
    AlertType _currentAlertType;
}

@property (nonatomic, retain) IBOutlet UIButton* CreateVaultButton;

// Functions
-(IBAction)vaultNamePressDone:(id)sender;
-(IBAction)vaultPasswordPressDone:(id)sender;
-(IBAction)vaultPassword2PressDone:(id)sender;
-(IBAction)handleCreateVaultButton;
-(IBAction)handleHintButton:(id)sender;
@end
