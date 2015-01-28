//
//  PasswordVaultViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "AddVaultItemViewController.h"
#import "CustomTableViewCell.h"
#import "MainViewController.h"
#import "PasswordVault.h"
#import "PasswordVaultViewController.h"
#import "Strings.h"
#import "Utility.h"

#import <QuartzCore/QuartzCore.h>

static const float kHeightForHeader = 46;
static const float kHeightForFooter = 1;
static const float kHeightForCell = 44;
static const float kTopOffset = 64.0f;
static const float kCategoryOffset = 64.0f;

@interface PasswordVaultItem(Private)
-(BOOL)searchForItem:(NSString*)text;
-(void)updateSearchButtons:(BOOL)show;
@end

@implementation PasswordVaultViewController

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _selectedRow = -1;
        _selectedSection = -1;
        _scrollOffset = CGPointMake(0.0f, 0.0f);
        _inEditMode = FALSE;
        _itemToDelete = nil;
        _searchOffset = 0;
    }
    return self;
}

// custom delete routine
-(void)dealloc
{
    [super dealloc];
}

// Handle the case when we receive a memory warning
-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
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
    
    UIImage* addImage = [[UIImage imageNamed:@"AddIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnAdd setBackgroundImage:addImage forState:UIControlStateNormal];
    [btnAdd addTarget:self action:@selector(handleNavigationAddButton:) forControlEvents:UIControlEventTouchUpInside];
    btnAdd.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem *btnAddItem = [[UIBarButtonItem alloc] initWithCustomView:btnAdd];
    
    UIImage* editImage = [[UIImage imageNamed:@"EditIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnEdit setBackgroundImage:editImage forState:UIControlStateNormal];
    [btnEdit addTarget:self action:@selector(handleEditButton:) forControlEvents:UIControlEventTouchUpInside];
    btnEdit.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem* btnEditItem = [[UIBarButtonItem alloc] initWithCustomView:btnEdit];
    
    NSInteger compareMode = [PasswordVault sharedInstance].categoryComparison;
    NSString* compareImageName = compareMode == NSOrderedDescending ? @"image129.png" : @"image112.png";
    UIImage* compareImage = [[UIImage imageNamed:compareImageName] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnCompare = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCompare setBackgroundImage:compareImage forState:UIControlStateNormal];
    [btnCompare addTarget:self action:@selector(handleCompareButton:) forControlEvents:UIControlEventTouchUpInside];
    btnCompare.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem* btnCompareItem = [[UIBarButtonItem alloc] initWithCustomView:btnCompare];
    
    NSArray* leftArray = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    NSArray* rightArray = [NSArray arrayWithObjects:btnCompareItem, btnAddItem, btnEditItem, nil];
    self.navigationItem.leftBarButtonItems = leftArray;
    self.navigationItem.rightBarButtonItems = rightArray;
    
    // Build search next button for search bar functionality
    CGRect searchBarFrame = _vaultSearchBar.frame;
    UIImage* searchImage = [[UIImage imageNamed:@"SearchNextButton.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnSearchNext = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSearchNext setBackgroundImage:searchImage forState:UIControlStateNormal];
    [btnSearchNext addTarget:self action:@selector(handleSearchNext:) forControlEvents:UIControlEventTouchUpInside];
    
    // determine search next button position
    float buttonSize = 22.0f;
    float xPos = searchBarFrame.origin.x + searchBarFrame.size.width - (buttonSize + 58);
    float yPos = searchBarFrame.origin.y + (searchBarFrame.size.height - buttonSize) / 2 + 1;
    btnSearchNext.frame = CGRectMake(xPos, yPos, buttonSize, buttonSize);
    [_vaultSearchBar addSubview:btnSearchNext];
    
    // Build search cancel button for search bar functionality
    UIImage* searchCancelImage = [[UIImage imageNamed:@"SearchCancelButton.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnSearchCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSearchCancel setBackgroundImage:searchCancelImage forState:UIControlStateNormal];
    [btnSearchCancel addTarget:self action:@selector(handleSearchCancel:) forControlEvents:UIControlEventTouchUpInside];
    
    // determine search cancel button position
    float xPos2 = searchBarFrame.origin.x + searchBarFrame.size.width - (buttonSize + 24);
    float yPos2 = searchBarFrame.origin.y + (searchBarFrame.size.height - buttonSize) / 2 + 1;
    btnSearchCancel.frame = CGRectMake(xPos2, yPos2, buttonSize, buttonSize);
    [_vaultSearchBar addSubview:btnSearchCancel];
    
    // Hide the clear button on the search bar
    UITextField *textField = [_vaultSearchBar valueForKey:@"_searchField"];
    textField.clearButtonMode = UITextFieldViewModeNever;
    
    // store this button so we can modify its background image
    _sortButton = btnCompare;
    _searchNextButton = btnSearchNext;
    _searchCancelButton = btnSearchCancel;
    
    // Set cell border
    _vaultTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _vaultTableView.separatorColor = [UIColor whiteColor];
    _vaultTableView.separatorInset = UIEdgeInsetsZero;

    [btnBack release];
    [btnAdd release];
    [btnBackItem release];
    [btnAddItem release];
    [btnEdit release];
    [btnCompare release];
    
    _vaultSearchBar.frame = CGRectMake(0, 63, 320, 44);
    _vaultSearchBar.delegate = self;
    [self.view addSubview:_vaultSearchBar];
    [self updateSearchButtons:FALSE];
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [super viewDidUnload];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [[PasswordVault sharedInstance] clearLastSearchResults];
    
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [PasswordVault sharedInstance].vaultName;
    
    // reload the table data
    _inEditMode = FALSE;
    [_vaultTableView setEditing:FALSE animated:YES];
    [_vaultTableView reloadData];
    
    [self updateSearchButtons:FALSE];
    
    // set placeholder text on search bar
    _vaultSearchBar.placeholder = [[Strings sharedInstance] lookupString:@"searchBarPlaceholder"];
    
    // begin the auto-lock timeout
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
    
    // For the search bar, we want to use the default font but with a different size
    UIFont* font = [self getSearchBarTextfield].font;
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:font.fontName size:11.0f]];
    [UITextField appearanceWhenContainedIn:[UISearchBar class], nil].textColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
    [UITextField appearanceWhenContainedIn:[UISearchBar class], nil].tintColor = [UIColor blueColor];

    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:[PasswordVault sharedInstance].vaultName
                                 withMaxWidth:120.0f
                              andIsLargeTitle:FALSE
                                 andAlignment:NSTextAlignmentLeft];
}

-(UITextField*)getSearchBarTextfield
{
    for (UIView* view in _vaultSearchBar.subviews) {
        if ([view class] == [UITextField class]) {
            return (UITextField*)view;
        }
    }
    return nil;
}

// handle the disapper
-(void)viewWillDisappear:(BOOL)animated
{
    [[PasswordVault sharedInstance] clearLastSearchResults];
    
    [_vaultSearchBar resignFirstResponder];
    
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
}

// Called when the back button is clicked
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

// Called when the plus is pressed
-(IBAction)handleNavigationAddButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // Animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    AddVaultItemViewController* pAddVaultItemViewController = [pDelegate mainViewController].AddVaultItemViewController;
    [[pDelegate navigationController] pushViewController:pAddVaultItemViewController animated:YES];
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

-(IBAction)handleEditButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (_inEditMode == FALSE)
    {
        _inEditMode = TRUE;
        [_vaultTableView setEditing:TRUE animated:YES];
    }
    else
    {
        _inEditMode = FALSE;
        [_vaultTableView setEditing:FALSE animated:YES];
    }
    
    //[_vaultTableView reloadData];
}

// When the user clicks the cancel button we want to reset the search
-(IBAction)handleSearchCancel:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    _vaultSearchBar.text = @"";
    
    [[PasswordVault sharedInstance] clearLastSearchResults];
    [self updateSearchButtons:FALSE];
    [self searchForItem:@""];
}

// When the user taps this button we advance our search to the next result
-(IBAction)handleSearchNext:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    ++_searchOffset;
    [self searchForItem:_vaultSearchBar.text];
}

// Called when the user clicks on the sort button
-(IBAction)handleCompareButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSInteger compareMode = [PasswordVault sharedInstance].categoryComparison;
    if (compareMode == NSOrderedDescending) {
        [[PasswordVault sharedInstance] sortCategories:NSOrderedAscending];
    }
    else {
        [[PasswordVault sharedInstance] sortCategories:NSOrderedDescending];
    }
    
    NSString* compareImageName = compareMode != NSOrderedDescending ? @"image129.png" : @"image112.png";
    UIImage* compareImage = [[UIImage imageNamed:compareImageName] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    [_sortButton setBackgroundImage:compareImage forState:UIControlStateNormal];
    
    [_vaultTableView reloadData];
}

-(void)tableView:(UITableView *)aTableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        _itemToDelete = [[PasswordVault sharedInstance] getItem:indexPath.section withItem:indexPath.row];
        [self showAreYouSureAlert];
    }
}

// Returns the number of sections in the table view
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return [[PasswordVault sharedInstance] getCategoryCount];
}

// Sets the text for the delet confirmation view
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[Strings sharedInstance] lookupString:@"deleteButton"];
}

//// Sets the title text for header for the table view
//-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
//{
//    return [[PasswordVault sharedInstance] getCategoryName:section];
//}

// Returns a view used to create headers on the tableview
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, kHeightForHeader)];
    NSString* text = [NSString stringWithFormat:@"%@", [[PasswordVault sharedInstance] getCategoryName:section]];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, rect.size.width, kHeightForHeader)];
    label.opaque = NO;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentLeft;
    [[Utility sharedInstance] determineAndSetFontForTableviewHeaderFooter:label
                                                                 withText:text
                                                              andMaxWidth:[Utility sharedInstance].tableviewHeaderFooterTextWidth
                                                                 andIsTip:FALSE];
    [label setText:text];
    
    view.backgroundColor = [UIColor blackColor];
    [view addSubview:label];
	return view;
}

// Returns a view that describes the last cell of the tableview
-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeightForFooter)];
    view.backgroundColor = [UIColor blackColor];
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return kHeightForHeader;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kHeightForFooter;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)path 
{
	return kHeightForCell;
}

//// Sets the title text for the footer for the table view
//-(NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
//{
//    return @"";
//}

// Returns the number of rows we should have based on the table view
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[PasswordVault sharedInstance] getItemCountForCategory:section];
}

-(void) reloadViewHeight
{
    float currentTotal = 0;
    
    //Need to total each section
    for (int i = 0; i < [_vaultTableView numberOfSections]; i++)
    {
        CGRect sectionRect = [_vaultTableView rectForSection:i];
        currentTotal += sectionRect.size.height;
    }
    
    //Set the contentSizeForViewInPopover
    _vaultTableView.contentSize = CGSizeMake(_vaultTableView.frame.size.width, currentTotal);
}

// Handle populating the table view with the data
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath 
{
    static NSString* CellIdentifier = @"Cell";
    UIColor* kColorOne = [UIColor colorWithRed:84.0f/255.0f green:177.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
    UIColor* kColorTwo = [UIColor colorWithRed:162.0f/255.0f green:205.0f/255.0f blue:232.0f/255.0f alpha:1.0f];
    UIColor* kTextColor = [UIColor colorWithRed:10.0/255.0 green:57.0f/255.0f blue:87.0f/255.0f alpha:1.0f];
    
    // See if we have a cell already
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)  
    {
        cell = [[[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
   
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.imageView.image = [UIImage imageNamed:[[PasswordVault sharedInstance] getItemIcon:indexPath.section withItem:indexPath.row]];
    cell.textLabel.textColor = kTextColor;
    cell.backgroundColor = indexPath.row % 2 == 0 ? kColorOne : kColorTwo;
    
    [[Utility sharedInstance] determineAndSetFontForTableviewCell:cell.textLabel
                                                         withText:[[PasswordVault sharedInstance] getItemName:indexPath.section
                                                                                                     withItem:indexPath.row]
                                                      andMaxWidth:[Utility sharedInstance].tableviewCellTextWidth
                                                         andIsTip:FALSE];
    // set the text after our font has been determined
    cell.textLabel.text = [[PasswordVault sharedInstance] getItemName:indexPath.section withItem:indexPath.row];
    
    [self reloadViewHeight];
    
    // return the created cell
    return cell;
}

// Handle when the user makes a selection
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath 
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // save the selected row
    _selectedSection = indexPath.section;
    _selectedRow = indexPath.row;
    
    // retrieve the password vault item
    PasswordVaultItem* item = [[PasswordVault sharedInstance] getItem:_selectedSection withItem:_selectedRow];
    
    // animate to the new vault view controller...
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    EditVaultItemViewController* pEditVaultViewController = [pDelegate mainViewController].EditVaultItemViewController;
    [[pDelegate navigationController] pushViewController:pEditVaultViewController animated:YES];
    
    // Call this on a delay since viewWillAppear will unset the item and we want
    // to do this after the view appears
    [pEditVaultViewController performSelector:@selector(applyPasswordVaultItem:) withObject:item afterDelay:0.1f];
}

// the user clicked on the hint button
-(IBAction)handleHintButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"hintTitle"]
                                                        message:[[Strings sharedInstance] lookupString:@"passwordVaultViewControllerHint"]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _currentAlertType = kAlertType_Hint;
}

// shows the are you sure dialog
-(void)showAreYouSureAlert
{
    NSString* message = [NSString stringWithFormat:
                         [[Strings sharedInstance] lookupString:@"alertDeleteItem"], _itemToDelete.title];
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"alertDeletItemTitle"]
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"deleteButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _currentAlertType = kAlertType_AreYouSureAlert;
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // the user cancelled, do nothing
    if (buttonIndex == 0)
    {
        if (_currentAlertType == kAlertType_AreYouSureAlert) {
            _itemToDelete = nil;
            
            // get out of edit mode
            _inEditMode = FALSE;
            [_vaultTableView setEditing:FALSE animated:YES];
        }
    }
    // Handle the user pressing the second button
    else if (buttonIndex == 1)
    {
        // if we are the "are you sure" alert then the user
        // has chosen to delete a vault entry
        if (_currentAlertType == kAlertType_AreYouSureAlert)
        {
            [[PasswordVault sharedInstance] removeItem:_itemToDelete];
            [_vaultTableView reloadData];
            
            _itemToDelete = nil;
            
            // get out of edit mode
            _inEditMode = FALSE;
            [_vaultTableView setEditing:FALSE animated:YES];
        }
    }
}

// Update the visibility of the search button
-(void)updateSearchButtons:(BOOL)show
{
    _searchNextButton.hidden = [[PasswordVault sharedInstance].lastSearchResults count] <= 1;
    _searchCancelButton.hidden = !show && _searchNextButton.hidden == TRUE;
}

// Handle when the user searches for an item
- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    // NOTE: do this first to properly update buttons
    if ([searchText isEqualToString:@""]) {
        [[PasswordVault sharedInstance] clearLastSearchResults];
    }
    
    _searchOffset = 0;
    [self searchForItem:searchText];
    
    // do this last to properly update buttons
    [self updateSearchButtons:searchText.length > 0];
}

-(void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self updateSearchButtons:FALSE];
    [self searchForItem:searchBar.text];
    [searchBar resignFirstResponder];
}

-(void)searchBarTextDidEndEditing:(UISearchBar*)searchBar
{
    // NOTE: do this first to properly update buttons
    if ([searchBar.text isEqualToString:@""]) {
        [[PasswordVault sharedInstance] clearLastSearchResults];
    }
    
    _searchOffset = 0;
    [self searchForItem:searchBar.text];
    
    // do this last to properly update buttons
    [self updateSearchButtons:searchBar.text.length > 0];
}

// Handles searching for the item and setting the content offset
-(BOOL)searchForItem:(NSString*)text
{
    BOOL result = FALSE;
    
    // Find the item that matches the text
    _searchOffset = [[PasswordVault sharedInstance] searchForItem:text withOffset:_searchOffset];
    NSIndexPath* path = [[PasswordVault sharedInstance] getSearchResultIndexPath:_searchOffset];
    
    if (path != nil && ![text isEqualToString:@""])
    {
        _scrollOffset = _vaultTableView.contentOffset;
        
        int row = path.row;
        int sec = path.section;
        
        UITableViewCell *cell = [_vaultTableView cellForRowAtIndexPath:path];
        
        // if we can't find the cell its because it is not visible
        if (cell == nil)
        {
            float offset = sec * (kHeightForHeader + kHeightForFooter);
            for (int i = 0; i < sec; ++i)
            {
                offset += [_vaultTableView numberOfRowsInSection:i] * kHeightForCell;
            }
            offset += row * kHeightForCell;
            
            _vaultTableView.contentOffset = CGPointMake(0, offset);
            
            // re-attempt to get the cell now that our position has changed
            cell = [_vaultTableView cellForRowAtIndexPath:path];
        }
        
        // if we still can't find the cell, then reset the offset
        if (cell == nil)
        {
            [_vaultTableView setContentOffset:CGPointMake(0, -kTopOffset) animated:YES];
            return FALSE;
        }
        
        CGPoint pt;
        CGRect bounds = [cell bounds];
        bounds = [cell convertRect:bounds toView:_vaultTableView];
        pt = bounds.origin;
        pt.x = 0;
        pt.y -= kTopOffset;
        [_vaultTableView setContentOffset:pt animated:YES];
        
        result = TRUE;
    }
    // If we did not find a match, reposition the table view to the top
    else
    {
        [_vaultTableView setContentOffset:CGPointMake(0, -kTopOffset) animated:YES];
    }
    
    // This will effectively hide the keyboard when the user backspaces all the way to the beginning of the string
    //if ([text isEqualToString:@""])
    //{
    //    [_vaultSearchBar resignFirstResponder];
    //}

    // return if we found an item or not
    return result;
}

@end
