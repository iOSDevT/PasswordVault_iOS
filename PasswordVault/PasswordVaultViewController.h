//
//  PasswordVaultViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

@interface PasswordVaultViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
    IBOutlet UITableView* _vaultTableView;
    IBOutlet UISearchBar* _vaultSearchBar;
    IBOutlet UIScrollView* _scrollView;
    int _selectedRow;
    int _selectedSection;
    AlertType _currentAlertType;
    CGPoint _scrollOffset;
    BOOL _inEditMode;
    PasswordVaultItem* _itemToDelete;
    UIButton* _sortButton;
    UIButton* _searchNextButton;
    UIButton* _searchCancelButton;
    int _searchOffset;
}

-(UITextField*)getSearchBarTextfield;

@end
