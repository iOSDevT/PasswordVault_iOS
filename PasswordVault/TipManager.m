//
//  TipManager.m
//  PasswordVault
//
//  Created by David Leistiko on 8/11/14.
//
//

#import "NSStringExtension.h"
#import "Singleton.h"
#import "Strings.h"
#import "TipManager.h"
#import "Utility.h"

#include <stdlib.h>

static NSString* invalidString = @"[[empty]]";

@interface TipManager(Private)
+(NSString*)xmlChecksumPreferenceName;
+(BOOL)checkForEscapedTipsXmlFile;
+(void)createEscapedTipsXmlFile;
+(BOOL)checkForTipsXmlUpdate;
-(BOOL)haveAllTipsBeenSeen:(Language)lang;
-(BOOL)containsTipId:(int)tipId outIndex:(int*)index forLanguage:(Language)lang;
-(void)readTips;
-(void)readTipsXml:(NSString*)filename;
-(void)convertTipsToXml:(NSString*)filename;
-(void)buildEscapedTipsFromXml:(NSString*)filename;
-(void)translateStrings:(BOOL)missingOnly;
@end

@implementation TipManager

// Declare the class a singleton
SINGLETON(TipManager)

// bind properties
@synthesize tipDictionary = _tipDictionary;
@synthesize shownCount = _shownCount;
@synthesize lastTipId = _lastTipId;
@synthesize isLoading;

// Returns the file to use
+(NSString*)getFilename
{
    // The source file is stored within the bundle
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* myFile = [mainBundle pathForResource:@"xmlTips" ofType:@"xml"];
    return myFile;
}

// Returns the file to use
+(NSString*)getEscapedFilename
{
    // The escaped file is stored in the documents directory
    NSString* basefilename = @"xmlTips_escaped";
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%@", directory, basefilename, @"xml"];
    return fullPath;
}

// returns the key to use to look for the modified date preference
+(NSString*)xmlChecksumPreferenceName
{
    return @"lastTipXmlChecksum";
}

// Check for the existence of the escaped xml file
+(BOOL)checkForEscapedTipsXmlFile
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[TipManager getEscapedFilename]]) {
        return TRUE;
    }
    return FALSE;
}

// Create the escaped xml file if it does not exist
+(void)createEscapedTipsXmlFile
{
    if ([TipManager checkForEscapedTipsXmlFile]) {
        return;
    }

    NSString* filename = [TipManager getEscapedFilename];
    [[NSFileManager defaultManager] createFileAtPath:filename
                                    contents:nil
                                    attributes:nil];
}

// Checks if we have had our source xml file updated since last run.
+(BOOL)checkForTipsXmlUpdate
{
    if (![TipManager checkForEscapedTipsXmlFile]) {
        return TRUE;
    }

    NSString* filename = [TipManager getFilename];
    NSString* storedChecksum = [[NSUserDefaults standardUserDefaults] objectForKey:[TipManager xmlChecksumPreferenceName]];
    
    NSString* contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    NSString* newChecksum = [contents md5];
    
    // compare the hash values for the stored result against the current result
    if (![storedChecksum isEqualToString:newChecksum]) {
        return TRUE;
    }

    // if we get here then no update is required
    return FALSE;
}

/**
 * Initialize function, sets up all of the tips that can be displayed
 */
-(id)init
{
    if (self = [super init])
    {
        // seed the random number generator
        srandom(time(NULL));
        
        _tipDictionary = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
    }
    
    // Load the have been seen values
    [self load:[Strings sharedInstance].CurrentLanguage];
    
    return self;
}

/**
 * Free used resources
 */
-(void)dealloc
{
    [_tipDictionary release];
    [super dealloc];
}

/**
 * This will rebuild all of the tip data using the current language
 */
-(void)buildTips:(BOOL)initial
{
    [_tipDictionary removeAllObjects];

    // DML
    // TODO
    // Once the data is converted to proper XML, remove these steps
    //[self readTips];
    //[self convertTipsToXml:[TipManager getFilename] isEscaped:FALSE];

    if (([TipManager checkForTipsXmlUpdate] || [Utility sharedInstance].forceLoadType & kForceLoadType_Tips) && initial) {
        [TipManager createEscapedTipsXmlFile];
        [self buildEscapedTipsFromXml:[TipManager getFilename]];
        [self translateStrings:TRUE];
        //[self convertTipsToXml:[TipManager getEscapedFilename] isEscaped:TRUE];
    }
    else {
        [self readTipsXml:[TipManager getEscapedFilename]];
    }
}

// do we need to translate?
-(BOOL)needsTranslation
{
    return [TipManager checkForTipsXmlUpdate] || [Utility sharedInstance].forceLoadType & kForceLoadType_Tips;
}

// complete the translations
-(void)finishTranslations
{
    [self convertTipsToXml:[TipManager getEscapedFilename] isEscaped:TRUE];
    [self readTipsXml:[TipManager getEscapedFilename]];
}

// Read stirng source data original format
-(void)readTips
{
    for (int i = kLanguage_English; i < kLanguage_COUNT; ++i) {
        
        NSString* langStr = [EnumHelper getStringForLanguage:(Language)i];
        NSString* tipFile = [NSString stringWithFormat:@"tips_%@", langStr];
        
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSString* myFile = [mainBundle pathForResource: tipFile ofType: @"txt"];
        NSString* source = [NSString stringWithContentsOfFile:myFile encoding:NSASCIIStringEncoding error:nil];
        NSArray* tipsData = [source componentsSeparatedByString:@"<<!>>"];
        
        NSMutableArray* tipArray = [NSMutableArray arrayWithCapacity:100];
        
        int idCount = 0;
        
        // Load all strings and translate them to be ready for lookup
        for (NSString* data in tipsData) {
            
            if ([NSString isWhiteSpace:data]) {
                continue;
            }
            
            // Use this for converted source
            NSString* encoded = [[Utility sharedInstance] convertStringForEncoding:data];
            
            struct Tip t;
            [self intializeTip:&t withDetail:encoded andId:idCount forLanguage:(Language)i];
            
            [tipArray addObject:[NSValue valueWithBytes:&t objCType:@encode(struct Tip)]];
            
            ++idCount;
        }
        
        [_tipDictionary setObject:tipArray forKey:[EnumHelper getCountryCodeForLanguage:(Language)i]];
    }
}

// Read string source data from xml
-(void)readTipsXml:(NSString*)filename
{
    [_tipDictionary removeAllObjects];
    
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

// Builds the string data using xml and escapes to be
-(void)buildEscapedTipsFromXml:(NSString*)filename
{
    struct Tip t;
    
    [_tipDictionary removeAllObjects];
    
    for (int i = kLanguage_English; i < kLanguage_COUNT; ++i) {
        
        int idCount = 0;
        NSMutableArray* arr = [self getTipsForLanguage:(Language)i withFilename:filename];
        NSMutableArray* escapedArr = [NSMutableArray arrayWithCapacity:[arr count]];
        
        // DML
        // add the empty array in the case we are a language to skip
        if (![[Utility sharedInstance] checkForceLanguageValidity:(Language)i]) {
            [_tipDictionary setObject:[NSMutableArray arrayWithCapacity:[arr count]] forKey:[EnumHelper getCountryCodeForLanguage:(Language)i]];
            continue;
        }
        
        // edit each value by applying escape sequences
        for (NSString* value in arr) {
            NSString* escaped = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [escapedArr addObject:escaped];
        }
        
        NSMutableArray* valueArray = [NSMutableArray arrayWithCapacity:[escapedArr count]];
        for (NSString* str in escapedArr) {
            [self intializeTip:&t withDetail:str andId:idCount forLanguage:(Language)i];
            NSValue* value = [NSValue valueWithBytes:&t objCType:@encode(struct Tip)];
            [valueArray addObject:value];
            
            ++idCount;
        }

        // Add escaped array to dictionary
        [_tipDictionary setObject:valueArray forKey:[EnumHelper getCountryCodeForLanguage:(Language)i]];
    }
}

// Writes all stirng data to an xml format
-(void)convertTipsToXml:(NSString*)filename isEscaped:(BOOL)escaped
{
    struct Tip t;
    NSMutableString* xmlString = [NSMutableString stringWithString:@""];
    
    [xmlString appendString:@"<tips>\n"];
    
    // iterate over all tips
    for (int i = 0; i < [self getTipCount:[Strings sharedInstance].CurrentLanguage]; ++i) {
        
        // write tip opener
        [xmlString appendString:@"\t<"];
        [xmlString appendString:[NSString stringWithFormat:@"tip_%d", i]];
        [xmlString appendString:@">\n"];
        
        // Sort the keys by the order of the Languag enum
        NSArray* keys = [_tipDictionary allKeys];
        NSMutableArray* sortedKeys = [NSMutableArray arrayWithCapacity:[keys count]];
        for (int lang = kLanguage_English; lang < kLanguage_COUNT; ++lang) {
            NSString* code = [EnumHelper getCountryCodeForLanguage:(Language)lang];
            
            for (int k = 0; k < [keys count]; ++k) {
                if ([[keys objectAtIndex:k] isEqualToString:code]) {
                    [sortedKeys addObject:[keys objectAtIndex:k]];
                }
            }
        }
        
        // iterate over all countries and add tips to xml
        for (NSString* country in sortedKeys) {
            [xmlString appendString:@"\t\t<"];
            [xmlString appendString:country];
            [xmlString appendString:@">"];
            
            NSMutableArray* tipArray = [_tipDictionary objectForKey:country];
            NSValue* value = nil;
            
            // DML
            if ([tipArray count] > 0) {
                value = [tipArray objectAtIndex:i];
                [value getValue:&t];
            }
            else {
                [self intializeTip:&t withDetail:invalidString andId:-1 forLanguage:[EnumHelper getLanguageFromCountryCode:country]];
            }
            
            // DML
            // add the empty array in the case we are a language to skip
            if (![[Utility sharedInstance] checkForceLanguageValidity:[EnumHelper getLanguageFromCountryCode:country]]) {
                [xmlString appendString:invalidString];
            }
            else {
                [xmlString appendString:t._tipDetail];
            }
            
            [xmlString appendString:@"</"];
            [xmlString appendString:country];
            [xmlString appendString:@">\n"];
        }
        
        // write tip closer
        [xmlString appendString:@"\t</"];
        [xmlString appendString:[NSString stringWithFormat:@"tip_%d", i]];
        [xmlString appendString:@">\n"];
    }
    
    // write closing syntax and write the string to file
    [xmlString appendString:@"</tips>"];
    [xmlString writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:nil];

    // if we are the escaped file then update our stored checksum
    if (escaped) {
        NSString* contents = [NSString stringWithContentsOfFile:[TipManager getFilename] encoding:NSUTF8StringEncoding error:nil];
        NSString* checksum = [contents md5];
        [[NSUserDefaults standardUserDefaults] setObject:checksum forKey:[TipManager xmlChecksumPreferenceName]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/**
 * Initializes the values on the tip
 */
-(void)intializeTip:(struct Tip*)tip withDetail:(NSString*)detail andId:(int)tipId forLanguage:(Language)lang
{
    tip->_tipDetail = [detail retain];
    tip->_tipId = tipId;
    tip->_hasBeenSeen = FALSE;
    tip->_language = lang;
}

/**
 * Randomly selects a tip for display and returns the tip detail to be displayed
 * @param BOOL - onlyUnseen (if this is true, this function will not consider any tips that have already been seen)
 * @return NSString* - Tip._tipDetail (returns the detail from the selected tip) NIL (if it could not find a tip)
 */
-(NSString*)showRandomNextTip:(BOOL)onlyUnseen forLanguage:(Language)lang
{
    // If we have seen all tips, then the loop below would be infinite in duration,
    // so to prevent this, we reset the state on everuy tip, rendering them as unseen.
    if ([self haveAllTipsBeenSeen:lang]) {
        [self reset:lang];
    }
    
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    const int maxFailureCount = 100 * [tipArray count];
    int failureCount = 0;
    
    while (true) {
        
        // Handle the case where we cannot seem to find an unseen tip
        if (failureCount >= maxFailureCount) {
            [self reset:lang];
            failureCount = 0;
        }
        
        int tipIndex = rand() % [tipArray count];
        
        NSValue* value = [tipArray objectAtIndex:tipIndex];
        struct Tip tip;
        [value getValue:&tip];
        
        if (!onlyUnseen || !tip._hasBeenSeen) {
            
            // increment show count
            if (!tip._hasBeenSeen) {
                _shownCount++;
            }
            
            // update the tip stored in the array
            tip._hasBeenSeen = TRUE;
            NSValue* value = [NSValue valueWithBytes:&tip objCType:@encode(struct Tip)];
            [tipArray replaceObjectAtIndex:tipIndex withObject:value];
            
            // save the state of the tips
            [self save:lang];
            
            return (([tip._tipDetail isEqualToString:invalidString]) ? @" " : tip._tipDetail);
        }
        
        ++failureCount;
    }
    
    // Something unexpected went wrong if we get here...
    return nil;
}

/**
 * Saves the state of the tips and whether or not they have been seen
 * @return [BOOL] Returns true on success, false otherwise
 */
-(BOOL)save:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    // Read the user defaults and set the auto lock type
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_shownCount forKey:@"shownCount"];
    
    for (NSValue* value in tipArray) {
        struct Tip tip;
        [value getValue:&tip];
        
        NSString* idStr = [NSString stringWithFormat:@"%d", tip._tipId];
        [defaults setInteger:tip._hasBeenSeen ? 1 : 0 forKey:idStr];
    }
    
    [defaults synchronize];
    
    return TRUE;
}

/**
 * Loads the tip seen info that properly initializes all tips and wheter or not
 * they have already been viewed
 * @return [BOOL] (returns TRUE on success, FALSE otherwise)
 */
-(BOOL)load:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    // insert new tip array for missing languages
    if (tipArray == nil) {
        [_tipDictionary setObject:[NSMutableArray arrayWithCapacity:50] forKey:countryCode];
    }
    
    // Read the user defaults and set the auto lock type
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    int tempCount = 0;
    
    _shownCount = [defaults integerForKey:@"shownCount"];
    
    for (int i = 0; i < [tipArray count]; ++i) {
        struct Tip tip;
        NSValue* value = [tipArray objectAtIndex:i];
        [value getValue:&tip];
        
        // get has been seen value
        NSString* idStr = [NSString stringWithFormat:@"%d", tip._tipId];
        int seen = [defaults integerForKey:idStr];
        tip._hasBeenSeen = seen == 1 ? TRUE : FALSE;
        
        tempCount += seen == 1 ? 1 : 0;
        
        // Update the tip object
        NSValue* newValue = [NSValue valueWithBytes:&tip objCType:@encode(struct Tip)];
        [tipArray replaceObjectAtIndex:i withObject:newValue];
    }
    
    // validate that we have loaded the correct data
    // assert(tempCount == _shownCount);
    
    // Reset the tips if we have seen them all
    if ([self haveAllTipsBeenSeen:lang]) {
        [self reset:lang];
    }
    
    [defaults synchronize];
    
    return TRUE;
}

/**
 * Attempts to show a specific tip, selected by its tip's id
 * @param int - tipId (specifies the tip id we should look for when selecting a tip to show)
 * @return [NSString* tip._tipDetail] (The detail of the selected tip) [nil] (otherwise, if it could not locate the tip by it's id)
 */
-(NSString*)showSpecificTip:(int)tipId forLanguage:(Language)lang
{
    int index = 0;
    BOOL contains = [self containsTipId:tipId outIndex:&index forLanguage:lang];

    // we do not have a tip with the id specified
    if (!contains) {
        return nil;
    }
    
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    NSValue* value = [tipArray objectAtIndex:index];
    struct Tip tip;
    [value getValue:&tip];
    
    // increment show count
    if (!tip._hasBeenSeen) {
        _shownCount++;
    }
    
    // Update the tip stored in the array
    tip._hasBeenSeen = TRUE;
    value = [NSValue valueWithBytes:&tip objCType:@encode(struct Tip)];
    [tipArray replaceObjectAtIndex:index withObject:value];
    
    return (([tip._tipDetail isEqualToString:invalidString]) ? @" " : tip._tipDetail);
    
//    NSString* encodedTipDetail= [[Utility sharedInstance] convertStringForEncoding:tip._tipDetail];
//    return encodedTipDetail;
}

/**
 * Rests the state of the manager informing that we will now begin to show
 * every tip once more since we have already seen all of the tips prior.
 */
-(void)reset:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    for (int i = 0; i < [tipArray count]; ++i) {
        NSValue* value = (NSValue*)[tipArray objectAtIndex:i];
        struct Tip tip;
        [value getValue:&tip];
        
        // Update tip in the array
        tip._hasBeenSeen = FALSE;
        value = [NSValue valueWithBytes:&tip objCType:@encode(struct Tip)];
        [tipArray replaceObjectAtIndex:i withObject:value];
    }
    
    _lastTipId = -1;
    _shownCount = 0;
}

/**
 * Utility function that determines if all tips have been seen by the player
 * @return BOOL - TRUE (if all tips have been) FALSE (otherwise)
 */
-(BOOL)haveAllTipsBeenSeen:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    return self.shownCount == [tipArray count];
}

/** 
 * Utility function that determines if there is a tip that has the tip id specified within the tip array
 * @param [int tipId] the id of a tip we are looking for
 * @param [int* index] this is the ref value that will contain the index within the array of the tip found or, -1 otherwise
 * @return [BOOL] returns true if there was a tip found with a matching id or, FALSE otherwise
 */
-(BOOL)containsTipId:(int)tipId outIndex:(int*)index forLanguage:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    
    for (int i = 0; i < [tipArray count]; ++i) {
        
        NSValue* value = [tipArray objectAtIndex:i];
        struct Tip tip;
        [value getValue:&tip];
        
        if (tip._tipId == tipId) {
            if (index != nil) {
                *index = i;
            }
            return TRUE;
        }
    }
    
    if (index != nil) {
        index = -1;
    }
    
    return FALSE;
}

// Get the tip count
-(int)getTipCount:(Language)lang
{
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    NSMutableArray* tipArray = [_tipDictionary objectForKey:countryCode];
    return [tipArray count];
}

// Handles when an xml element is found for use
-(void)parser:(NSXMLParser*)parser
didStartElement:(NSString*)elementName
 namespaceURI:(NSString*)namespaceURI
qualifiedName:(NSString*)qName
   attributes:(NSDictionary *)attributeDict
{
    if ([elementName rangeOfString:@"tip_"].length > 0) {
        _activeXmlElement = [elementName copy];
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
    if ([NSString isEmptyOrNull:string] || [NSString isWhiteSpace:string] || [string isEqualToString:@"\""]) {
        return;
    }
    
    // if we have a valid key and lang then read the text
    if (_activeXmlElement != nil && _activeXmlLanguage != kLanguage_Invalid) {
        
        NSString* country = [EnumHelper getCountryCodeForLanguage:_activeXmlLanguage];
        NSMutableArray* arr = [_tipDictionary objectForKey:country];
        
        if (arr == nil) {
            arr = [NSMutableArray arrayWithCapacity:kLanguage_COUNT];
        }
        
        NSString* convertedString = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        // DML
        BOOL isInvalid = [string isEqualToString:invalidString];
        NSString* finalString = ((isInvalid) ? string : ((convertedString == nil) ? string : convertedString));
        
        struct Tip tip;
        [self intializeTip:&tip withDetail:((finalString == nil) ? string : convertedString) andId:[arr count] forLanguage:_activeXmlLanguage];
        
        NSValue* value = [NSValue valueWithBytes:&tip objCType:@encode(struct Tip)];
        [arr addObject:value];
        
        // replace the tip array for the language
        [_tipDictionary setObject:arr forKey:country];
    }
}

// Returns an array of all strings defined for the lang passed in
-(NSMutableArray*)getTipsForLanguage:(Language)lang withFilename:(NSString*)filename
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
    
    // English source tips
    NSArray* englishTips = [_tipDictionary objectForKey:[EnumHelper getCountryCodeForLanguage:kLanguage_English]];
    
    // iterate over each keys in the string dictionary, translating any strings
    // that are equal to the empty string
    for (int i = kLanguage_English + 1; i < kLanguage_COUNT; ++i) {
        
        NSString* key = [EnumHelper getCountryCodeForLanguage:(Language)i];
        NSMutableArray* tips = [_tipDictionary objectForKey:key];
        
        // DML
        if (![[Utility sharedInstance] checkForceLanguageValidity:(Language)i]) {
            continue;
        }
        
        for (int j = 0; j < tips.count; ++j) {
            
            // read tip structure
            struct Tip englishTip;
            struct Tip otherTip;
            
            NSValue* enValue = [englishTips objectAtIndex:j];
            NSValue* curValue = [tips objectAtIndex:j];
            [enValue getValue:&englishTip];
            [curValue getValue:&otherTip];
            
            NSString* enStr = englishTip._tipDetail;
            NSString* curTranslation = otherTip._tipDetail;
            
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
                
                // Make sure we have an initialized structure for replacing objects below
                if ([_tipDictionary objectForKey:key] == nil) {
                    [_tipDictionary setObject:[NSMutableArray arrayWithCapacity:100] forKey:key];
                }
                // Make sure we have objects within the array to replace
                while ([[_tipDictionary objectForKey:key] count] <= j) {
                    struct Tip tempTip;
                    NSValue* tempValue = [NSValue valueWithBytes:&tempTip objCType:@encode(struct Tip)];
                    [[_tipDictionary objectForKey:key] addObject:tempValue];
                }
                
                // make the new tip and insert into tip dictionary to replace current value
                struct Tip newTip;
                [self intializeTip:&newTip withDetail:fixedTranslated andId:otherTip._tipId forLanguage:(Language)i];
                NSValue* value = [NSValue valueWithBytes:&newTip objCType:@encode(struct Tip)];
                [[_tipDictionary objectForKey:key] replaceObjectAtIndex:j withObject:value];
                
                NSString* original = [userData objectForKey:@"original"];
                NSLog(@"Translate result: %@ = %@", original, translated);
                [userData release];
                
                _translationCount -= 1;
            };
            
            // should we translate this string
            if (!missingOnly || (missingOnly && [curTranslation isEqualToString:@""])) {
                
                _translationCount += 1;
                
                NSString* unescapedEnStr = [enStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                // read value
                NSValue* value = [englishTips objectAtIndex:j];
                struct Tip tip;
                [value getValue:&tip];
                
                // Build a userData property that will be used to help us pass data in and out of the callback
                NSMutableDictionary* userData = [[NSMutableDictionary dictionaryWithCapacity:32] retain];
                [userData setObject:tip._tipDetail forKey:@"original"];
                [userData setObject:key forKey:@"key"];
                
                [[Utility sharedInstance] translateText:unescapedEnStr
                                     withSourceLanguage:kLanguage_English
                                      andTargetLanguage:(Language)i
                                            andCallback:callback
                                           withUserData:userData];
            }
        }
    }
    
    // clear the queue now that everything has been translated
    //[[Utility sharedInstance] translateQueuedInfos];
}

@end