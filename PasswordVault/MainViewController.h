//
//  MainViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 11/29/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddVaultItemViewController.h"
#import "AutoLockViewController.h"
#import "EditVaultItemViewController.h"
#import "IconSelectionViewController.h"
#import "LoadVaultViewController.h"
#import "NewVaultViewController.h"
#import "PasswordGenerateViewController.h"
#import "PasswordVaultViewController.h"
#import "SettingsViewController.h"
#import "WebViewController.h"

// ViewController for the main screen that the navigation controller shows
@interface MainViewController : UIViewController
{
    UIButton* _newVaultButton;
	UIButton* _loadVaultButton;
    UIButton* _autoLockVaultButton;
    UIButton* _settingsButton;
    UILabel* _tipLabel;
    UILabel* _loadingLabel;
    IBOutlet UISegmentedControl* _tutorialOnOffControl;

    NewVaultViewController* _newVaultViewContoller;
    LoadVaultViewController* _loadVaultViewController;
    PasswordVaultViewController* _passwordVaultViewController;
    AddVaultItemViewController* _addVaultItemViewController;
    EditVaultItemViewController* _editVaultItemViewController;
    WebViewController* _webViewController;
    IconSelectionViewController* _iconSelectionViewController;
    AutoLockViewController* _autoLockViewController;
    SettingsViewController* _settingsViewController;
    PasswordGenerateViewController* _passwordGenerateViewController;
    UIViewController* _lastViewController;
    BOOL _hasInitializedData;
}

// Properties
@property (nonatomic, retain) IBOutlet UIButton* NewVaultButton;
@property (nonatomic, retain) IBOutlet UIButton* LoadVaultButton;
@property (nonatomic, retain) IBOutlet UIButton* AutoLockVaultButton;
@property (nonatomic, retain) IBOutlet UIButton* SettingsButton;
@property (nonatomic, retain) IBOutlet UILabel* TipLabel;
@property (nonatomic, retain) IBOutlet UILabel* LoadingLabel;
@property (nonatomic, readonly) NewVaultViewController* NewVaultViewController;
@property (nonatomic, readonly) LoadVaultViewController* LoadVaultViewController;
@property (nonatomic, readonly) PasswordVaultViewController* PasswordVaultViewController;
@property (nonatomic, readonly) AddVaultItemViewController* AddVaultItemViewController;
@property (nonatomic, readonly) EditVaultItemViewController* EditVaultItemViewController;
@property (nonatomic, readonly) WebViewController* WebViewController;
@property (nonatomic, readonly) IconSelectionViewController* IconSelectionViewController;
@property (nonatomic, readonly) AutoLockViewController* AutoLockViewController;
@property (nonatomic, readonly) SettingsViewController* SettingsViewController;
@property (nonatomic, readonly) PasswordGenerateViewController* PasswordGenerateViewController;
@property (nonatomic, assign) UIViewController* LastViewController;

// Functions
-(IBAction)handleNewVaultButton;
-(IBAction)handleLoadVaultButton;
-(IBAction)handleAutoLockButton;
-(IBAction)handleSettingsButton;
+(NSString*)fallbackDirectory;
+(BOOL)useFallbackDirectory;

@end
