//
//  LoadVaultViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Enums.h"

@interface LoadVaultViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITextFieldDelegate>
{
    IBOutlet UITableView* _fileTableView;
    IBOutlet UIButton* _changePasswordButton;
    IBOutlet UIButton* _duplicateVaultButton;
    IBOutlet UIButton* _renameVaultButton;
    NSMutableArray* _filesAvailableForLoad;
    int _selectedRow;
    UIAlertView* _alertView;
    BOOL _inEditMode;
    BOOL _changePasswordRequested;
    BOOL _duplicateVaultRequested;
    BOOL _renameVaultRequested;
    int _activeChangePasswordRow;
    int _activeDuplicateVaultRow;
    int _activeRenameVaultRow;
    AlertType _alertType;
    UIButton* _changePasswordCellButton;
    UIButton* _duplicateVaultCellButton;
    UIButton* _renameVaultCellButton;
    NSString* _filenameToDelete;
    NSInteger _fileRowToDelete;
    NSString* _filenameToDuplicate;
    NSInteger _fileRowToDuplicate;
    NSString* _filenameToRename;
    NSInteger _fileRowToRename;
    BOOL _duplicatingVault;
    BOOL _editingVaultPassword;
    BOOL _renamingVault;
}
-(IBAction)handleHintButton:(id)sender;
+(BOOL)isVaultNameUsed:(NSString*)name;

@end
