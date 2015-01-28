

//
//  Strings.m
//  PasswordVault
//
//  Created by David Leistiko on 9/15/14.
//
//

#import "Enums.h"
#import "NSStringExtension.h"
#import "Singleton.h"
#import "Strings.h"
#import "Utility.h"

static NSString* invalidString = @"[[empty]]";

// private members
@interface Strings(Private)
+(NSString*)xmlChecksumPreferenceName;
+(BOOL)checkForEscapedStringsXmlFile;
+(void)createEscapedStringsXmlFile;
+(BOOL)checkForStringsXmlUpdate;
-(void)readStrings;
-(void)readStringsXml:(NSString*)filename;
-(void)convertStringsToXml:(NSString*)filename isEscaped:(BOOL)escaped;
-(void)buildEscapedStringsFromXml:(NSString*)filename;
-(void)translateStrings:(BOOL)missingOnly;
@end

@implementation Strings

@synthesize CurrentLanguage = _currentLanguage;
@synthesize isLoading;

// Declare the class a singleton
SINGLETON(Strings)

// Returns the file to use
+(NSString*)getFilename
{
    // The source file is stored within the bundle
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* myFile = [mainBundle pathForResource:@"xmlStrings" ofType:@"xml"];
    return myFile;
}

// Returns the file to use
+(NSString*)getEscapedFilename
{
    // The escaped file is stored in the documents directory
    NSString* basefilename = @"xmlStrings_escaped";
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%@", directory, basefilename, @"xml"];
    return fullPath;
}

// returns the key to use to look for the modified date preference
+(NSString*)xmlChecksumPreferenceName
{
    return @"lastStringXmlChecksum";
}

// Check for the existence of the escaped xml file
+(BOOL)checkForEscapedStringsXmlFile
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[Strings getEscapedFilename]]) {
        return TRUE;
    }
    return FALSE;
}

// Create the escaped xml file if it does not exist
+(void)createEscapedStringsXmlFile
{
    if ([Strings checkForEscapedStringsXmlFile]) {
        return;
    }
    
    NSString* filename = [Strings getEscapedFilename];
    [[NSFileManager defaultManager] createFileAtPath:filename
                                            contents:nil
                                          attributes:nil];
}

// Checks if we have had our source xml file updated since last run.
+(BOOL)checkForStringsXmlUpdate
{
    if (![Strings checkForEscapedStringsXmlFile]) {
        return TRUE;
    }
    
    NSString* filename = [Strings getFilename];
    NSString* storedChecksum = [[NSUserDefaults standardUserDefaults] objectForKey:[Strings xmlChecksumPreferenceName]];
    
    NSString* contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    NSString* newChecksum = [contents md5];
    
    // compare the hash values for the stored result against the current result
    if (![storedChecksum isEqualToString:newChecksum]) {
        return TRUE;
    }
    
    // if we get here then no update is required
    return FALSE;
}

// the init function returns instane
-(id)init
{
    if (self = [super init])
    {
        _currentLanguage = kLanguage_English;
        _activeXmlElement = @"";
        _activeXmlLanguage = kLanguage_Invalid;
        
        _stringDict = [[NSMutableDictionary dictionaryWithCapacity:500] retain];
    }
    return self;
}

// dealloc function to cleanup resources
-(void)dealloc
{
    [_stringDict release];
    
    [super dealloc];
}

// builds all the string data for lookup
-(void)buildStrings:(BOOL)initial
{
    [_stringDict removeAllObjects];
    
    // DML
    // TODO
    // Once the data is converted to proper XML, remove these steps
    //[self readStrings];
    //[self convertStringsToXml:[Strings getFilename] isEscaped:FALSE];
    
    if (([Strings checkForStringsXmlUpdate] || [Utility sharedInstance].forceLoadType & kForceLoadType_Strings) && initial) {
        [Strings createEscapedStringsXmlFile];
        [self buildEscapedStringsFromXml:[Strings getFilename]];
        [self translateStrings:TRUE];
        //[self convertStringsToXml:[Strings getEscapedFilename] isEscaped:TRUE];
    }
    else {
        [self readStringsXml:[Strings getEscapedFilename]];
    }
}

// do we need to translate?
-(BOOL)needsTranslation
{
    return [Strings checkForStringsXmlUpdate] || [Utility sharedInstance].forceLoadType & kForceLoadType_Strings;
}

// Builds the string data using xml and escapes to be
-(void)buildEscapedStringsFromXml:(NSString*)filename
{
    [_stringDict removeAllObjects];
    
    NSMutableArray* keys = [self getKeysForAllLanguages:filename];
    NSMutableDictionary* tempDict = [NSMutableDictionary dictionaryWithCapacity:kLanguage_COUNT];
    
    for (int i = kLanguage_English; i < kLanguage_COUNT; ++i) {
        NSMutableArray* arr = [self getStringsForLanguage:(Language)i withFilename:filename];
        NSMutableArray* escapedArr = [NSMutableArray arrayWithCapacity:[arr count]];
        
        // edit each value by applying escape sequences
        for (NSString* value in arr) {
            NSString* escaped = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [escapedArr addObject:escaped];
        }
        
        // DML
        // add the empty array in the case we are a language to skip
        if (![[Utility sharedInstance] checkForceLanguageValidity:(Language)i]) {
            [tempDict setObject:[NSMutableArray arrayWithCapacity:0] forKey:[NSNumber numberWithInt:i]];
            continue;
        }
        
        // add array of values to dict
        [tempDict setObject:escapedArr forKey:[NSNumber numberWithInt:i]];
    }
    
    // Iterate over all keys and add array of language values to the dict
    for (int i = 0; i < [keys count]; ++i) {
        NSString* key = [keys objectAtIndex:i];
        NSMutableArray* values = [NSMutableArray arrayWithCapacity:kLanguage_COUNT];
        
        for (int j = 0; j < kLanguage_COUNT; ++j) {
            NSMutableArray* langVaules = [tempDict objectForKey:[NSNumber numberWithInt:j]];
            
            // DML
            if ([langVaules count] == 0) {
                [values addObject:@""];
                continue;
            }
            
            [values addObject:[langVaules objectAtIndex:i]];
        }
        
        // add to primary dict
        [_stringDict setObject:values forKey:key];
    }
}

// Read stirng source data original format
-(void)readStrings
{
    [_stringDict removeAllObjects];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* myFile = [mainBundle pathForResource: @"strings" ofType: @"txt"];
    NSString* source = [NSString stringWithContentsOfFile:myFile encoding:NSASCIIStringEncoding error:nil];
    NSArray* stringData = [source componentsSeparatedByString:@"<<!>>"];
    
    for (NSString* data in stringData) {
        NSArray* keyAndStrings = [data componentsSeparatedByString:@"="];
        if (keyAndStrings.count <= 1) {
            continue;
        }
        
        NSString* key = (NSString*)[keyAndStrings objectAtIndex:0];
        if ([key isEqualToString:@""]) {
            continue;
        }
        NSArray* source = [((NSString*)[keyAndStrings objectAtIndex:1]) componentsSeparatedByString:@"|"];
        
        // Use this for converted source
        NSMutableArray* convertedSource = [[NSMutableArray arrayWithCapacity:kLanguage_COUNT] retain];
        
        // run through each source string and convert to use proper encoding
        for (NSString* str in source) {
            if ([str isEqualToString:@""]) {
                continue;
            }
            [convertedSource addObject:[[Utility sharedInstance] convertStringForEncoding:str]];
        }
        
        // add the strings to the dict for later lookup
        [_stringDict setObject:convertedSource forKey:key];
    }
}

// Read string source data from xml
-(void)readStringsXml:(NSString*)filename
{
    [_stringDict removeAllObjects];
    
    NSString* source = [[NSString alloc] initWithContentsOfFile:filename
                                                       encoding:NSUTF8StringEncoding error:nil];
    NSData* data = [source dataUsingEncoding:NSUTF8StringEncoding];
    
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    
    // Since the parse function is a blocking function
    // we can safely dispose of the parse now
    [parser release];
}

// Writes all stirng data to an xml format
-(void)convertStringsToXml:(NSString*)filename isEscaped:(BOOL)escaped
{
    NSMutableString* xmlString = [NSMutableString stringWithString:@""];
    
    [xmlString appendString:@"<strings>\n"];
    
    for (NSString* key in [_stringDict allKeys]) {
        NSMutableArray* sources = [_stringDict objectForKey:key];
        
        [xmlString appendString:@"\t<string id=\""];
        [xmlString appendString:[NSString stringWithFormat:@"%@\"", key]];
        [xmlString appendString:@">\n"];
        
        for (int i = 0; i < kLanguage_COUNT; ++i) {
            
            NSString* countryCode = [EnumHelper getCountryCodeForLanguage:(Language)i];

            // DML
            // should we skip this language
            if (![[Utility sharedInstance] checkForceLanguageValidity:(Language)i]) {
                [xmlString appendString:[NSString stringWithFormat:@"\t\t<%@>", countryCode]];
                [xmlString appendString:invalidString];
                [xmlString appendString:[NSString stringWithFormat:@"</%@>\n", countryCode]];
                continue;
            }
            
            [xmlString appendString:[NSString stringWithFormat:@"\t\t<%@>", countryCode]];
            [xmlString appendString:[sources objectAtIndex:i]];
            [xmlString appendString:[NSString stringWithFormat:@"</%@>\n", countryCode]];
        }
        
        [xmlString appendString:@"\t</string>\n"];
    }
    
    [xmlString appendString:@"</strings>\n"];
    [xmlString writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:nil];
    
    // if we are the escaped file then update our stored mod time
    if (escaped) {
        NSString* contents = [NSString stringWithContentsOfFile:[Strings getFilename] encoding:NSUTF8StringEncoding error:nil];
        NSString* checksum = [contents md5];
        [[NSUserDefaults standardUserDefaults] setObject:checksum forKey:[Strings xmlChecksumPreferenceName]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// are we still loading
-(BOOL)IsLoading
{
    return _translationCount > 0;
}

// The purpose of this function is to translate any missing strings that we
// do not have a translation for (or it can translate all strings).
-(void)translateStrings:(BOOL)missingOnly
{
    _translationCount = 0;
    
    // NOTE: This function assumes that all source strings are currently percent escaped
    // which means we must remove this attribute to translate the string and then add the
    // percent escaping back afterwards so that when the stirngs are converted to xml format
    // they will be ready for parsing when we read the xml file
    
    // iterate over each keys in the string dictionary, translating any strings
    // that are equal to the empty string
    for (NSString* key in [_stringDict allKeys]) {
        NSArray* arr = [_stringDict objectForKey:key];
        NSString* enStr = [arr objectAtIndex:0];
        
        // iterate over all translations for each language
        for (int i = kLanguage_English + 1; i < kLanguage_COUNT; ++i) {
            
            NSString* curTranslation = [arr objectAtIndex:i];
            
            // DML
            if (![[Utility sharedInstance] checkForceLanguageValidity:(Language)i]) {
                continue;
            }
            
            // this is our callback which will be called when we receive the translated text from google
            TranslateTextCallback callback = ^(NSString* source, NSString* translated, NSMutableDictionary* userData)
            {
                NSString* dictKey = [userData objectForKey:@"key"];
                NSString* langStr = [userData objectForKey:@"targetLanguage"];
                Language language = [EnumHelper getLanguageFromCountryCode:langStr];
                
                // Since the text is sent as html we need to convert it back to plain text and then escaped it
                NSString* fixedTranslated = [[Utility sharedInstance] fixTranslatedString:translated];
                fixedTranslated = [NSString htmlToText:fixedTranslated];
                fixedTranslated = [[Utility sharedInstance] fixTranslatedString:fixedTranslated];
                fixedTranslated = [fixedTranslated stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                while ([[_stringDict objectForKey:dictKey] count] < kLanguage_COUNT) {
                    [[_stringDict objectForKey:dictKey] addObject:[NSString stringWithFormat:@"%@", @"<debug>"]];
                }
                
                [[_stringDict objectForKey:dictKey] replaceObjectAtIndex:language withObject:fixedTranslated];
                
                NSString* original = [userData objectForKey:@"original"];
                NSLog(@"Translate result: %@ = %@", original, translated);
                [userData release];
                
                _translationCount -= 1;
            };
            
            // should we translate this string
            if (!missingOnly || (missingOnly && [curTranslation isEqualToString:@""])) {
                
                _translationCount += 1;
                
                NSString* unescapedEnStr = [enStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                // Build a userData property that will be used to help us pass data in and out of the callback
                NSMutableDictionary* userData = [[NSMutableDictionary dictionaryWithCapacity:32] retain];
                [userData setObject:[arr objectAtIndex:kLanguage_English] forKey:@"original"];
                [userData setObject:key forKey:@"key"];
                
                [[Utility sharedInstance] translateText:unescapedEnStr
                                     withSourceLanguage:kLanguage_English
                                      andTargetLanguage:(Language)i
                                            andCallback:callback
                                           withUserData:userData];
            }
        }
    }
    
    //[[Utility sharedInstance] translateQueuedInfos];
}

// complete the translations by converting them to xml and then reading them back in
-(void)finishTranslations
{
    [self convertStringsToXml:[Strings getEscapedFilename] isEscaped:TRUE];
    [self readStringsXml:[Strings getEscapedFilename]];
}

// Based on the current language, it returns the string for the key passed in
-(NSString*)lookupString:(NSString *)key
{
    NSArray* source = (NSArray*)[_stringDict objectForKey:key];
    if (source == nil || (int)_currentLanguage >= [source count]) {
        return key;
    }
    
    // returns the found string or the key in the event that we match
    // the invalid string
    NSString* value = [source objectAtIndex:(int)_currentLanguage];
    return (([value isEqualToString:invalidString]) ? @" " : value);
}

// Based on the passed in language, it returns the string for the key passed in
-(NSString*)lookupString:(NSString*)key withLanguage:(Language)lang
{
    NSArray* source = (NSArray*)[_stringDict objectForKey:key];
    if (source == nil || (int)lang >= [source count]) {
        return key;
    }
    
    // returns the found string or the key in the event that we match
    // the invalid string
    NSString* value = [source objectAtIndex:(int)lang];
    return (([value isEqualToString:invalidString]) ? @" " : value);
}

// modifies the current language which will affect future lookups
-(void)changeCurrentLanguage:(Language)lang
{
    _currentLanguage = lang;
}

// attempts to read the user's language setting and change the language based on that
-(void)setCurrentLanguageFromSettings
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    // Spanish?
    if ([language isEqualToString:@"es"]) {
        [self changeCurrentLanguage:kLanguage_Spanish];
    }
    // Russian?
    else if ([language isEqualToString:@"ru"]) {
        [self changeCurrentLanguage:kLanguage_Russian];
    }
    // Fallback to English
    else {
        [self changeCurrentLanguage:kLanguage_English];
    }
}

// Handles when an xml element is found for use
-(void)parser:(NSXMLParser*)parser
didStartElement:(NSString*)elementName
 namespaceURI:(NSString*)namespaceURI
qualifiedName:(NSString*)qName
   attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"string"]) {
        _activeXmlElement = [[attributeDict objectForKey:@"id"] retain];
        return;
    }
    
    Language lang = [EnumHelper getLanguageFromCountryCode:elementName];
    if (lang != kLanguage_Invalid) {
        _activeXmlLanguage = lang;
    }
}

// Handles when an element has finished being processed
-(void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    // did we finish reading the element <string> ?
    if (_activeXmlElement != nil && [elementName isEqualToString:_activeXmlElement]) {
        [_activeXmlElement release];
        _activeXmlElement = nil;
        _activeXmlLanguage = kLanguage_Invalid;
    }
}

// Handles when the inner-text of an element is being read
-(void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    // if we get whitespace characters here we can simply ignore these characters
    if (string == nil || [NSString isWhiteSpace:string]) {
        return;
    }
    
    // if we have a valid key and lang then read the text
    if (_activeXmlElement != nil && _activeXmlLanguage != kLanguage_Invalid) {
        
        NSMutableArray* arr = [_stringDict objectForKey:_activeXmlElement];
        if (arr == nil) {
            arr = [NSMutableArray arrayWithCapacity:kLanguage_COUNT];
        }
        
        NSString* convertedString = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        // DML
        BOOL isInvalid = [string isEqualToString:invalidString];
        NSString* finalString = ((isInvalid) ? string : ((convertedString == nil) ? string : convertedString));
        
        // NOTE: elements should be in the array in the same order as
        // the language enum. This should be automatic as the elements
        // are stored in the proper order on the file
        [arr addObject:finalString];
        
        // set the new array in the dictionary
        [_stringDict setObject:arr forKey:_activeXmlElement];
    }
}

// Returns an array of all strings defined for the lang passed in
-(NSMutableArray*)getStringsForLanguage:(Language)lang withFilename:(NSString*)filename
{
    NSString* source = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    NSString* country = [EnumHelper getCountryCodeForLanguage:lang];
    NSString* openStr = [NSString stringWithFormat:@"<%@>", country];
    NSString* closeStr = [NSString stringWithFormat:@"</%@>", country];
    
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:300];
    NSArray* subresults1 = [source componentsSeparatedByString:openStr];
    
    // iterate through subresults
    for (NSString* partial in subresults1) {
        
        NSArray* subresults2 = [partial componentsSeparatedByString:closeStr];
        
        int index = [subresults1 indexOfObject:partial];
        if (index > 0) {
            [results addObject:[subresults2 objectAtIndex:0]];
        }
    }
    
    // return the parsed results
    return results;
}

// Returns an array containing all of the keys for the various stirngs
-(NSMutableArray*)getKeysForAllLanguages:(NSString*)filename
{
    NSString* source = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    NSString* openStr = @"<string id=\"";
    NSString* closeStr = @"\">\n";
    
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:300];
    NSArray* subresults1 = [source componentsSeparatedByString:openStr];
    
    // iterate through subresults
    for (NSString* partial in subresults1) {
        
        NSArray* subresults2 = [partial componentsSeparatedByString:closeStr];
        
        int index = [subresults1 indexOfObject:partial];
        if (index > 0) {
            [results addObject:[subresults2 objectAtIndex:0]];
        }
    }
    
    // return the parsed results
    return results;
}

// Sets the value of a string within the language dictionary with the specified key
// and language, replacing the current value with the new one
-(NSString*)setString:(NSString*)key withValue:(NSString*)value andLanguage:(Language)lang
{
    NSMutableArray* valueArray = [_stringDict objectForKey:key];
    if (valueArray == nil) {
        valueArray = [NSMutableArray arrayWithCapacity:kLanguage_COUNT];
        
        // add placeholders for all languages since we just created a new array
        for (int i = 0; i < kLanguage_COUNT; ++i) {
            [valueArray addObject:@""];
        }
    }
    
    NSString* oldValue = [valueArray objectAtIndex:(int)lang];
    [valueArray replaceObjectAtIndex:(int)lang withObject:value];
    return oldValue;
}

@end