//
//  PasswordVaultItemList.h
//  PasswordVault
//
//  Created by David Leistiko on 1/3/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "PasswordVaultItem.h"

@interface PasswordVaultItemList : NSObject <NSCoding>
{
    NSString* _category;
    NSMutableArray* _items;
}

@property (nonatomic, readonly) NSString* category;
@property (nonatomic, readonly) NSMutableArray* items;

+(PasswordVaultItemList*)passwordVaultItemList;
-(void)addItem:(PasswordVaultItem*)item;
-(void)setCategory:(NSString*)category;

@end
