//
//  PasswordVaultItem.m
//  PasswordVault
//
//  Created by David Leistiko on 1/3/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "PasswordVaultItem.h"

@implementation PasswordVaultItem

@synthesize category = _category;
@synthesize title = _title;
@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;
@synthesize notes = _notes;
@synthesize icon = _icon;
@synthesize account = _account;

// creates and returns a password vault item
+(PasswordVaultItem*)passwordVaultItem
{
    return [[[self alloc] init] autorelease];
}

// Custom init function for the item
-(id)init
{
    if (self = [super init])
    {
        _category = [@"" retain];
        _title = [@"" retain];
        _url = [@"" retain];
        _username = [@"" retain];
        _password = [@"" retain];
        _notes = [@"" retain];
        _icon = [@"" retain];
        _account = [@"" retain];
    }
    return self;
}

// Handles decoding
-(id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super init])
	{
		_category = [[decoder decodeObject] retain];
        _title = [[decoder decodeObject] retain];
        _url = [[decoder decodeObject] retain];
        _username = [[decoder decodeObject] retain];
        _password = [[decoder decodeObject] retain];
        _notes = [[decoder decodeObject] retain];
        _icon = [[decoder decodeObject] retain];
        _account = [[decoder decodeObject] retain];
    }
    return self;
}

// Custom dealloc function for the password vault item
-(void)dealloc
{
    [_category release];
    [_title release];
    [_url release];
    [_username release];
    [_password release];
    [_notes release];
    [_icon release];
    [_account release];
    
    [super dealloc];
}

// sets the category for the item
-(void)setCategory:(NSString*)category
{
    [_category release];
    _category = [category copy];
}

// sets the title for the item
-(void)setTitle:(NSString*)title
{
    [_title release];
    _title = [title copy];
}

// sets the url for the item
-(void)setUrl:(NSString*)url
{
    [_url release];
    _url = [url copy];
}

// sets the username for the item
-(void)setUsername:(NSString*)username
{
    [_username release];
    _username = [username copy];
}

// sets the password for the item
-(void)setPassword:(NSString*)password
{
    [_password release];
    _password = [password copy];
}

// sets the notes for the item
-(void)setNotes:(NSString*)notes
{
    [_notes release];
    _notes = [notes copy];
}

// sets the icon for the item
-(void)setIcon:(NSString*)icon
{
    [_icon release];
    _icon = [icon copy];
}

// set the account for the item
-(void)setAccount:(NSString *)account
{
    [_account release];
    _account = [account copy];
}

// handles encoding the object
-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:_category];
    [coder encodeObject:_title];
    [coder encodeObject:_url];
    [coder encodeObject:_username];
    [coder encodeObject:_password];
    [coder encodeObject:_notes];
    [coder encodeObject:_icon];
    [coder encodeObject:_account];
}

@end
