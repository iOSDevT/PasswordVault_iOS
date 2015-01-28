//
//  PasswordVault.m
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "NSData+CommonCrypto.h"
#import "PasswordVault.h"
#import "PasswordVaultItemList.h"
#import "Reachability.h"
#import "Singleton.h"
#import "Utility.h"

#define GENERATE_PASSWORD_LENGTH 12
#define SELECTABLE_NUMBER_COUNT 10
#define SELECTABLE_CHAR_COUNT 26
#define SELECTABLE_SPECIAL_COUNT 15

// The defaul extension for the password vault files
const char* kPasswordVaultExtension = {"pvf"};
const char* kInitVector = {"Kp12S51UoR0vA11Lt"};

static NSInteger sortItemLists(id list1, id list2, void* context);

@implementation PasswordVault

// Declare the class a singleton
SINGLETON(PasswordVault)

// bind properties
@synthesize vaultName = _vaultName;
@synthesize internetActive = _internetActive;
@synthesize hostActive = _hostActive;
@synthesize categoryComparison = _categoryComparison;
@synthesize lastSearchResults = _lastSearchResults;

// default init func
-(id)init
{
    if (self = [super init])
    {
        _vaultName = [[NSString stringWithString:@""] retain];
        _password = [[NSString stringWithString:@""] retain];
        _categories = [[NSMutableArray array] retain];
        _itemLists = [[NSMutableArray array] retain];
        _internetActive = FALSE;
        _hostActive = FALSE;
        _categoryComparison = NSOrderedDescending;
        _lastSearchResults = [[NSMutableArray arrayWithCapacity:200] retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(checkNetworkStatus:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        
        _internetReachable = [[Reachability reachabilityForInternetConnection] retain];
        [_internetReachable startNotifier];
        
        _hostReachable = [[Reachability reachabilityWithHostName: @"www.apple.com"] retain];
        [_hostReachable startNotifier];
    }
    return self;
}

// custom dealloc to free mem
-(void)dealloc
{
    [_vaultName release];
    [_password release];
    [_categories release];
    [_itemLists release];
    [_lastSearchResults release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

// creates the new vault with the password and name given
-(void)createNewVault:(NSString*)vaultName withPassword:(NSString *)password
{
    // remove all objects
    [_categories removeAllObjects];
    [_itemLists removeAllObjects];
    
    if (_categories == nil)
    {
        _categories = [[NSMutableArray array] retain];
    }
    if (_itemLists == nil)
    {
        _itemLists = [[NSMutableArray array] retain];
    }
    
    // Set the new vault name and password
    [_vaultName release];
    [_password release];
    _vaultName = [vaultName copy];
    _password = [password copy];
    
    // Save the new vault
    [self saveVault];
}

// returns the category name based on the index
-(NSString*)getCategoryName:(int)category
{
    if (category >= 0 && category < [self getCategoryCount])
    {
        return [_categories objectAtIndex:category];
    }
    return @"";
}

// returns the number of items within the category specified
-(int)getItemCountForCategory:(int)category
{
    if (category >= 0 && category < [self getCategoryCount])
    {
        PasswordVaultItemList* list = (PasswordVaultItemList*)[_itemLists objectAtIndex:category];
        return [list.items count];
    }
    return 0;
}

// returns the item name based on the category and item index
-(NSString*)getItemName:(int)category withItem:(int)item
{
    if (category >= 0 && category < [self getCategoryCount])
    {
        PasswordVaultItemList* list = (PasswordVaultItemList*)[_itemLists objectAtIndex:category];
        return ((PasswordVaultItem*)[list.items objectAtIndex:item]).title;
    }
    return @""; 
}

// returns the item name based on the category and item index
-(NSString*)getItemIcon:(int)category withItem:(int)item;
{
    if (category >= 0 && category < [self getCategoryCount])
    {
        PasswordVaultItemList* list = (PasswordVaultItemList*)[_itemLists objectAtIndex:category];
        return ((PasswordVaultItem*)[list.items objectAtIndex:item]).icon;
    }
    return @""; 
}

// returns all of the strings that are used by the items
-(NSArray*)getRelevantStringData
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self getCategoryCount]; ++i)
    {
        NSString* name = [self getCategoryName:i];
        [array addObject:name];
        
        PasswordVaultItemList* list = (PasswordVaultItemList*)[_itemLists objectAtIndex:i];
        for (int j = 0; j < [list items].count; ++j)
        {
            PasswordVaultItem* item = (PasswordVaultItem*)[list.items objectAtIndex:j];
            [array addObject:item.title];
            [array addObject:item.url];
            [array addObject:item.username];
            [array addObject:item.account];
            
            NSString* notes = item.notes;
            NSArray* noteWords = [notes componentsSeparatedByString:@" "];
            
            [array addObjectsFromArray:noteWords];
        }
    }
    
    return array;
}

// returns the number of categories in the list
-(int)getCategoryCount
{
    return [_categories count];
}

// Adds a password vault item to the items array
-(void)addItem:(PasswordVaultItem*)item
{
    NSString* category = item.category;
    
    // search for the category
    BOOL categoryFound = FALSE;
    int categoryIndex = 0;
    for (NSString* cat in _categories)
    {
        if ([cat isEqualToString:category])
        {
            categoryFound = TRUE;
            break;
        }
        categoryIndex++;
    }
    
    // If we failed to find the category then add the category to the list
    if (categoryFound == FALSE)
    {
        [_categories addObject:[NSString stringWithString:category]];
        
        PasswordVaultItemList* itemList = [PasswordVaultItemList passwordVaultItemList];
        [itemList setCategory:category];
        [itemList addItem:item];
        
        [_itemLists addObject:itemList];
    }
    else
    {
        PasswordVaultItemList* currentItemList = [_itemLists objectAtIndex:categoryIndex];
        [currentItemList addItem:item];
    }
    
    // sort categories based on current comparison value
    [self sortCategories:_categoryComparison];
    
    // Save the vault when we add an item
    [self saveVault];
}

// sorts the categories
-(void)sortCategories:(NSInteger)sortMode
{
    _categoryComparison = sortMode;
    
    [_categories sortUsingComparator:(NSComparator)^(id obj1, id obj2){;
        return sortMode == NSOrderedAscending ? [obj2 caseInsensitiveCompare:obj1] : [obj1 caseInsensitiveCompare:obj2];}];
    
    NSArray* sorted = [_itemLists sortedArrayUsingFunction:sortItemLists
                                                   context:sortMode == NSOrderedAscending ? "ascending" : "descending"];
    [_itemLists release];
    _itemLists = [[NSMutableArray arrayWithArray:sorted] retain];
}

// Helper function for sorting item lists
NSInteger sortItemLists(id list1, id list2, void* context)
{
    char* sortString = (char*)context;
    PasswordVaultItemList* itemList1 = (PasswordVaultItemList*)list1;
    PasswordVaultItemList* itemList2 = (PasswordVaultItemList*)list2;
    
    if (strcmp(sortString, "ascending") == 0) {
        return [itemList2.category caseInsensitiveCompare:itemList1.category];
    }
    return [itemList1.category caseInsensitiveCompare:itemList2.category];
}


// returns all of the categories
-(NSArray*)getCategoryNames
{
    return [NSArray arrayWithArray:_categories];
}

// returns the password vault item stored at the specified indices
-(PasswordVaultItem*)getItem:(int)category withItem:(int)item
{
    PasswordVaultItemList* vaultItemnList = (PasswordVaultItemList*)[_itemLists objectAtIndex:category];
    return [vaultItemnList.items objectAtIndex:item];
}

// removes a password vault item from the list
-(void)removeItem:(PasswordVaultItem*)item
{
    NSString* category = item.category;
    
    // find the category index
    BOOL categoryFound = FALSE;
    int categoryIndex = 0;
    for (NSString* cat in _categories)
    {
        if ([cat isEqualToString:category])
        {
            categoryFound = TRUE;
            break;
        }
        categoryIndex++;
    }
    
    NSAssert(categoryFound == TRUE, @"The vault item with category name %@ does not exist!", category);
    
    // Check the item list to see if this was the lone item for the category found
    PasswordVaultItemList* vaultItemnList = (PasswordVaultItemList*)[_itemLists objectAtIndex:categoryIndex];
    int itemCountForCategory = [vaultItemnList.items count];
    
    // if we are the only item then remove the entry from the _itemLists and _categories
    if (itemCountForCategory == 1)
    {
        [vaultItemnList.items removeObject:item];
        [_itemLists removeObjectAtIndex:categoryIndex];
        [_categories removeObjectAtIndex:categoryIndex];
    }
    // otherwise, simply remove the item from the list
    else
    {
        [vaultItemnList.items removeObject:item];
    }
    
    // Save the vault when we remove an item
    [self saveVault];
}

// Returns a list of terms that will be used for auto complete
-(NSMutableArray*)getAutoCompleteStrings:(AutoCompleteType)autoType
{
    NSMutableArray* data = [NSMutableArray array];
    switch (autoType)
    {
        // Handle category auto complete data
        case kAutoCompleteType_Category:
        {
            for (int i = 0; i < [_categories count]; i++)
            {
                NSString* category = (NSString*)[_categories objectAtIndex:i];
                if ([data containsObject:category] == FALSE)
                {
                    [data addObject:category];
                }
            }
            break;
        }
        // Handle title auto complete data
        case kAutoCompleteType_Title:
        {
            for (PasswordVaultItemList* list in _itemLists)
            {
                for (PasswordVaultItem* item in list.items)
                {
                    NSString* title = item.title;
                    if ([data containsObject:title] == FALSE)
                    {
                        [data addObject:title];
                    }
                }
            }
            break;
        }
        // Handle title auto complete data
        case kAutoCompleteType_Username:
        {
            for (PasswordVaultItemList* list in _itemLists)
            {
                for (PasswordVaultItem* item in list.items)
                {
                    NSString* title = item.username;
                    if ([data containsObject:title] == FALSE)
                    {
                        [data addObject:title];
                    }
                }
            }
            break;
        }
    }
    return data;
}

// convert to ns data
-(NSData*)convertToNSData
{
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:_categories forKey:@"category"];
    [dictionary setObject:_itemLists forKey:@"itemLists"];
    [dictionary setObject:_vaultName  forKey:@"vaultName"];
    
    NSMutableData *data = [[[NSMutableData alloc] init] autorelease];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:dictionary forKey:@"Dictionary"];
    [archiver finishEncoding];
    [archiver release];
        
	// Here, data holds the serialized version of your dictionary
	// do what you need to do with it before you:
	return data;
}

// converts from ns data
-(void)convertFromNSData:(NSData*)data
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary* dictionary = [[unarchiver decodeObjectForKey:@"Dictionary"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];
    
    // release objects first
    [_categories removeAllObjects];
    [_itemLists removeAllObjects];
    [_categories release];
    [_itemLists release];
    [_vaultName release];
    
    // save a reference to the data stored in the dictionary
    _categories = [[dictionary objectForKey:@"category"] retain];
    _itemLists = [[dictionary objectForKey:@"itemLists"] retain];
    _vaultName = [[dictionary objectForKey:@"vaultName"] retain];
    
    // validate that we have valid category object
    if (_categories == nil)
    {
        _categories = [[NSMutableArray array] retain];
    }
    
    // validate that we have valid item list object
    if (_itemLists == nil)
    {
        _itemLists = [[NSMutableArray array] retain];
    }
    
    // validate that we have valid vault name object
    if (_vaultName == nil)
    {
        _vaultName = [[NSString stringWithString:@""] retain];
    }
}

// Saves the vault with a new password
-(BOOL)saveVaultNewPassword:(NSString*)newPassword
{
    [_password release];
    _password = [[NSString stringWithString:newPassword] retain];
    return [self saveVault];
}

// Saves the password vault to disk
-(BOOL)saveVault
{
    // We do not have a valid vault name
    if (_vaultName.length == 0)
    {
        return FALSE;
    }
    
    // Before saving make sure we are in descending order
    BOOL needsUnsort = FALSE;
    if (_categoryComparison == NSOrderedAscending) {
        [self sortCategories:NSOrderedDescending];
        needsUnsort = TRUE;
    }
    
    NSString* basefilename = _vaultName;
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, basefilename, kPasswordVaultExtension];
    
    // Alter the path of the file if we are to use the fallback directory
    if ([MainViewController useFallbackDirectory]) {
        directory = [MainViewController fallbackDirectory];
        fullPath = [NSString stringWithFormat:@"%@/%@.%s", [MainViewController fallbackDirectory], basefilename, kPasswordVaultExtension];
    }
    
    // Grab the data from the vault
    NSData* data = [self convertToNSData];
    
    // TODO: encrypt the data
    NSString* vector = [NSString stringWithUTF8String:kInitVector];
    CCCryptorStatus status = kCCSuccess;
    CCOptions opts = kCCOptionPKCS7Padding;
    NSData* outputData = [data dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                                                       key:_password
                                      initializationVector:vector
                                                   options:opts
                                                     error:&status];
    
    // Validate that we encrypted the file successfully
    NSAssert(status == kCCSuccess, @"Failed to encrypt the vault file with path %@", fullPath);
    
    // Save the file to disk
    BOOL success = NO;
    if (status == kCCSuccess)
    {
        NSFileManager* filemanager = [NSFileManager defaultManager];
        success = [filemanager createFileAtPath:fullPath contents:outputData attributes:nil];
        NSAssert(success == TRUE, @"Failed to save vault file with path %@", fullPath);
    }
    
    // if we sorted before we saved, then lets revert to where we were before
    if (needsUnsort) {
        [self sortCategories:NSOrderedAscending];
    }
    
    // return if we were successful
    return success;
}

// Loads the vault from disk
-(BOOL)loadVault:(NSString*)vaultName withPassword:(NSString *)password fromChangePasswordRequest:(BOOL)fromChange
{
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%s", directory, vaultName, kPasswordVaultExtension];
    
    // Alter the path of the file if we are to use the fallback directory
    if ([MainViewController useFallbackDirectory]) {
        fullPath = [NSString stringWithFormat:@"%@/%@.%s", [MainViewController fallbackDirectory], vaultName, kPasswordVaultExtension];
    }
    
    // retrieve the actual data for the file
    NSData* data = [NSData dataWithContentsOfFile:fullPath];
    
    NSString* vector = [NSString stringWithUTF8String:kInitVector];
    CCCryptorStatus status = kCCSuccess;
    CCOptions opts = kCCOptionPKCS7Padding;
    NSData* outputData = [data decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                       key:password
                                      initializationVector:vector 
                                                   options:opts
                                                     error:&status];
    BOOL failed = status != kCCSuccess;
    
    // Load the vault data
    if (status == kCCSuccess)
    {
        @try
        {
            [self convertFromNSData:outputData];
        }
        @catch(NSException* e)
        {
            failed = TRUE;
            NSLog(@"Failed to load the vault (%@) with exception (%@)", vaultName, [e reason]);
        }

        if (failed == FALSE)
        {
            // Store the vault name and passwor
            [_vaultName release];
            [_password release];
            _vaultName = [vaultName copy];
            _password = [password copy];
        }
    }
    
    if (failed == TRUE && !fromChange)
    {
        NSString* message = [NSString stringWithFormat:
                             @"Incorrect password given when attempting to decrypt the vault %@", vaultName];
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Failed to Load File" 
                                                            message:message 
                                                           delegate:self
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
        [alertView release];
    }
        
    return status == kCCSuccess && failed == FALSE;
}

// delegate method for the alert view called with the button index the user selected
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
}

// Marks the network status, called after network status changes
-(void)checkNetworkStatus:(NSNotification*)notice
{
    NetworkStatus internetStatus = [_internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:      _internetActive = NO;   break;
        case ReachableViaWiFi:  _internetActive = YES;  break;
        case ReachableViaWWAN:  _internetActive = YES;  break;
    }
    
    NetworkStatus hostStatus = [_hostReachable currentReachabilityStatus];
    switch (hostStatus)
    {
        case NotReachable:      _hostActive = NO;   break;
        case ReachableViaWiFi:  _hostActive = YES;  break;
        case ReachableViaWWAN:  _hostActive = YES;  break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"networkStatusChange" object: nil];
}

// generates a random password and assigns it to the textfield passed in
-(NSString*)populatePassword
{
    static char generatedPassword[GENERATE_PASSWORD_LENGTH + 1];
    static char selectableNumber[SELECTABLE_NUMBER_COUNT] = {"0123456789"};
    static char selectableSpecials[SELECTABLE_SPECIAL_COUNT] = {"!@#$%^&*()-_+=?"};
    static char selectableChars[SELECTABLE_CHAR_COUNT] = {"abcdefghijklmnopqrstuvwxyz"};
    
    int uppercaseIndex = random() % GENERATE_PASSWORD_LENGTH;
    int lowercaseIndex = -1;
    int numberIndex  = -1;
    int specialIndex1 = -1;
    int specialIndex2 = -1;
    
    // determine index for certain characters
    while (lowercaseIndex == -1 || 
           lowercaseIndex == uppercaseIndex)
    {
        lowercaseIndex = random() % GENERATE_PASSWORD_LENGTH;
    }
    while (numberIndex == - 1 ||
           numberIndex == lowercaseIndex ||
           numberIndex == uppercaseIndex)
    {
        numberIndex = random() % GENERATE_PASSWORD_LENGTH;
    }
    while (specialIndex1 == -1 ||
           specialIndex1 == numberIndex ||
           specialIndex1 == lowercaseIndex ||
           specialIndex1 == uppercaseIndex)
    {
        specialIndex1 = random() % GENERATE_PASSWORD_LENGTH;
    }
    while (specialIndex2 == -1 ||
           specialIndex2 == specialIndex1 || 
           specialIndex2 == numberIndex ||
           specialIndex2 == lowercaseIndex ||
           specialIndex2 == uppercaseIndex)
    {
        specialIndex2 = random() % GENERATE_PASSWORD_LENGTH;
    }
    
    // build the password
    for (int i = 0; i < GENERATE_PASSWORD_LENGTH; ++i)
    {
        char characterToUse = '0';
        
        if (i == lowercaseIndex)
        {
            characterToUse = selectableChars[random() % SELECTABLE_CHAR_COUNT];
        }
        else if (i == uppercaseIndex)
        {
            const int toUpper = 'A' - 'a';
            characterToUse = selectableChars[random() % SELECTABLE_CHAR_COUNT] + toUpper;
        }
        else if (i == numberIndex)
        {
            characterToUse = selectableNumber[random() % SELECTABLE_NUMBER_COUNT];
        }
        else if (i == specialIndex1 || i == specialIndex2)
        {
            characterToUse = selectableSpecials[random() % SELECTABLE_SPECIAL_COUNT];
        }
        else
        {
            int value = random() % 2;
            char* arrayToUse = value ? selectableNumber : selectableChars;
            int count = value ? SELECTABLE_NUMBER_COUNT : SELECTABLE_CHAR_COUNT;
            BOOL useUpper = (count == SELECTABLE_CHAR_COUNT) && (BOOL)(random() % 2);
            
            characterToUse = arrayToUse[random() % count];
            if (useUpper)
            {
                characterToUse += 'A' - 'a';
            }
        }
        
        // assign the character to the passcode
        generatedPassword[i] = characterToUse;
    }
    
    // Close the string
    generatedPassword[GENERATE_PASSWORD_LENGTH] = '\0';
    
    return [NSString stringWithUTF8String:generatedPassword];
}

// Searches all items based on the text specified
-(NSInteger)searchForItem:(NSString*)text withOffset:(int)offset
{
    // clear previous search
    [self clearLastSearchResults];
    
    struct SearchResult result;
    
    for (PasswordVaultItemList* list in _itemLists)
    {
        for (PasswordVaultItem* item in list.items)
        {
            NSString* title = item.title;
            NSRange range = [title rangeOfString:text options:NSCaseInsensitiveSearch];
            if (range.location == 0 && range.length > 0)
            {
                result._item = item;
                result._list = list;
                NSValue* value = [NSValue valueWithBytes:&result objCType:@encode(struct SearchResult)];
                [_lastSearchResults addObject:value];
            }
        }
    }
    
    // no matches found
    if ([_lastSearchResults count] == 0) {
        return -1;
    }
    
    // wrap the search offset tp start from beginning again
    if (offset >= [_lastSearchResults count]) {
        offset = 0;
    }
    
    // return our offset into the search results.
    return offset;
}

// Retrieves the index path for the search result
-(NSIndexPath*)getSearchResultIndexPath:(NSInteger)offset
{
    if (offset < 0 || offset >= [_lastSearchResults count]) {
        return nil;
    }
    
    struct SearchResult result;
    NSValue* value = (NSValue*)[_lastSearchResults objectAtIndex:offset];
    [value getValue:&result];
    
    int section = [_itemLists indexOfObject:result._list];
    int row = [[((PasswordVaultItemList*)[_itemLists objectAtIndex:section]) items] indexOfObject:result._item];
    NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:section];
    return path;
}

// Clears last search results
-(void)clearLastSearchResults
{
    [_lastSearchResults removeAllObjects];
}

@end