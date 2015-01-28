//
//  EditVaultItemViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 1/4/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "PasswordVaultItem.h"
#import "Enums.h"

@interface EditVaultItemViewController : UIViewController<UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITextField* _categoryTextField;
    IBOutlet UITextField* _titleTextField;
    IBOutlet UITextField* _accountTextField;
    IBOutlet UITextField* _userNameTextField;
    IBOutlet UITextField* _passwordTextField;
    IBOutlet UITextField* _urlTextField;
    IBOutlet UITextView* _notesTextView;
    IBOutlet UIScrollView* _scrollView;
    IBOutlet UIBarButtonItem* _webButtonItem;
    IBOutlet UIBarButtonItem* _forwardButtonItem;
    IBOutlet UIBarButtonItem* _editedButtonItem;
    IBOutlet UIButton* _webButton;
    IBOutlet UIButton* _forwardButton;
    IBOutlet UIButton* _editButton;
    IBOutlet UIImageView* _iconImageView;
    
    IBOutlet UILabel* _categoryLabel;
    IBOutlet UILabel* _titleLabel;
    IBOutlet UILabel* _accountLabel;
    IBOutlet UILabel* _usernameLabel;
    IBOutlet UILabel* _passwordLabel;
    IBOutlet UILabel* _urlLabel;
    IBOutlet UILabel* _notesLabel;
    IBOutlet UILabel* _iconLabel;
    IBOutlet UILabel* _tapIconLabel;
    
    NSString* _notesTextViewPlaceHolderText;
    CGPoint _scrollOffset;
    CGRect _scrollRect;
    UITextField* _activeTextField;
    UIActionSheet* _activeActionSheet;
    PasswordVaultItem* _activeItem;
    UITapGestureRecognizer* _iconTapGestureRecognizer;
    NSString* _selectedIcon;
    AlertType _currentAlertType;
    UITableView* _autoCompleteTableView;
    NSMutableArray* _autoCompleteData;
    AutoCompleteType _autoCompleteType;
}
-(IBAction)dismissKeyboardOnTap:(id)sender;
-(IBAction)textFieldPressDone:(id)sender;
-(IBAction)generatePassword:(id)sender;
-(void)applyPasswordVaultItem:(PasswordVaultItem*)item;
-(BOOL)hasChanges;
-(void)searchAutocompleteEntriesWithSubstring:(NSString*)substring withData:(NSMutableArray*)data;
-(void)setupAutoComplete:(NSString*)string withTextField:(UITextField*)textField andRange:(NSRange)range;

@property (nonatomic, readonly) PasswordVaultItem* activeItem;

@end
