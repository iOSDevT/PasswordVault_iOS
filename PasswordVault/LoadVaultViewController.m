//
//  LoadVaultViewController.m
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "AutoLockViewController.h"
#import "CustomTableViewCell.h"
#import "MainViewController.h"
#import "LoadVaultViewController.h"
#import "NewVaultViewController.h"
#import "PasswordVault.h"
#import "PasswordVaultViewController.h"
#import "Strings.h"
#import "Utility.h"

#import "QuartzCore/QuartzCore.h"

static const float kHeightForHeader = 32;
static const float kHeightForFooter = 32;

@interface LoadVaultViewController(Private)
-(void)enableChangePasswordCellButton:(BOOL)enabled;
-(void)enableDuplicateVaultCellButton:(BOOL)enabled;
-(void)enableRenameVaultCellButton:(BOOL)enabled;
-(void)updateCellChangePasswordButtons;
-(void)updateCellDuplicateVaultButtons;
-(void)updateCellRenameVaultButtons;
-(UIButton*)getChangePasswordButton:(UITableViewCell*)cell outIndex:(int*)index;
-(UIButton*)getDuplicateVaultButton:(UITableViewCell*)cell outIndex:(int*)index;
-(void)buildFilesAvailableForLoad:(NSArray*)files;
-(BOOL)duplicateVault:(NSString*)newVaultName;
-(BOOL)renameVault:(NSString*)newVaultName;
-(NSString*)getBaseFilename:(NSString*)source;
@end

@implementation LoadVaultViewController

// Main init func called when the nib is loaded by name
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        _selectedRow = -1;
        _alertView = nil;
        _inEditMode = FALSE;
        _changePasswordRequested = FALSE;
        _duplicateVaultRequested = FALSE;
        _renameVaultRequested = FALSE;
        _activeDuplicateVaultRow = -1;
        _activeChangePasswordRow = -1;
        _activeRenameVaultRow = -1;
        _filenameToDelete = nil;
        _fileRowToDelete = -1;
        _filenameToDuplicate = nil;
        _fileRowToDuplicate = -1;
        _filenameToRename = nil;
        _fileRowToRename = -1;
        _changePasswordCellButton = nil;
        _duplicateVaultCellButton = nil;
        _renameVaultCellButton = nil;
        _duplicatingVault = FALSE;
        _editingVaultPassword = FALSE;
        _renamingVault = FALSE;
    }
    return self;
}

// custom delete method
-(void)dealloc
{
    [_filesAvailableForLoad release];
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
    
    // Set the title for the navigation item
    self.title = @"Load Vault";
    
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
    
    UIImage* editImage = [[UIImage imageNamed:@"EditIcon.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIButton* btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnEdit setBackgroundImage:editImage forState:UIControlStateNormal];
    [btnEdit addTarget:self action:@selector(handleEditButton:) forControlEvents:UIControlEventTouchUpInside];
    btnEdit.frame = CGRectMake(0, 0, 32, 32);
    
    UIBarButtonItem* btnEditItem = [[UIBarButtonItem alloc] initWithCustomView:btnEdit];
    
    NSArray* leftArray = [NSArray arrayWithObjects:btnBackItem, btnHintItem, nil];
    self.navigationItem.leftBarButtonItems = leftArray;
    self.navigationItem.rightBarButtonItem = btnEditItem;
    
    // Set cell border
    _fileTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _fileTableView.separatorColor = [UIColor whiteColor];
    _fileTableView.separatorInset = UIEdgeInsetsZero;
    
    [btnEdit release];
    [btnBack release];
    [btnHint release];
    [btnEditItem release];
    [btnBackItem release];
    [btnHintItem release];
}

// Called when the view is about to be removed from memory
-(void)viewDidUnload
{
    [super viewDidUnload];
    
    // free the array
    [_filesAvailableForLoad release];
}

// Perform custom init of objects
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Lookup all password vault files saved in the bundle
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are to use the fallback directory then load files from that path
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    // build this list
    [self buildFilesAvailableForLoad:passwordVaultFiles];
    
    _inEditMode = FALSE;
    [_fileTableView setEditing:FALSE animated:YES];
    
    // force the table to recompile
    [_fileTableView reloadData];
    
    // set the title
    [[Utility sharedInstance] adjustTitleView:self
                                withStringKey:@"loadVaultViewController"
                                 withMaxWidth:220.0f
                              andIsLargeTitle:TRUE
                                 andAlignment:NSTextAlignmentLeft];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    pDelegate.mainViewController.LastViewController = self;
    
    // Unset the view
    _alertView = nil;
}

// Defines how to handle the rotation of the scene
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Returns the base filename
-(NSString*)getBaseFilename:(NSString*)source
{
    NSString* shortFilename = (NSString*)[[source componentsSeparatedByString:@"/"] lastObject];
    NSRange range;
    range.location = 0;
    range.length = [shortFilename length] - 4;
    
    // return the empty string in this case
    if ((int)range.length < 0) {
        return @"";
    }
    
    return [shortFilename substringWithRange:range];
}

// Builds the list of files that can be loaded
-(void)buildFilesAvailableForLoad:(NSArray*)files
{
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    
    if (_filesAvailableForLoad != nil) {
        [_filesAvailableForLoad removeAllObjects];
        [_filesAvailableForLoad release];
    }
    
    // modify each of the entries to contain only the name of the file with no path and extension
    NSMutableArray* passwordVaultAdjustedFiles = [NSMutableArray array];
    for (NSString* filename in files)
    {
        // retrieve the filename by the last object separated by a slash
        NSString* filenameNoPath = [[filename componentsSeparatedByString:@"/"] lastObject];
        NSMutableString* adjustedFilename = [NSMutableString stringWithString:filenameNoPath];
        
        // use the range to strip off the extension
        NSRange range = [adjustedFilename rangeOfString:[NSString stringWithFormat:@".%@", passwordVaultExt]];
        [adjustedFilename deleteCharactersInRange:range];
        
        // insert the newly formatted filename
        [passwordVaultAdjustedFiles addObject:[NSString stringWithString:adjustedFilename]];
    }
    
    // now set the variable to the adjusted filenames for use
    _filesAvailableForLoad = [[NSMutableArray arrayWithArray:passwordVaultAdjustedFiles] retain];
}

// Returns the number of sections in the table view
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 1;
}

// Sets the text for the delet confirmation view
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[Strings sharedInstance] lookupString:@"deleteButton"];
}

// Sets the title text for header for the table view
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[Strings sharedInstance] lookupString:@"loadVaultTableViewHeader"];
}

// Sets the title text for the footer for the table view
-(NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    return [[Strings sharedInstance] lookupString:@"loadVaultTableViewFooter"];
}

// Returns the number of rows we should have based on the table view
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_filesAvailableForLoad count];
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
    // Setup the cell...
    if(indexPath.section == 0)
    {
        [[Utility sharedInstance] determineAndSetFontForTableviewCell:cell.textLabel
                                                             withText:[_filesAvailableForLoad objectAtIndex:indexPath.row]
                                                          andMaxWidth:[Utility sharedInstance].tableviewCellTextWidth
                                                             andIsTip:FALSE];
        cell.textLabel.text = [_filesAvailableForLoad objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.imageView.image = [UIImage imageNamed:@"SmallLock.png"];
        cell.userInteractionEnabled = TRUE;
    }
    
    cell.textLabel.textColor = kTextColor;
    cell.backgroundColor = indexPath.row % 2 == 0 ? kColorOne : kColorTwo;
    
    // Create a button to change the password of a vault
    UIButton* copyBtn = (UIButton*)[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject: _changePasswordButton]];
    [copyBtn addTarget:self action:@selector(onChangePassword:) forControlEvents:UIControlEventTouchUpInside];
    [copyBtn setTag:indexPath.row];
    [copyBtn setFrame:CGRectMake(280, 10, 24, 24)];
    
    // Create a button to duplicate the vault
    UIButton* duplicateButton = (UIButton*)[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:_duplicateVaultButton]];
    [duplicateButton addTarget:self action:@selector(onDuplicateVault:) forControlEvents:UIControlEventTouchUpInside];
    [duplicateButton setTag:100 + indexPath.row];
    [duplicateButton setFrame:CGRectMake(250, 10, 24, 24)];
    
    // Create a button to duplicate the vault
    UIButton* renameButton = (UIButton*)[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:_renameVaultButton]];
    [renameButton addTarget:self action:@selector(onRenameVault:) forControlEvents:UIControlEventTouchUpInside];
    [renameButton setTag:1000 + indexPath.row];
    [renameButton setFrame:CGRectMake(220, 10, 24, 24)];
    
    // first we remove the old button (if there is one) before adding the copied button to the subviews
    int viewIndex = 0;
    UIButton* curButton = [self getChangePasswordButton:cell outIndex:&viewIndex];
    if (curButton != nil) {
        [curButton removeFromSuperview];
    }
    
    // first remove the old button
    UIButton* dupButton = [self getDuplicateVaultButton:cell outIndex:&viewIndex];
    if (dupButton != nil) {
        [dupButton removeFromSuperview];
    }
    
    // first remove the old button
    UIButton* nameButton = [self getRenameVaultButton:cell outIndex:&viewIndex];
    if (nameButton != nil) {
        [nameButton removeFromSuperview];
    }
    
    [cell.contentView addSubview:copyBtn];
    [cell.contentView addSubview:duplicateButton];
    [cell.contentView addSubview:renameButton];

    // return the created cell
    return cell;
}

// Checks if we can use this vault name
+(BOOL)isVaultNameUsed:(NSString*)name
{
    // Build the files list from the stored resources
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, name, kPasswordVaultExtension];
    for (NSString* file in passwordVaultFiles) {
        if ([file rangeOfString:fullPath].location != NSNotFound) {
            return TRUE;
        }
    }
    
    return FALSE;
}

// If we get here the user wants to duplicate the vault with the name specified.
// It is also possible that the newVaultName matches the name of an existing vault,
// this is okay since we will not get here until the user confirms the overwrite that
// would occur
-(BOOL)duplicateVault:(NSString*)newVaultName
{
    // Build the files list from the stored resources
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
  
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
    }
    
    // Attempt to duplicate
    NSString* newFullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, newVaultName, kPasswordVaultExtension];
    if (![[NSFileManager defaultManager] copyItemAtPath:_filenameToDuplicate toPath:newFullPath error:nil]) {
        return FALSE;
    }
    
    // Now that we saved our duplicate, update the list of loaded files
    passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    [self buildFilesAvailableForLoad:passwordVaultFiles];
    [_fileTableView reloadData];
    
    return TRUE;
}

// If we get here the user has chosen to rename the vault
-(BOOL)renameVault:(NSString*)newVaultName
{
    // Build the files list from the stored resources
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
    }
    
    // Attempt to rename by duplicating
    NSString* newFullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, newVaultName, kPasswordVaultExtension];
    if (![[NSFileManager defaultManager] copyItemAtPath:_filenameToRename toPath:newFullPath error:nil]) {
        return FALSE;
    }
    
    // If we rename succesfully, then we want to delete the old one
    [[NSFileManager defaultManager] removeItemAtPath:_filenameToRename error:nil];
    
    // Now that we saved our duplicate, update the list of loaded files
    passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    [self buildFilesAvailableForLoad:passwordVaultFiles];
    [_fileTableView reloadData];
    
    return TRUE;
}

// The user clicked on the rename button
-(void)onRenameVault:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIButton* btn = (UIButton*)sender;
    _renameVaultCellButton = [btn retain];
    
    _activeRenameVaultRow = btn.tag - 1000;
    
    _renamingVault = TRUE;
    
    // Build the files list from the stored resources
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    _filenameToRename = [[passwordVaultFiles objectAtIndex:btn.tag - 1000] retain];
    _fileRowToRename = btn.tag - 1000;
    
    NSString* title = [[Strings sharedInstance] lookupString:@"renameVault"];
    NSString* message = [[Strings sharedInstance] lookupString:@"renameVaultMessage"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    // release the ref to the alertview
    //[alertView release];
    // Actually show the alert view
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.secureTextEntry = NO;
    
    [self updateCellChangePasswordButtons];
    [self updateCellDuplicateVaultButtons];
    [self updateCellRenameVaultButtons];
    
    [self enableChangePasswordCellButton:FALSE];
    [self enableDuplicateVaultCellButton:FALSE];
    [self enableRenameVaultCellButton:FALSE];
    
    _alertType = kAlertType_RenameVault;
    [_alertView show];
}

// The user clicked on the duplicate button
-(void)onDuplicateVault:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIButton* btn = (UIButton*)sender;
    _duplicateVaultCellButton = [btn retain];
    
    _activeDuplicateVaultRow = btn.tag - 100;
    
    _duplicatingVault = TRUE;
    
    // Build the files list from the stored resources
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
    NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    
    // if we are using the fallback directory then delete from there
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
    }
    
    _filenameToDuplicate = [[passwordVaultFiles objectAtIndex:btn.tag - 100] retain];
    _fileRowToDuplicate = btn.tag - 100;
    
    NSString* title = [[Strings sharedInstance] lookupString:@"duplicateVault"];
    NSString* message = [[Strings sharedInstance] lookupString:@"duplicateVaultMessage"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    // release the ref to the alertview
    //[alertView release];
    // Actually show the alert view
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.secureTextEntry = NO;
    
    [self updateCellChangePasswordButtons];
    [self updateCellDuplicateVaultButtons];
    [self updateCellRenameVaultButtons];
    
    [self enableChangePasswordCellButton:FALSE];
    [self enableDuplicateVaultCellButton:FALSE];
    [self enableRenameVaultCellButton:FALSE];
    
    _alertType = kAlertType_DuplicateVault;
    [_alertView show];
}

-(void)onChangePassword:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIButton* btn = (UIButton*)sender;
    _changePasswordCellButton = btn;
    
    _activeChangePasswordRow = btn.tag;
    
    _editingVaultPassword = TRUE;
    
    // Attempt to load the vault with the valid password and name
    //BOOL success = [[PasswordVault sharedInstance] loadVault:basefilename withPassword:textField.text];
    
    NSString* title = [[Strings sharedInstance] lookupString:@"editVaultPassword"];
    NSString* subTitle = [[Strings sharedInstance] lookupString:@"enterCurrentPassword"];
    NSString* fullTitle = [NSString stringWithFormat:@"%@\n%@", title, subTitle];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:fullTitle
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    // release the ref to the alertview
    //[alertView release];
    // Actually show the alert view
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.secureTextEntry = YES;

    [self updateCellChangePasswordButtons];
    [self updateCellDuplicateVaultButtons];
    [self updateCellRenameVaultButtons];
    
    [self enableChangePasswordCellButton:FALSE];
    [self enableDuplicateVaultCellButton:FALSE];
    [self enableRenameVaultCellButton:FALSE];
 
    _alertType = kAlertType_ChangePassword;
    [_alertView show];
}

// Enables/Disables the change password button on the currently selected cell
-(void)enableChangePasswordCellButton:(BOOL)enabled
{
    if (_changePasswordCellButton != nil) {
        _changePasswordCellButton.enabled = enabled;
        _changePasswordCellButton.hidden = !enabled;
    }
    
    if (enabled) {
        _changePasswordCellButton = nil;
    }
}

// Enables/Disables the duplicate vault button on the currently selected cell
-(void)enableDuplicateVaultCellButton:(BOOL)enabled
{
    if (_duplicateVaultCellButton != nil) {
        _duplicateVaultCellButton.enabled = enabled;
        _duplicateVaultCellButton.hidden = !enabled;
    }
    
    if (enabled && _duplicateVaultCellButton != nil) {
        [_duplicateVaultCellButton release];
        _duplicateVaultCellButton = nil;
    }
}

// Enables/Disables the duplicate vault button on the currently selected cell
-(void)enableRenameVaultCellButton:(BOOL)enabled
{
    if (_renameVaultCellButton != nil) {
        _renameVaultCellButton.enabled = enabled;
        _renameVaultCellButton.hidden = !enabled;
    }
    
    if (enabled && _renameVaultCellButton != nil) {
        [_renameVaultCellButton release];
        _renameVaultCellButton = nil;
    }
}

// Handle when the user makes a selection
- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (_alertView != nil)
    {
        return;
    }
    
    // save the selected row
    _selectedRow = indexPath.row;
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"enterVaultPassword"]
                                                        message:@"" 
                                                       delegate:self 
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;

    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    if (indexPath != nil) {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        UIButton* btn = [self getChangePasswordButton:cell outIndex:nil];
        _changePasswordRequested = btn != nil ? btn.selected : FALSE;
        
        UIButton* dupBtn = [self getDuplicateVaultButton:cell outIndex:nil];
        _duplicateVaultRequested = dupBtn != nil ? dupBtn.selected : FALSE;
        
        UIButton* nameBtn = [self getRenameVaultButton:cell outIndex:nil];
        _renameVaultRequested = nameBtn != nil ? nameBtn.selected : FALSE;
    }
    
    // release the ref to the alertview
    //[alertView release];
    // Actually show the alert view
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.secureTextEntry = YES;
    
    _alertType = kAlertType_EnterPassword;
    [_alertView show];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, kHeightForHeader)];
    NSString* text = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"loadVaultTableViewHeader"]];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, rect.size.width, kHeightForHeader)];
    [label setText:text];
    label.opaque = NO;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentLeft;
    [[Utility sharedInstance] determineAndSetFontForTableviewHeaderFooter:label
                                                                 withText:[[Strings sharedInstance] lookupString:@"loadVaultTableViewHeader"]
                                                              andMaxWidth:[Utility sharedInstance].tableviewHeaderFooterTextWidth
                                                                 andIsTip:FALSE];
    
    view.backgroundColor = [UIColor blackColor];
    [view addSubview:label];
	return view;
}

-(IBAction)onPasswordChangedSelected:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UIButton* btn = (UIButton*)sender;
    [btn setSelected:!btn.selected];
}

-(UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, kHeightForFooter)];
    NSString* text = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"loadVaultTableViewFooter"]];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, rect.size.width, kHeightForFooter)];
    [label setText:text];
    label.opaque = NO;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentLeft;
    [[Utility sharedInstance] determineAndSetFontForTableviewHeaderFooter:label
                                                                 withText:[[Strings sharedInstance] lookupString:@"loadVaultTableViewFooter"]
                                                              andMaxWidth:[Utility sharedInstance].tableviewHeaderFooterTextWidth
                                                                 andIsTip:FALSE];
    
    view.backgroundColor = [UIColor blackColor];
    [view addSubview:label];
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

// Handle when an item is deleted from the list
-(void)tableView:(UITableView *)aTableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Build the files list from the stored resources
        NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString* passwordVaultExt = [NSString stringWithCString:kPasswordVaultExtension encoding:NSASCIIStringEncoding];
        NSArray* passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
        
        // if we are using the fallback directory then delete from there
        if ([MainViewController useFallbackDirectory]) {
            directory = [MainViewController fallbackDirectory];
            passwordVaultFiles = [NSBundle pathsForResourcesOfType:passwordVaultExt inDirectory:directory];
        }
        
        _filenameToDelete = [[passwordVaultFiles objectAtIndex:indexPath.row] retain];
        _fileRowToDelete = indexPath.row;
        
        [self showAreYouSureAlert];
    } 
}

// shows the are you sure dialog
-(void)showAreYouSureAlert
{
    // Get base filename without extension
    NSString* baseFile = [self getBaseFilename:_filenameToDelete];
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"alertDeleteVault"], baseFile];
    NSString* title = [[Strings sharedInstance] lookupString:@"alertDeleteVaultTitle"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"deleteButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _alertType = kAlertType_AreYouSureAlert;
}

// Shows the alert view informing the user that we have a vault with the same name
-(void)showRenameOverwriteFileAlert:(NSString*)newFilename
{
    // Get base filename without extension
    NSString* baseFile = [self getBaseFilename:newFilename];
    NSString* title = [NSString stringWithFormat:@"%@\n%@", [[Strings sharedInstance] lookupString:@"overwriteRenameFile"], baseFile];
    NSString* message = [[Strings sharedInstance] lookupString:@"overwriteRenameFileMessage"];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _alertType = kAlertType_RenameVaultOverwrite;
}

// Shows the alert view informing the user that we have a vault with the same name
-(void)showRenameInvalidNameFileAlert:(NSString*)newFilename
{
    // Get base filename without extension
    NSString* title = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"invalidNameRenameFile"]];
    NSString* message = [[Strings sharedInstance] lookupString:@"invalidNameRenameMessage"];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _alertType = kAlertType_RenameVaultInvalidName;
}


// Shows the alert view informing the user that we have a vault with the same name
-(void)showDuplicateOverwriteFileAlert
{
    // Get base filename without extension
    NSString* baseFile = [self getBaseFilename:_filenameToDuplicate];
    NSString* title = [NSString stringWithFormat:@"%@\n%@", [[Strings sharedInstance] lookupString:@"overwriteDuplicateFile"], baseFile];
    NSString* message = [[Strings sharedInstance] lookupString:@"overwriteDuplicateFileMessage"];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _alertType = kAlertType_DuplicateVaultOverwrite;
}

// Handle when the use enters an invalid name
-(void)showDuplicateInvalidNameFileAlert
{
    // Get base filename without extension
    NSString* title = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"invalidNameDuplicateFile"]];
    NSString* message = [[Strings sharedInstance] lookupString:@"invalidNameDuplicateMessage"];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    [alertView show];
    [alertView release];
    
    _alertType = kAlertType_DuplicateVaultInvalidName;
}

// Show the rename success message
-(void)showRenameVaultSuccess:(NSString*)newFilename
{
    // Get base filename without extension
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"renameVaultSuccessMessage"], @"\n", newFilename];
    NSString* title = [[Strings sharedInstance] lookupString:@"renameVaultSuccess"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _alertType = kAlertType_RenameVaultSuccess;
}

// Show the success message
-(void)showDuplicateVaultSuccess:(NSString*)newFilename
{
    // Get base filename without extension
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"duplicateVaultSuccessMessage"], @"\n", newFilename];
    NSString* title = [[Strings sharedInstance] lookupString:@"duplicateVaultSuccess"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _alertType = kAlertType_DuplicateVaultSuccess;
}

// Shows the alert view for when an error occurs when renaming a vault
-(void)showRenameVaultErrorAlert
{
    // Get base filename without extension
    NSString* baseFile = [self getBaseFilename:_filenameToRename];
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"renameVaultErrorMessage"], baseFile];
    NSString* title = [[Strings sharedInstance] lookupString:@"renameVaultError"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _alertType = kAlertType_RenameVaultError;
}

// Shows the alert view for when an error occurs when copying a vault
-(void)showDuplicateVaultErrorAlert
{
    // Get base filename without extension
    NSString* baseFile = [self getBaseFilename:_filenameToDuplicate];
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"duplicateVaultErrorMessage"], baseFile];
    NSString* title = [[Strings sharedInstance] lookupString:@"duplicateVaultError"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    // Actually show the alert view
    [alertView show];
    [alertView release];
    
    // show the are you sure alert
    _alertType = kAlertType_DuplicateVaultError;
}

// Called when we finish editing in the textfield and we want to hide the alertview
-(void)alertViewTextFieldPressDone:(UITextField*)sender;
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    UITextField* textField = (UITextField*)sender;
    [textField.superview resignFirstResponder];
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    // the user cancelled, do nothing
    if (buttonIndex == 0)
    {
        [self enableChangePasswordCellButton:TRUE];
        [self enableDuplicateVaultCellButton:TRUE];
        [self enableRenameVaultCellButton:TRUE];
        
        _alertView = nil;
        
        // if we cancelled the enter password alert, reset the selected row
        if (_alertType == kAlertType_EnterPassword) {
            NSIndexPath* path = [NSIndexPath indexPathForRow:_selectedRow inSection:0];
            [_fileTableView deselectRowAtIndexPath:path animated:FALSE];
        }
        else if (_alertType == kAlertType_ChangePassword ||
                 _alertType == kAlertType_ChangePasswordFailure ||
                 _alertType == kAlertType_EnterNewPassword ||
                 _alertType == kAlertType_ChangePasswordLengthMismatch ||
                 _alertType == kAlertType_ChangePasswordMismatch ||
                 _alertType == kAlertType_ChangePasswordMatch) {
            _editingVaultPassword = FALSE;
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
        }
        else if (_alertType == kAlertType_AreYouSureAlert) {
            [_filenameToDelete release];
            _filenameToDelete = nil;
            _fileRowToDelete = -1;
            
            // get out of edit mode
            _inEditMode = FALSE;
            [_fileTableView setEditing:FALSE animated:YES];
            
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
        }
        else if (_alertType == kAlertType_DuplicateVault ||
                 _alertType == kAlertType_DuplicateVaultError ||
                 _alertType == kAlertType_DuplicateVaultOverwrite ||
                 _alertType == kAlertType_DuplicateVaultInvalidName ||
                 _alertType == kAlertType_DuplicateVaultSuccess) {
            
            _duplicatingVault = FALSE;
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [_filenameToDuplicate release];
            _filenameToDuplicate = nil;
            _fileRowToDuplicate = -1;
        }
        else if (_alertType == kAlertType_RenameVault ||
                 _alertType == kAlertType_RenameVaultError ||
                 _alertType == kAlertType_RenameVaultOverwrite ||
                 _alertType == kAlertType_RenameVaultInvalidName ||
                 _alertType == kAlertType_RenameVaultSuccess) {
            
            _renamingVault = FALSE;
        
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [_filenameToRename release];
            _filenameToRename = nil;
            _fileRowToRename = -1;
        }
    }
    // try to load the vault file selected with the password given
    else if (buttonIndex == 1)
    {
        // If we get here then the user has requested to delete an entire password vault
        if (_alertType == kAlertType_AreYouSureAlert) {
            
            // Actually delete the file resource from memory
            [[NSFileManager defaultManager] removeItemAtPath:_filenameToDelete error:nil];
            
            // remove the info from the stored array
            [_filesAvailableForLoad removeObjectAtIndex:_fileRowToDelete];
            
            // unset delete fields
            [_filenameToDelete release];
            _filenameToDelete = nil;
            _fileRowToDelete = -1;
            
            // get out of edit mode
            _inEditMode = FALSE;
            [_fileTableView setEditing:FALSE animated:YES];
            [_fileTableView reloadData];
        }
        else if (_alertType == kAlertType_DuplicateVault) {
            UITextField* textField = [alertView textFieldAtIndex:0];
            NSString* newFilename = textField.text;
            
            if ([LoadVaultViewController isVaultNameUsed:newFilename]) {
                [self showDuplicateOverwriteFileAlert];
            }
            else if (newFilename == nil || newFilename.length == 0) {
                [self showDuplicateInvalidNameFileAlert];
            }
            else {
                if (![self duplicateVault:newFilename]) {
                    [self showDuplicateVaultErrorAlert];
                }
                else {
                    [self showDuplicateVaultSuccess:newFilename];
                    
                    [_filenameToDuplicate release];
                    _filenameToDuplicate = nil;
                    _fileRowToDuplicate = -1;
                    
                    _alertView = nil;
                }
            }
        }
        else if (_alertType == kAlertType_RenameVault) {
            UITextField* textField = [alertView textFieldAtIndex:0];
            NSString* newFilename = textField.text;
            
            if ([LoadVaultViewController isVaultNameUsed:newFilename]) {
                [self showRenameOverwriteFileAlert:newFilename];
            }
            else if (newFilename == nil || newFilename.length == 0) {
                [self showRenameInvalidNameFileAlert:newFilename];
            }
            else {
                if (![self renameVault:newFilename]) {
                    [self showRenameVaultErrorAlert];
                }
                else {
                    [self showRenameVaultSuccess:newFilename];
                    
                    [_filenameToRename release];
                    _filenameToRename = nil;
                    _fileRowToRename = -1;
                    
                    _alertView = nil;
                }
            }
        }
        else if (_alertType == kAlertType_EnterPassword || _alertType == kAlertType_ChangePassword)
        {
            int row = _alertType == kAlertType_EnterPassword ? _selectedRow : _activeChangePasswordRow;
            NSString* basefilename = [_filesAvailableForLoad objectAtIndex:row];
            UITextField *textField = [alertView textFieldAtIndex:0];
            BOOL success = FALSE;
            
            // Attempt to load the vault with the valid password and name
            success = [[PasswordVault sharedInstance] loadVault:basefilename
                                                   withPassword:textField.text
                                      fromChangePasswordRequest:_alertType == kAlertType_ChangePassword];
            
            // Move on to the next view controller on success
            if (success == TRUE)
            {
                if (_alertType == kAlertType_EnterPassword) {
                    UITableViewCell* cell = [[_fileTableView visibleCells] objectAtIndex:row];
                    cell.imageView.image = [UIImage imageNamed:@"image197.png"];
                    
                    for (UITableViewCell* cell in [_fileTableView visibleCells])
                    {
                        cell.userInteractionEnabled = FALSE;
                    }
                    
                    // Fire off the call to advance to the next screen after we let the user see the image
                    // on the cell change first.
                    [self performSelector:@selector(onLoadVaultSuccess) withObject:nil afterDelay:1.00f];
                    
                    _alertView = nil;
                }
                else if (_alertType == kAlertType_ChangePassword) {
                    [self performSelector:@selector(onChangePasswordEnteredSuccess) withObject:nil afterDelay:1.0F];
                }
            }
            else {
                // Show error modal
                if (_alertType == kAlertType_ChangePassword) {
                    [self performSelector:@selector(onChangePasswordEnteredFailure) withObject:nil afterDelay:1.0F];
                }
                else if (_alertType == kAlertType_EnterPassword) {
                    NSIndexPath* path = [NSIndexPath indexPathForRow:_selectedRow inSection:0];
                    [_fileTableView deselectRowAtIndexPath:path animated:FALSE];
                    
                    _alertView = nil;
                }
            }
        }
        // Handle the new password change request
        else if (_alertType == kAlertType_EnterNewPassword)
        {
            NSString* password1 = [_alertView textFieldAtIndex:0].text;
            NSString* password2 = [_alertView textFieldAtIndex:1].text;
            
            if (password1.length < kVaultPasswordMinLimit || password1.length > kVaultPasswordMaxLimit) {
                [self performSelector:@selector(onChangePasswordIncorrectLength) withObject:nil afterDelay:1.0F];
            }
            else if ([password1 isEqualToString:password2])
            {
                [[PasswordVault sharedInstance] saveVaultNewPassword:password1];
                _alertView = nil;
                [self performSelector:@selector(onChangePasswordMatch) withObject:nil afterDelay:1.0F];
            }
            else
            {
                [self performSelector:@selector(onChangePasswordMismatch) withObject:nil afterDelay:1.0F];
            }
        }
        else if (_alertType == kAlertType_ChangePasswordFailure) {
            _alertView = nil;
            _editingVaultPassword = FALSE;
            
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [self enableChangePasswordCellButton:TRUE];
            [self enableDuplicateVaultCellButton:TRUE];
            [self enableRenameVaultCellButton:TRUE];
        }
        else if (_alertType == kAlertType_ChangePasswordLengthMismatch) {
            _alertView = nil;
            _editingVaultPassword = FALSE;
            
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [self enableChangePasswordCellButton:TRUE];
            [self enableDuplicateVaultCellButton:TRUE];
            [self enableRenameVaultCellButton:TRUE];
        }
        else if (_alertType == kAlertType_ChangePasswordMismatch) {
            _alertView = nil;
            _editingVaultPassword = FALSE;
            
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [self enableChangePasswordCellButton:TRUE];
            [self enableDuplicateVaultCellButton:TRUE];
            [self enableRenameVaultCellButton:TRUE];
        }
        else if (_alertType == kAlertType_ChangePasswordMatch) {
            _alertView = nil;
            _editingVaultPassword = FALSE;
            
            [self updateCellChangePasswordButtons];
            [self updateCellDuplicateVaultButtons];
            [self updateCellRenameVaultButtons];
            
            [self enableChangePasswordCellButton:TRUE];
            [self enableDuplicateVaultCellButton:TRUE];
            [self enableRenameVaultCellButton:TRUE];
        }
    }
}

// Handle when the vault loads completely
-(void)onLoadVaultSuccess
{    
    AppDelegate* pDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    PasswordVaultViewController* pPasswordVaultViewController = [pDelegate mainViewController].PasswordVaultViewController;
    [[pDelegate navigationController] pushViewController:pPasswordVaultViewController animated:YES];
    
    // begin the auto-lock timeout
    [pDelegate.mainViewController.AutoLockViewController resetAutoLockTimeout];
}

// Called when the user enters the wrong vault password
-(void)onChangePasswordEnteredFailure
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertChangePasswordError2Title"];
    NSString* message = [[Strings sharedInstance] lookupString:@"alertChangePasswordError2"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    _alertType = kAlertType_ChangePasswordFailure;
    [_alertView show];
}

-(void)onChangePasswordIncorrectLength
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertNewPasswordFailureTitle"];
    NSString* message = [NSString stringWithFormat:[[Strings sharedInstance] lookupString:@"alertNewPasswordFailure"], kVaultPasswordMinLimit, kVaultPasswordMaxLimit];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"okButton"]
                                              otherButtonTitles:nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    _alertType = kAlertType_ChangePasswordLengthMismatch;
    [_alertView show];}

-(void)onChangePasswordMatch
{
    NSString* message = [[Strings sharedInstance] lookupString:@"alertChangePasswordSuccess"];
    NSString* title = [[Strings sharedInstance] lookupString:@"alertChangePasswordSuccessTitle"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    _alertType = kAlertType_ChangePasswordMatch;
    [_alertView show];

}

// Called when changing a new password and the passwords dont match
-(void)onChangePasswordMismatch
{
    NSString* message = [[Strings sharedInstance] lookupString:@"alertChangePasswordError"];
    NSString* title = [[Strings sharedInstance] lookupString:@"alertChangePasswordErrorTitle"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    _alertType = kAlertType_ChangePasswordMismatch;
    [_alertView show];
}

-(void)onChangePasswordEnteredSuccess
{
    NSString* title = [[Strings sharedInstance] lookupString:@"alertEnterNewPasswordTitle"];
    
    // Create a popup to enter the password for the file selected
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:[[Strings sharedInstance] lookupString:@"cancelButton"]
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];
    
    // store the view
    _alertView = alertView;
    _alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    // Translate the alert view so that its position is consistent with where it will
    // translate to when the keyboard becomes hidden
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -108.0f);
    [alertView setTransform:transform];
    
    // We have to adjust the frame of the alert view after we show it, otherwise,
    // the changes do not take effect
    CGRect alertViewFrame = alertView.frame;
    alertViewFrame.size.height += 32.0f;
    alertViewFrame.origin.y -= 16.0f;
    [alertView setFrame:alertViewFrame];
    
    // release the ref to the alertview
    //[alertView release];
    // Actually show the alert view
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.secureTextEntry = YES;
    [textField setPlaceholder:[[Strings sharedInstance] lookupString:@"enterNewPasswordPlaceholder"]];
    
    UITextField *textField2 = [alertView textFieldAtIndex:1];
    textField2.secureTextEntry = YES;
    [textField2 setPlaceholder:[[Strings sharedInstance] lookupString:@"confirmNewPasswordPlaceholder"]];
    
    _alertType = kAlertType_EnterNewPassword;
    [_alertView show];
}

// Handles limiting the number of characters allowed
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > kVaultPasswordMaxLimit) ? NO : YES;
}

// Handle responding to the text field
- (void)textFieldDidChange:(UITextField*)textField
{
    ((UIButton*)[_alertView.subviews objectAtIndex:4]).enabled = (textField.text.length >= kVaultPasswordMinLimit);
}

// Handle when the user clicks on the back button
-(IBAction)handleNavigationBackButton:(id)sender  
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

// Handle the edit button being selected
-(IBAction)handleEditButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    if (_inEditMode == FALSE)
    {
        _inEditMode = TRUE;
        [_fileTableView setEditing:TRUE animated:YES];
    }
    else
    {
        _inEditMode = FALSE;
        [_fileTableView setEditing:FALSE animated:YES];
    }
    
    // Update the change password button so they are hidden during
    // edit mode
    [self updateCellChangePasswordButtons];
    [self updateCellDuplicateVaultButtons];
    [self updateCellRenameVaultButtons];
}

-(IBAction)handleHintButton:(id)sender
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    
    NSString* message = [NSString stringWithFormat:@"%@", [[Strings sharedInstance] lookupString:@"loadVaultViewControllerHint"]];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[Strings sharedInstance] lookupString:@"hintTitle"]
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:[[Strings sharedInstance] lookupString:@"okButton"], nil];

    [alertView show];
    [alertView release];
    
    _alertType = kAlertType_Hint;
}

/**
 * Retrieves the change password button found within the subviews of the cell passed in
 * @param UITableViewCell* - the cell to look within for the button
 * @return UIButton* - if successful, return the found button, othwewise, return nil
 */
-(UIButton*)getChangePasswordButton:(UITableViewCell*)cell outIndex:(int*)index
{
    for (NSInteger j = 0; j < [cell.contentView.subviews count]; ++j) {
        UIView* view = [cell.contentView.subviews objectAtIndex:j];
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* btn = (UIButton*)view;
            if (btn.tag < 100) {
                return btn;
            }
        }
    }
    return nil;
}

/**
 * Retrieves the duplicate vault button found within the subviews of the cell passed in
 * @param UITableViewCell* - the cell to look within for the button
 * @return UIButton* - if successful, return the found button, othwewise, return nil
 */
-(UIButton*)getDuplicateVaultButton:(UITableViewCell*)cell outIndex:(int*)index
{
    for (NSInteger j = 0; j < [cell.contentView.subviews count]; ++j) {
        UIView* view = [cell.contentView.subviews objectAtIndex:j];
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* btn = (UIButton*)view;
            if (btn.tag >= 100 && btn.tag < 1000) {
                return btn;
            }
        }
    }
    return nil;
}

/**
 * Retrieves the rename vault button found within the subviews of the cell passed in
 * @param UITableViewCell* - the cell to look within for the button
 * @return UIButton* - if successful, return the found button, othwewise, return nil
 */
-(UIButton*)getRenameVaultButton:(UITableViewCell*)cell outIndex:(int*)index
{
    for (NSInteger j = 0; j < [cell.contentView.subviews count]; ++j) {
        UIView* view = [cell.contentView.subviews objectAtIndex:j];
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* btn = (UIButton*)view;
            if (btn.tag >= 1000 && btn.tag < 10000) {
                return btn;
            }
        }
    }
    return nil;
}

/**
 * Updates the visibility of the change password button for all cells within the UITableView.
 * If we are in edit mode then the buttons will be hidden, otherwise they will be visible.
 */
-(void)updateCellChangePasswordButtons
{
    for (NSInteger i = 0; i < [_fileTableView numberOfRowsInSection:0]; ++i) {
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell* cell = [_fileTableView cellForRowAtIndexPath:indexPath];
        
        UIButton* btn = [self getChangePasswordButton:cell outIndex:nil];
        if (btn != nil) {
            btn.hidden = _inEditMode || _duplicatingVault || _editingVaultPassword || _renamingVault;
        }
    }
}

/**
 * Updates the visibility of the change password button for all cells within the UITableView.
 * If we are in edit mode then the buttons will be hidden, otherwise they will be visible.
 */
-(void)updateCellDuplicateVaultButtons
{
    for (NSInteger i = 0; i < [_fileTableView numberOfRowsInSection:0]; ++i) {
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell* cell = [_fileTableView cellForRowAtIndexPath:indexPath];
        
        UIButton* btn = [self getDuplicateVaultButton:cell outIndex:nil];
        if (btn != nil) {
            btn.hidden = _inEditMode || _duplicatingVault || _editingVaultPassword || _renamingVault;
        }
    }
}

/**
 * Updates the visibility of the rename vault button for all cells within the UITableView.
 * If we are in edit mode then the buttons will be hidden, otherwise they will be visible.
 */
-(void)updateCellRenameVaultButtons
{
    for (NSInteger i = 0; i < [_fileTableView numberOfRowsInSection:0]; ++i) {
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell* cell = [_fileTableView cellForRowAtIndexPath:indexPath];
        
        UIButton* btn = [self getRenameVaultButton:cell outIndex:nil];
        if (btn != nil) {
            btn.hidden = _inEditMode || _duplicatingVault || _editingVaultPassword || _renamingVault;
        }
    }
}

@end
