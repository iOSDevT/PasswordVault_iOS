//
//  NSMutableDictionaryExtension.m
//  PasswordVault
//
//  Created by David Leistiko on 10/13/14.
//
//

#import "NSMutableDictionaryExtension.h"

#import <CoreFoundation/CoreFoundation.h>

@implementation NSMutableDictionary (Extension)

// Deep clones the dictionary
-(NSMutableDictionary*)deepCopy
{
    NSMutableDictionary *clone = (NSMutableDictionary*)CFPropertyListCreateDeepCopy(
                                                                kCFAllocatorDefault,
                                                                (CFDictionaryRef)self,
                                                                kCFPropertyListMutableContainers);
    return clone;
}

@end