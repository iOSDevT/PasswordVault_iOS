//
//  PasswordVaultItem.h
//  PasswordVault
//
//  Created by David Leistiko on 1/3/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

@interface PasswordVaultItem : NSObject <NSCoding> 
{
    NSString* _category;
    NSString* _title;
    NSString* _url;
    NSString* _username;
    NSString* _password;
    NSString* _notes;
    NSString* _icon;
    NSString* _account;
}

@property (nonatomic, readonly) NSString* category;
@property (nonatomic, readonly) NSString* title;
@property (nonatomic, readonly) NSString* url;
@property (nonatomic, readonly) NSString* username;
@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) NSString* notes;
@property (nonatomic, readonly) NSString* icon;
@property (nonatomic, readonly) NSString* account;

+(PasswordVaultItem*)passwordVaultItem;
-(void)setCategory:(NSString*)category;
-(void)setTitle:(NSString*)title;
-(void)setUrl:(NSString*)url;
-(void)setUsername:(NSString*)username;
-(void)setPassword:(NSString*)password;
-(void)setNotes:(NSString*)notes;
-(void)setIcon:(NSString*)icon;
-(void)setAccount:(NSString*)account;

@end
