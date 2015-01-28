//
//  Enums.m
//  PasswordVault
//
//  Created by David Leistiko on 9/16/14.
//
//

#import "Enums.h"

@implementation EnumHelper

// Looks up the string representation for font size
+(NSString*)getStringForFontSize:(PrimaryFontSize)size
{
    switch (size) {
        case kPrimaryFontSize_Extra_Small:  return @"Extra Small";
        case kPrimaryFontSize_Small:        return @"Small";
        case kPrimaryFontSize_Medium:       return @"Medium";
        case kPrimaryFontSize_Large:        return @"Large";
        case kPrimaryFontSize_ExtraLarge:   return @"Extra Large";
        default:                            return @"";
    }
}

// Returns a string representation for the language enum passed in
+(NSString*)getStringForLanguage:(Language)lang
{
    switch (lang)
    {
        case kLanguage_English:
            return @"english";
        case kLanguage_Spanish:
            return @"spanish";
        case kLanguage_Russian:
            return @"russian";
        case kLanguage_German:
            return @"german";
        case kLanguage_French:
            return @"french";
        case kLanguage_Italian:
            return @"italian";
        case kLanguage_Dutch:
            return @"dutch";
        case kLanguage_Greek:
            return @"greek";
        case kLanguage_Irish:
            return @"irish";
        default:
            return @"undefined";
    }
}

// Returns a string rep for the country code represented by the language passed in
+(NSString*)getCountryCodeForLanguage:(Language)lang
{
    switch (lang)
    {
        case kLanguage_English:
            return @"en";
        case kLanguage_Spanish:
            return @"es";
        case kLanguage_Russian:
            return @"ru";
        case kLanguage_German:
            return @"de";
        case kLanguage_French:
            return @"fr";
        case kLanguage_Italian:
            return @"it";
        case kLanguage_Dutch:
            return @"nl";
        case kLanguage_Greek:
            return @"el";
        case kLanguage_Irish:
            return @"ga";
        default:
            return @"undefined";
    }
}

// Returns the language based on country code
+(Language)getLanguageFromCountryCode:(NSString*)code
{
    if ([code isEqualToString:@"en"]) {
        return kLanguage_English;
    }
    else if ([code isEqualToString:@"es"]) {
        return kLanguage_Spanish;
    }
    else if ([code isEqualToString:@"ru"]) {
        return kLanguage_Russian;
    }
    else if ([code isEqualToString:@"de"]) {
        return kLanguage_German;
    }
    else if ([code isEqualToString:@"fr"]) {
        return kLanguage_French;
    }
    else if ([code isEqualToString:@"it"]) {
        return kLanguage_Italian;
    }
    else if ([code isEqualToString:@"nl"]) {
        return kLanguage_Dutch;
    }
    else if ([code isEqualToString:@"el"]) {
        return kLanguage_Greek;
    }
    else if ([code isEqualToString:@"ga"]) {
        return kLanguage_Irish;
    }
    return kLanguage_Invalid;
}

// Returns the display name for the language passed in, if it cannot find a
// match for the language the "unknown" string is returned
+(NSString*)getDisplayStringForLanguage:(Language)lang
{
    NSString* code = [EnumHelper getCountryCodeForLanguage:lang];
    NSArray* langArray = [NSLocale preferredLanguages];
    
    // search array for lang
    for (NSString* langCode in langArray) {
        if ([code isEqualToString:langCode]) {
            return [[[NSLocale alloc] initWithLocaleIdentifier:langCode] displayNameForKey:NSLocaleIdentifier
                                                                                     value:langCode];
        }
    }
    
    return @"unknown";
}

// Returns an array of language infos
+(NSArray*)getLanguageInfo
{
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:kLanguage_COUNT];
    
    for (int i = 0; i < kLanguage_COUNT; ++i) {
        
        struct LanguageInfo info;
        
        info._lang = (Language)i;
        info._code = [EnumHelper getCountryCodeForLanguage:info._lang];
        
        switch (i)
        {
            case kLanguage_English:     info._displayName = @"English";     break;
            case kLanguage_Russian:     info._displayName = @"Russian";     break;
            case kLanguage_Spanish:     info._displayName = @"Spanish";     break;
            case kLanguage_German:      info._displayName = @"German";      break;
            case kLanguage_French:      info._displayName = @"French";      break;
            case kLanguage_Italian:     info._displayName = @"Italian";     break;
            case kLanguage_Dutch:       info._displayName = @"Dutch";       break;
            case kLanguage_Greek:       info._displayName = @"Greek";       break;
            case kLanguage_Irish:       info._displayName = @"Irish";       break;
        }
        
        // encode the data and add to array
        NSValue* value = [NSValue valueWithBytes:&info objCType:@encode(struct LanguageInfo)];
        [arr addObject:value];
    }
    
    // return the info
    return [NSArray arrayWithArray:arr];
}

// Returns an array of font size infos
+(NSArray*)getFontSizeInfo
{
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:kPrimaryFontSize_COUNT];
    
    for (int i = 0; i < kPrimaryFontSize_COUNT; ++i) {
        
        struct FontSizeInfo info;
        info._size = i;
        
        // encode the data and add to array
        NSValue* value = [NSValue valueWithBytes:&info objCType:@encode(struct FontSizeInfo)];
        [arr addObject:value];
    }
    
    // return the info
    return [NSArray arrayWithArray:arr];
}

@end
