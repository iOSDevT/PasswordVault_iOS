//
//  PasswordVault.h
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "PasswordVaultItem.h"
#import "Enums.h"

@class Reachability;

// access to the default file extension
extern const char* kPasswordVaultExtension;

// core class responsible for managing actual user data
@interface PasswordVault : NSObject <UIAlertViewDelegate>
{
    NSString* _vaultName;
    NSString* _password;
    NSMutableArray* _categories;
    NSMutableArray* _itemLists;
    NSMutableArray* _lastSearchResults;
    
    Reachability* _internetReachable;
    Reachability* _hostReachable;
    BOOL _internetActive;
    BOOL _hostActive;
    
    NSComparisonResult _categoryComparison;
}

// class properties
@property (nonatomic, readonly) NSString* vaultName;
@property (nonatomic, readonly) BOOL internetActive;
@property (nonatomic, readonly) BOOL hostActive;
@property (nonatomic, readonly) NSComparisonResult categoryComparison;
@property (nonatomic, readonly) NSMutableArray* lastSearchResults;

// class functions
+(PasswordVault*)sharedInstance;
-(void)createNewVault:(NSString*)vaultName withPassword:(NSString*)password;
-(int)getCategoryCount;
-(NSString*)getCategoryName:(int)category;
-(int)getItemCountForCategory:(int)category;
-(NSString*)getItemName:(int)category withItem:(int)item;
-(NSString*)getItemIcon:(int)category withItem:(int)item;
-(PasswordVaultItem*)getItem:(int)category withItem:(int)item;
-(NSArray*)getCategoryNames;
-(NSArray*)getRelevantStringData;
-(void)addItem:(PasswordVaultItem*)item;
-(void)removeItem:(PasswordVaultItem*)item;
-(NSData*)convertToNSData;
-(void)convertFromNSData:(NSData*)data;
-(BOOL)saveVault;
-(BOOL)saveVaultNewPassword:(NSString*)password;
-(BOOL)loadVault:(NSString*)vaultName withPassword:(NSString*)password fromChangePasswordRequest:(BOOL)fromChange;
-(void)checkNetworkStatus:(NSNotification*)notice;
-(NSString*)populatePassword;
-(NSMutableArray*)getAutoCompleteStrings:(AutoCompleteType)autoType;
-(NSInteger)searchForItem:(NSString*)text withOffset:(int)offset;
-(NSIndexPath*)getSearchResultIndexPath:(NSInteger)offset;
-(void)clearLastSearchResults;
-(void)sortCategories:(NSInteger)sortMode;
@end
