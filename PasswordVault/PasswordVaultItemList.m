//
//  PasswordVaultItemList.m
//  PasswordVault
//
//  Created by David Leistiko on 1/3/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//

#import "PasswordVaultItemList.h"

static NSInteger sortItems(id elem1, id elem2, void* context);

@implementation PasswordVaultItemList

@synthesize category = _category;
@synthesize items = _items;

// returns a default list
+(PasswordVaultItemList*)passwordVaultItemList
{
    return [[[self alloc] init] autorelease];
}

// inits the password vault item list
-(id)init
{
    if (self = [super init])
    {
        _category = [[NSString alloc] initWithCString:"" encoding:NSUTF8StringEncoding];
        _items = [[NSMutableArray array] retain];
    }
    return self;
}

// Handles decoding
-(id)initWithCoder:(NSCoder*)decoder
{
    if (self = [super init])
	{
		_category = [[decoder decodeObject] retain];
        _items = [[decoder decodeObject] retain];
    }
    return self;
}

// custom dealloc function
-(void)dealloc
{
    [_items removeAllObjects];
    [_category release];
    [_items release];
    
    [super dealloc];
}

// adds an item to the list
-(void)addItem:(PasswordVaultItem*)item
{
    [_items addObject:item];
    
    NSArray* sorted = [_items sortedArrayUsingFunction:sortItems context:"title"];
    [_items release];
    _items = [[NSMutableArray arrayWithArray:sorted] retain];
    
//    [_items sortUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"title" 
//                                                                                          ascending:true], nil]];
}

// sets the category name
-(void)setCategory:(NSString*)category
{
    [_category release];
    _category = [category copy];
}

// handles encoding the object
-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:_category];
    [coder encodeObject:_items];
}

// Helper function for sorting item lists
NSInteger sortItems(id elem1, id elem2, void* context)
{
    PasswordVaultItem* item1 = (PasswordVaultItem*)elem1;
    PasswordVaultItem* item2 = (PasswordVaultItem*)elem2;
    
    char* compareContext = (char*)context;
    if (strcmp(compareContext, "title") == 0) {
        return [item1.title caseInsensitiveCompare:item2.title];
    }
    else if (strcmp(compareContext, "username") == 0) {
        return [item1.username caseInsensitiveCompare:item2.username];
    }
    return NSOrderedSame;
}


@end
