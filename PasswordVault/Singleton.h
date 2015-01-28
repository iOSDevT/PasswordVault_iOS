//
//  Singleton.h
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#define NAMED_SINGLETON(classname,instancename)\
+(classname *) instancename \
{ \
static classname * instance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
instance = [[classname alloc] init]; \
}); \
return instance; \
}

#define SINGLETON(classname) \
NAMED_SINGLETON(classname, sharedInstance)