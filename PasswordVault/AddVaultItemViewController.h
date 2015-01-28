//
//  AddVaultItemController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/23/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Enums.h"
#import "PasswordVaultItem.h"


@interface AddVaultItemViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITextField* _categoryTextField;
    IBOutlet UITextField* _titleTextField;
    IBOutlet UITextField* _accountTextField;
    IBOutlet UITextField* _userNameTextField;
    IBOutlet UITextField* _passwordTextField;
    IBOutlet UITextField* _urlTextField;
    IBOutlet UITextView* _notesTextView;
    IBOutlet UIScrollView* _scrollView;
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
    UITapGestureRecognizer* _iconTapGestureRecognizer;
    NSString* _selectedIcon;
    AlertType _currentAlertType;
    UITableView* _autoCompleteTableView;
    NSMutableArray* _autoCompleteData;
    AutoCompleteType _autoCompleteType;
    PasswordVaultItem* _tempItem;
}
-(IBAction)dismissKeyboardOnTap:(id)sender;
-(IBAction)textFieldPressDone:(id)sender; 
-(IBAction)generatePassword:(id)sender;
-(void)showMenuController;
-(void)searchAutocompleteEntriesWithSubstring:(NSString*)substring withData:(NSMutableArray*)data;
-(void)setupAutoComplete:(NSString*)string withTextField:(UITextField*)textField andRange:(NSRange)range;
@end
