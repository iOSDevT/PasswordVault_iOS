//
//  PasswordVault.m
//  PasswordVault
//
//  Created by David Leistiko on 12/20/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "Json/NSDictionary_JSONExtensions.h"
#import "NSMutableDictionaryExtension.h"
#import "NSStringExtension.h"
#import "SettingsViewController.h"
#import "Singleton.h"
#import "Strings.h"
#import "Utility.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreText/CTFont.h>

#include <sys/time.h>

#define GET_CASTED_TIME_RESULT(a,b) (((a)*1000ull) + (b)/1000ull)

static NSString* bundleId = @"com.davidleistiko.passwordvault";
static NSString* appStoreId = @"495508185";
static int animCounterId = 0;
static const float minFontSize = 8;
static NSString* googleClientId = @"1087465263700-4i232462ff03lg7d4bef3h9uc75tk16p.apps.googleusercontent.com";
static NSString* googleClientSecret = @"IMQbmDZQ6WG4YZlSsyI-RTBR";
static NSString* googleApiKey = @"AIzaSyBpR9IgbVhISD2LfhwOMQFzWUO567HgEnk";

@interface Utility(Private)
-(void)scheduledAnimation:(NSNumber*)number;
-(float)getAdjustedFontSize:(NSString*)fontName withText:(NSString*)text withMaxWidth:(float)width andStartingSize:(float)size;
-(float)getTextfieldFontSize;
-(float)getDefaultPrimaryFontSize;
-(float)getDefaultTipFontSize;
-(float)getHeaderFontSize;
-(float)getButtonFontSize;
-(void)readFontMetrics:(NSString*)filename;
-(void)convertFontMetricsToXml:(NSString*)filename;
-(void)readFontMetricsXml:(NSString*)filename;
-(float)applySelectedFontSize:(float)fontSize;
-(void)handleConnectionData:(NSData*)data withUserData:(NSMutableDictionary*)userData andCallback:(TranslateTextCallback)callback;
@end

@implementation Utility

@synthesize primaryFont = _primaryFont;
@synthesize primaryFontName = _primaryFontName;
@synthesize primaryFontSize = _primaryFontSize;
@synthesize tipFont = _tipFont;
@synthesize tipFontName = _tipFontName;
@synthesize tipFontSize = _tipFontSize;
@synthesize textfieldTextWidth = _textfieldTextWidth;
@synthesize textviewTextWidth = _textviewTextWidth;
@synthesize buttonTextWidth = _buttonTextWidth;
@synthesize buttonLabelTextWidth = _buttonLabelTextWidth;
@synthesize headerTextWidth = _headerTextWidth;
@synthesize headerSmallTextWidth = _headerSmallTextWidth;
@synthesize tableviewHeaderFooterTextWidth = _tableviewHeaderFooterTextWidth;
@synthesize tableviewCellTextWidth = _tableviewCellTextWidth;
@synthesize largeLabelTextWidth = _largeLabelTextWidth;
@synthesize smallLabelTextWidth = _smallLabelTextWidth;
@synthesize searchbarTextWidth = _searchbarTextWidth;
@synthesize largeTitleTextWidth = _largeTitleTextWidth;
@synthesize smallTitleTextWidth = _smallTitleTextWidth;
@synthesize forceLoadType = _forceLoadType;
@synthesize forceLanguages = _forceLangauges;
@synthesize headerFontSize;
@synthesize buttonFontSize;
@synthesize textfieldFontSize;
@synthesize textviewFontSize;
@synthesize defaultPrimaryFontSize;
@synthesize defaultTipFontSize;
@synthesize tableviewHeaderFooterFontSize;
@synthesize tableviewCellFontSize;
@synthesize largeLabelFontSize;
@synthesize smallLabelFontSize;
@synthesize searchbarFontSize;
@synthesize largeTitleFontSize;
@synthesize smallTitleFontSize;

// Declare the class a singleton
SINGLETON(Utility)

// Returns the source font metric filename
+(NSString*)getFontMetricFilename
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* myFile = [mainBundle pathForResource: @"font_data" ofType: @"txt"];
    return myFile;
}

// Returns the converted xml font metric filename
+(NSString*)getFontMetricXmlFilename
{
    // The source file is stored within the bundle
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* myFile = [mainBundle pathForResource:@"xmlFontMetrics" ofType:@"xml"];
    return myFile;
}

// Returns the extended version of the font metrics system
+(NSString*)getExtendedFontMetricXmlFilename
{
    // The escaped file is stored in the documents directory
    NSString* basefilename = @"xmlFontMetrics_extended";
    NSString* directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@.%@", directory, basefilename, @"xml"];
    return fullPath;
}

// Returns a list of all loaded fonts
+(NSArray*)getDefaultLoadedFonts
{
    NSMutableArray* fonts = [NSMutableArray arrayWithCapacity:300];
    
    for (NSString* str in [UIFont familyNames]) {
        for (NSString* str2 in [UIFont fontNamesForFamilyName:str]) {
            [fonts addObject:str2];
        }
    }
    
    return fonts;
}

// default init func
-(id)init
{
    if (self = [super init])
    {
        _animations = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
        
        _defaultPrimaryFontName = [[NSString stringWithFormat:@"%@", @"PTMono-Bold"] retain];
        _primaryFontName = [[NSString stringWithFormat:@"%@", @"PTMono-Bold"] retain];
        _primaryFontSize = 24.0f;
        _primaryFont = [[UIFont fontWithName:_primaryFontName size:_primaryFontSize] retain];

        _defaultTipFontName = [[NSString stringWithFormat:@"%@", @"UbuntuMono-Bold"] retain];
        _tipFontName = [[NSString stringWithFormat:@"%@", @"UbuntuMono-Bold"] retain];
        _tipFontSize = 12.0f;
        _tipFont = [[UIFont fontWithName:_tipFontName size:_tipFontSize] retain];
        
        _textfieldTextWidth = 240.0f;
        _textviewTextWidth = 240.0f;
        _buttonTextWidth = 175.0f;
        _buttonLabelTextWidth = 175.0f;
        _headerSmallTextWidth = 120.0f;
        _headerTextWidth = 220.0f;
        _tableviewHeaderFooterTextWidth = 240.0f;
        _tableviewCellTextWidth = 150.0f;
        _largeLabelTextWidth = 220.0f;
        _smallLabelTextWidth = 190.0f;
        _searchbarTextWidth = 120.0f;
        _largeTitleTextWidth = 200.0f;
        _smallTitleTextWidth = 150.0f;
        
        _forceLoadType = kForceLoadType_None;
        
        _forceLangauges = [[NSMutableArray arrayWithCapacity:20] retain];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        [_forceLangauges addObject:[NSNumber numberWithBool:TRUE]];
        
        
        _translationQueue = [[NSMutableArray arrayWithCapacity:256] retain];
        
        // Load the font metrics
        _languageAndFontMetrics = [[NSMutableDictionary alloc] initWithCapacity:10];
        
        NSString* file1 = [Utility getFontMetricXmlFilename];
        NSString* file2 = [Utility getExtendedFontMetricXmlFilename];
        
        // Determine which font file to use..
        // if we have manually added a font to our font metric list then we will need to load the extended
        // metrics file until we update the base file contained within the bundle
        if ([[NSFileManager defaultManager] fileExistsAtPath:file2]) {
            NSString* source1 = [NSString stringWithContentsOfFile:file1 encoding:NSUTF8StringEncoding error:nil];
            NSString* source2 = [NSString stringWithContentsOfFile:file2 encoding:NSUTF8StringEncoding error:nil];
            
            source1 = [source1 md5];
            source2 = [source2 md5];
            
            if (source2.length > source1.length) {
                [self readFontMetricsXml:[Utility getExtendedFontMetricXmlFilename]];
            }
            else {
                [self readFontMetricsXml:[Utility getFontMetricXmlFilename]];
            }
        }
        else {
            [self readFontMetricsXml:[Utility getFontMetricXmlFilename]];
            [self convertFontMetricsToXml:[Utility getExtendedFontMetricXmlFilename]];
        }
        
        // initialize sounds
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    return self;
}

// custom dealloc to free mem
-(void)dealloc
{
    [_animations release];
    [_primaryFont release];
    [_tipFont release];
    [_primaryFontName release];
    [_tipFontName release];
    [_languageAndFontMetrics release];
    [_forceLangauges release];
    [_translationQueue release];
    
    [super dealloc];
}

// Returns if we want to translate the language passed in when we
// are in a force load mode
-(BOOL)checkForceLanguageValidity:(Language)lang
{
    // if we are forcing a rebuild, which languages do we want to handle?
    if (self.forceLoadType != kForceLoadType_None) {
        NSArray* langCheck = self.forceLanguages;
        return [[langCheck objectAtIndex:(int)lang] boolValue];
    }
    return TRUE;
}

// Converts string for propert encoding
-(NSString*)convertStringForEncoding:(NSString*)source
{
    // Convert the text to have proper encoding
    const char* converted = nil;
    converted = [source cStringUsingEncoding:NSISOLatin1StringEncoding];
    return converted == nil ? source : [NSString stringWithCString:converted encoding:NSUTF8StringEncoding];
}

// returns the string dimensions
-(CGSize)measureString:(NSString*)str withFont:(UIFont*)font
{
    UIFont* f = font == nil ? _primaryFont : font;
    return [str sizeWithFont:f];
}

// Comapres title length to max pixel length and then adjusts the title view as necessary, then finally, it sets the text
-(void)adjustTitleView:(UIViewController*)controller
         withStringKey:(NSString*)key
          withMaxWidth:(float)maxWidth
       andIsLargeTitle:(BOOL)large
          andAlignment:(NSTextAlignment)alignment
{
    NSString* title = [[Strings sharedInstance] lookupString:key];
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGRect frame = CGRectMake(0, 0, screenWidth, 44);
    
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = alignment;
    
    if (large) {
        [self determineAndSetFontForLargeTitle:label withText:title andMaxWidth:maxWidth andIsTip:FALSE];
    }
    else {
        [self determineAndSetFontForSmallTitle:label withText:title andMaxWidth:maxWidth andIsTip:FALSE];
    }
    
    label.text = title;
    controller.navigationItem.titleView = label;
}

// returns the current time in ms
-(unsigned long long)getCurrentTime
{
    struct timeval time;
    gettimeofday(&time, NULL);
    unsigned long long ms = GET_CASTED_TIME_RESULT(time.tv_sec, time.tv_usec);
    return ms;
}

// Returns the image modified with the alpha value passed in
-(UIImage*)addImageAlpha:(UIImage*)image withAlpha:(CGFloat)alpha
{
    CGRect rect = CGRectZero;
    rect.size = image.size;
    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:rect blendMode:kCGBlendModeScreen alpha:alpha];
    UIImage * translucentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return translucentImage;
}

// Returns the image modified to have the new size specified
-(UIImage*)resizeImage:(UIImage *)original withSize:(CGSize)size
{
    //avoid redundant drawing
    if (CGSizeEqualToSize(original.size, size))
    {
        return original;
    }
    
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [original drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return image
    return image;
}

// Returns the number of animations waiting to be processed
-(int)getPendingAnimationCount
{
    return [_animations count];
}

// Adds a new animation to the dictionary to be processed after the delay.
-(void)animateControl:(UIView*)control withStart:(CGRect)start withEnd:(CGRect)end withTime:(float)time andDelay:(float)delay
{
    // Create new animation struct
    struct Animation anim;
    anim.animId = ++animCounterId;
    anim.control = control;
    anim.startFrame = start;
    anim.endFrame = end;
    anim.time = time;
    
    // Add the animation to the dictionary
    NSValue* value = [NSValue valueWithBytes:&anim objCType:@encode(struct Animation)];
    [_animations setObject:value forKey:[NSNumber numberWithInt:anim.animId]];
    
    if (delay <= 0.0f) {
        [self scheduledAnimation:[NSNumber numberWithInt:anim.animId]];
    }
    else {
        anim.control.frame = anim.startFrame;
        [self performSelector:@selector(scheduledAnimation:) withObject:[NSNumber numberWithInt:anim.animId] afterDelay:delay];
    }
}

// Process the animation here
-(void)scheduledAnimation:(NSNumber*)number
{
    NSValue* value = (NSValue*)[_animations objectForKey:number];
    
    // decode the animation
    struct Animation animation;
    [value getValue:&animation];
    
    // process the animation now...
    animation.control.frame = animation.startFrame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animation.time];
    animation.control.frame = animation.endFrame;
    [UIView commitAnimations];
    
    // remove the animation from the dictionary now that we have processed it
    [_animations removeObjectForKey:number];
}

// Attempts to set the title color for a button within an actionSheet
-(BOOL)adjustActionSheetButtonColor:(UIActionSheet*)actionSheet withButtonTitle:(NSString*)title andColor:(UIColor*)color
{
    NSArray *actionSheetButtons = actionSheet.subviews;
    
    for (int i = 0; [actionSheetButtons count] > i; i++) {
        UIView *view = (UIView*)[actionSheetButtons objectAtIndex:i];
        if([view isKindOfClass:[UIButton class]]){
            UIButton *btn = (UIButton*)view;
            if ([[btn titleLabel].text isEqualToString:title]) {
                [btn setTitleColor:color forState:UIControlStateNormal];
                return TRUE;
            }
        }
    }
    
    return FALSE;
}

// Changes the primary font to the font specified by the name passed in
-(void)changePrimaryFont:(NSString *)fontName withSize:(float)size
{
    _primaryFontSize = size <= 0 ? self.defaultPrimaryFontSize : size;
    
    [_primaryFontName release];
    _primaryFontName = [fontName retain];
    
    [_primaryFont release];
    _primaryFont = [[UIFont fontWithName:fontName size:_primaryFontSize] retain];
}

// Changes the tip font to the font specified by the name passed in
-(void)changeTipFont:(NSString*)fontName withSize:(float)size
{
    _tipFontSize = size <= 0 ? self.defaultTipFontSize : size;
    
    [_tipFontName release];
    _tipFontName = [fontName retain];
    
    [_tipFont release];
    _tipFont = [[UIFont fontWithName:fontName size:_tipFontSize] retain];
}

// Returns the font size for the title
-(float)getTitleFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"title"]) floatValue]];
}

// Returns the font size for the textfield
-(float)getTextfieldFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"textfield"]) floatValue]];
}

// Returns the font size for the textfield
-(float)getTextviewFontSize
{
    // NOTE: textview size shares the same metric as textfield does
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"textfield"]) floatValue]];
}

// Returns the default primary font size
-(float)getDefaultPrimaryFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"primary"]) floatValue]];
}

// Returns the default tip font size
-(float)getDefaultTipFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    
    // NOTE: for tips we do not want to call "applySelectedFontSize" since we want tips
    // to always stay at the right size
    return [((NSNumber*)[fontMetric objectForKey:@"tip"]) floatValue];
}

// Returns the default header size
-(float)getHeaderFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"header"]) floatValue]];
}

// Returns the default button size
-(float)getButtonFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"button"]) floatValue]];
}

// Returns the default tableview header size
-(float)getTableviewHeaderFooterFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"tableviewHeader"]) floatValue]];
}

// Returns the default tableview header size
-(float)getTableviewCellFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"tableviewCell"]) floatValue]];
}

// Returns the default label size for large labels
-(float)getLargeLabelFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"largeLabel"]) floatValue]];
}

// Returns the default label size for small labels
-(float)getSmallLabelFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"smallLabel"]) floatValue]];
}

// Returns the default label size for small labels
-(float)getSearchbarFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"searchbar"]) floatValue]];
}

// Returns the default label size for small labels
-(float)getLargeTitleFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"largeTitle"]) floatValue]];
}

// Returns the default label size for small labels
-(float)getSmallTitleFontSize
{
    NSMutableDictionary* languageMetric = [_languageAndFontMetrics objectForKey:
                                           [EnumHelper getCountryCodeForLanguage:
                                            [Strings sharedInstance].CurrentLanguage]];
    NSMutableDictionary* fontMetric = [languageMetric objectForKey:self.primaryFontName];
    return [self applySelectedFontSize:[((NSNumber*)[fontMetric objectForKey:@"smallTitle"]) floatValue]];
}

// Attempts to find the smallest font that will satisfy the max width property
-(float)getAdjustedFontSize:(NSString*)fontName withText:(NSString*)text withMaxWidth:(float)width andStartingSize:(float)size
{
    float curSize = size;
    UIFont* font = nil;
    
    while (true && curSize >= 4.0f) {
        
        font = [UIFont fontWithName:fontName size:curSize];
        CGSize strSize = [self measureString:text withFont:font];
        
        if (strSize.width > width) {
            curSize -= 1.0f;
            continue;
        }
        
        break;
    }
    
    return curSize;
}

// Determines the font size to use for the textfield
-(float)determineAndSetFontForTextfield:(UITextField*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.textfieldFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the font size to use for the textview
-(float)determineAndSetFontForTextview:(UITextView*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.textfieldFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the font size to use for the button
-(float)determineAndSetFontForButton:(UIButton*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.buttonFontSize];
    if (view != nil) {
        view.titleLabel.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the font size to use for the button
-(float)determineAndSetFontForButtonLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.buttonFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}


// Determins the font size to use for the label
-(float)determineAndSetFontForTableviewHeaderFooter:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.tableviewHeaderFooterFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the font size to use for the label
-(float)determineAndSetFontForTableviewCell:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.tableviewCellFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the fonr size to use for large labels
-(float)determineAndSetFontForLargeLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.largeLabelFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the fonr size to use for large labels
-(float)determineAndSetFontForSmallLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.smallLabelFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the fonr size to use for large labels
-(float)determineAndSetFontForSearchbar:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.searchbarFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the fonr size to use for large labels
-(float)determineAndSetFontForLargeTitle:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.largeTitleFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Determines the fonr size to use for large labels
-(float)determineAndSetFontForSmallTitle:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip
{
    int widthToUse = width <= 0.0f ? view.frame.size.width : width;
    float fontSize = [self getAdjustedFontSize:tip ? _tipFontName : _primaryFontName
                                      withText:text
                                  withMaxWidth:widthToUse
                               andStartingSize:self.smallTitleFontSize];
    if (view != nil) {
        view.font = [UIFont fontWithName:tip ? _tipFontName : _primaryFontName size:fontSize];
    }
    return fontSize;
}

// Loads the font info and creates dictionaries to store the data
-(void)readFontMetrics:(NSString*)filename
{
    NSString* source = [NSString stringWithContentsOfFile:filename encoding:NSASCIIStringEncoding error:nil];
    NSArray* stringData = [source componentsSeparatedByString:@"<<!>>"];
    NSString* curLang = @"";
    
    // clear any current data
    [_languageAndFontMetrics removeAllObjects];
    
    for (NSString* data in stringData) {
        
        data = [NSString removeAllWhitespace:data];
        
        // skip any whitespace
        if (data.length < 2) {
            continue;
        }
        
        // Are we a language code?
        if (data.length == 2) {
            curLang = data;
        }
        else {
            
            NSArray* fontInfo = [data componentsSeparatedByString:@":"];
            NSString* curFont = @"";
            NSString* curData = @"";
            NSMutableDictionary* fontDictionary = [NSMutableDictionary dictionaryWithCapacity:25];
            
            for (NSString* fontInfoStr in fontInfo) {
                
                fontInfoStr = [NSString removeAllWhitespace:fontInfoStr];
                
                NSArray* fontAndData = [fontInfoStr componentsSeparatedByString:@">>"];
                curFont = [NSString removeAllWhitespace:[fontAndData objectAtIndex:0]];
                curData = [NSString removeAllWhitespace:[fontAndData objectAtIndex:1]];
                
                // Now we get all of the size info for the font
                NSMutableDictionary* sizeDictionary = [NSMutableDictionary dictionaryWithCapacity:25];
                NSArray* sizeInfo = [curData componentsSeparatedByString:@","];
                
                // Iterate over all of the sizes...
                for (NSString* sizeStr in sizeInfo) {
                    sizeStr = [NSString removeAllWhitespace:sizeStr];
                    
                    NSArray* nameAndSize = [sizeStr componentsSeparatedByString:@"="];
                    NSString* sizeName = [NSString removeAllWhitespace:[nameAndSize objectAtIndex:0]];
                    NSString* sizeSize = [NSString removeAllWhitespace:[nameAndSize objectAtIndex:1]];
                    
                    // add the size for the name
                    [sizeDictionary setObject:[NSNumber numberWithFloat:[sizeSize floatValue]] forKey:sizeName];
                }
                
                [fontDictionary setObject:sizeDictionary forKey:curFont];
            }
            
            // add the new dictionary with for the language identified
            [_languageAndFontMetrics setObject:fontDictionary forKey:curLang];
        }
    }
}

// Converts the font metric data to xml
-(void)convertFontMetricsToXml:(NSString*)filename
{    
    NSMutableString* xmlString = [NSMutableString stringWithString:@""];
    
    [xmlString appendString:@"<fontInfos>\n"];
    
    for (int i = 0; i < kLanguage_COUNT; ++i) {
        
        NSString* country = [EnumHelper getCountryCodeForLanguage:(Language)i];
        NSDictionary* tempDict = [_languageAndFontMetrics objectForKey:country];
        
        // iterate over all fonts
        for (NSString* fontName in tempDict) {
            
            // write font info with fontname
            [xmlString appendString:@"\t<fontInfo id=\""];
            [xmlString appendString:[NSString stringWithFormat:@"%@\"", fontName]];
            [xmlString appendString:@">\n"];
            
            // iterate over all languages for the font
            for (int j = 0; j < kLanguage_COUNT; ++j) {
                NSString* key = [EnumHelper getCountryCodeForLanguage:(Language)j];
                
                // Open country code
                [xmlString appendString:[NSString stringWithFormat:@"\t\t<%@>\n", key]];
                
                NSDictionary* fontDict = [_languageAndFontMetrics objectForKey:key];
                NSDictionary* sizeDict = [fontDict objectForKey:fontName];
                
                // write all size values
                for (NSString* sizeName in [sizeDict allKeys]) {
                    float value = [[sizeDict objectForKey:sizeName] floatValue];
                    [xmlString appendString:[NSString stringWithFormat:@"\t\t\t<%@>%.2f</%@>\n", sizeName, value, sizeName]];
                }
                
                // Close country code
                [xmlString appendString:[NSString stringWithFormat:@"\t\t</%@>\n", key]];
            }
            
            // Close font element
            [xmlString appendString:@"\t</fontInfo>\n"];
        }
    }
    
    // close outermost element
    [xmlString appendString:@"</fontInfos>\n"];
    [xmlString writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

// Reads the font metrics as xml
-(void)readFontMetricsXml:(NSString*)filename
{
    [_languageAndFontMetrics removeAllObjects];
    
    NSString* source = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    NSData* data = [source dataUsingEncoding:NSUTF8StringEncoding];
    
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    
    // Since the parse function is a blocking function
    // we can safely dispose of the parse now
    [parser release];
}

// Checks if the is an existing font metric for the font and language specified
-(BOOL)doesFontMetricExist:(NSString*)fontName withLanguage:(Language)lang
{
    // add metric for all languages....
    NSString* countryCode = [EnumHelper getCountryCodeForLanguage:lang];
    for (NSString* key in [_languageAndFontMetrics allKeys]) {
        if ([key isEqual:countryCode]) {
            NSDictionary* dict = [_languageAndFontMetrics objectForKey:key];
            for (NSString* dictFontName in [dict allKeys]) {
                if ([dictFontName isEqual:fontName]) {
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

// This function will dynamically add a font to the font metrics by copying an
// existing entry and using that for its default values
-(BOOL)addFontMetric:(NSString*)fontName withSizeDict:(NSMutableDictionary*)sizeDict
{
    for (int i = 0; i < kLanguage_COUNT; ++i) {
        NSString* key = [EnumHelper getCountryCodeForLanguage:(Language)i];
        NSMutableDictionary* dict = [_languageAndFontMetrics objectForKey:key];
        
        UIFont* font = [UIFont fontWithName:fontName size:13.0f];
        if ([self doesFontSupportLanguage:font withLanguague:(Language)i]) {

            if (sizeDict == nil) {
                NSMutableDictionary* clone = [[[dict allValues] objectAtIndex:0] deepCopy];
                [dict setObject:clone forKey:fontName];
            }
            else {
                [dict setObject:sizeDict forKey:fontName];
            }
        }
    }
    
    [self convertFontMetricsToXml:[Utility getExtendedFontMetricXmlFilename]];
    
    return TRUE;
}

// this returns a list of all of the keys used for determining font metrics
-(NSArray*)getFontMetricSizeNames
{
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:20];
    [arr addObject:@"button"];
    [arr addObject:@"header"];
    [arr addObject:@"textfield"];
    [arr addObject:@"primary"];
    [arr addObject:@"tip"];
    [arr addObject:@"passwordLength"];
    [arr addObject:@"loading"];
    [arr addObject:@"tableviewHeader"];
    [arr addObject:@"tableviewCell"];
    [arr addObject:@"largeLabel"];
    [arr addObject:@"smallLabel"];
    [arr addObject:@"searchbar"];
    [arr addObject:@"largeTitle"];
    [arr addObject:@"smallTitle"];
    return arr;
}

// returns a dictionary containing default font metric values
-(NSDictionary*)getDefaultFontMetrics
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:20];
    [dict setObject:[NSNumber numberWithFloat:14.0] forKey:@"button"];
    [dict setObject:[NSNumber numberWithFloat:14.0] forKey:@"header"];
    [dict setObject:[NSNumber numberWithFloat:13.0] forKey:@"textfield"];
    [dict setObject:[NSNumber numberWithFloat:24.0] forKey:@"primary"];
    [dict setObject:[NSNumber numberWithFloat:12.0] forKey:@"tip"];
    [dict setObject:[NSNumber numberWithFloat:12.0] forKey:@"passwordLength"];
    [dict setObject:[NSNumber numberWithFloat:14.0] forKey:@"loading"];
    [dict setObject:[NSNumber numberWithFloat:13.0] forKey:@"tableviewHeader"];
    [dict setObject:[NSNumber numberWithFloat:13.0] forKey:@"tableviewCell"];
    [dict setObject:[NSNumber numberWithFloat:20.0] forKey:@"largeLabel"];
    [dict setObject:[NSNumber numberWithFloat:14.0] forKey:@"smallLabel"];
    [dict setObject:[NSNumber numberWithFloat:13.0] forKey:@"searchbar"];
    [dict setObject:[NSNumber numberWithFloat:16.0] forKey:@"largeTitle"];
    [dict setObject:[NSNumber numberWithFloat:11.0] forKey:@"smallTitle"];
    return dict;
}

// Returns a specific font metric for lang and font specified
-(NSDictionary*)getFontMetricFor:(NSString*)fontName forLanguage:(Language)lang
{
    NSString* code = [EnumHelper getCountryCodeForLanguage:lang];
    NSDictionary* dict = [_languageAndFontMetrics objectForKey:code];
    if (dict != nil) {
        NSDictionary* metric = [dict objectForKey:fontName];
        return metric;
    }
    
    // could not be found
    return nil;
}

// Handles when an xml element is found for use
-(void)parser:(NSXMLParser*)parser
didStartElement:(NSString*)elementName
 namespaceURI:(NSString*)namespaceURI
qualifiedName:(NSString*)qName
   attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"fontInfos"]) {
        return;
    }
    
    // do we have a font info?
    if ([elementName isEqualToString:@"fontInfo"]) {
        _activeXmlFontName = [[attributeDict objectForKey:@"id"] retain];
        return;
    }
    
    // do we have a language?
    Language lang = [EnumHelper getLanguageFromCountryCode:elementName];
    if (lang != kLanguage_Invalid) {
        _activeXmlLanguage = lang;
        return;
    }
    
    // do we have a size?
    _activeXmlSizeName = [elementName retain];
    _activeXmlSizeValue = [[attributeDict objectForKey:@"val"] floatValue];
}

// Handles when an element has finished being processed
-(void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
    // did we finish reading the fontInfo element?
    if (_activeXmlFontName != nil && [elementName isEqualToString:@"fontInfo"]) {
        [_activeXmlFontName release];
        _activeXmlFontName = nil;
        _activeXmlLanguage = kLanguage_Invalid;
    }
    // did we finsih reading an active size element?
    else if (_activeXmlSizeName != nil && [elementName isEqualToString:_activeXmlSizeName]) {
        [_activeXmlSizeName release];
        _activeXmlSizeName = nil;
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
    if (_activeXmlFontName != nil && _activeXmlLanguage != kLanguage_Invalid && _activeXmlSizeName != nil) {
        
        NSString* countryKey = [EnumHelper getCountryCodeForLanguage:_activeXmlLanguage];
        NSMutableDictionary* fontDict = [_languageAndFontMetrics objectForKey:countryKey];
        
        // if we don't have an entry then add it now
        if (fontDict == nil) {
            [_languageAndFontMetrics setObject:[NSMutableDictionary dictionaryWithCapacity:30] forKey:countryKey];
            fontDict = [_languageAndFontMetrics objectForKey:countryKey];
        }
        
        NSMutableDictionary* sizeDict = [fontDict objectForKey:_activeXmlFontName];
        if (sizeDict == nil) {
            [fontDict setObject:[NSMutableDictionary dictionaryWithCapacity:kLanguage_COUNT] forKey:_activeXmlFontName];
            sizeDict = [fontDict objectForKey:_activeXmlFontName];
        }
        
        _activeXmlSizeValue = [string floatValue];
        [sizeDict setObject:[NSNumber numberWithFloat:_activeXmlSizeValue] forKey:_activeXmlSizeName];
    }
}

// Checks if the font supports a given character
-(BOOL)doesFontContainCharacter:(UIFont*)font withChar:(unichar)character
{
    NSCharacterSet *characterSet = [font.fontDescriptor objectForKey:UIFontDescriptorCharacterSetAttribute];
    return [characterSet characterIsMember:character];
}

// Helper function that verifies if a font supportes a language
-(BOOL)doesFontSupportLanguage:(UIFont*)font withLanguague:(Language)lang
{
    NSString* sampleString = [[Strings sharedInstance] lookupString:@"testString" withLanguage:lang];
    
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    NSUInteger count = sampleString.length;
    unichar characters[count];
    [sampleString getCharacters:characters range:NSMakeRange(0, count)];
    CGGlyph glyphs[count];
    
    // add the font if chars are supported!!
    if (CTFontGetGlyphsForCharacters(fontRef, characters, glyphs, count) == TRUE) {
        return YES;
    }
    return NO;
}

// This function checks the initial font passed in and will return nil in the case that the default font does
// in fact support the language passed in.  In the case that the font fails, a search is done through all
// available fonts looking for any that would support the language, and it then returns an array containing
// all supporting fonts.
-(NSArray*)findAlternateFontsThatSupportLanguage:(Language)lang withFontSize:(float)size
{
    NSMutableArray* supportingFonts = [NSMutableArray arrayWithCapacity:200];
    
    for (NSString* str in [UIFont familyNames]) {
        for (NSString* fname in [UIFont fontNamesForFamilyName:str]) {
            UIFont* curFont = [UIFont fontWithName:fname size:size];
            BOOL result = [self doesFontSupportLanguage:curFont withLanguague:lang];
            if (result) {
                [supportingFonts addObject:curFont];
            }
        }
    }
    
    // return list of supporting fonts
    return supportingFonts;
}



// Returns a list of fonts that support the language passed in
-(NSArray*)getDefaultSupportiveFontsFor:(Language)lang andForTips:(BOOL)tips
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:200];

    // These are shared fontsa among all languages
    if (tips == FALSE) {
        [array addObject:@"Helvetica"];
        [array addObject:@"TrebuchetMS"];
        [array addObject:@"GillSans-BoldItalic"];
        [array addObject:@"MarkerFelt-Thin"];
        [array addObject:@"AmericanTypewriter"];
        [array addObject:@"Noteworthy-Light"];
        [array addObject:@"Palatino-Italic"];
        [array addObject:@"Arial-BoldMT"];
        [array addObject:@"AppleSDGothicNeo-Medium"];
        [array addObject:@"HelveticaNeue-MediumItalic"];
        [array addObject:@"TimesNewRomanPSMT"];
        [array addObject:@"Menlo-BoldItalic"];
        [array addObject:@"IowanOldStyle-Roman"];
        [array addObject:@"Cochin-BoldItalic"];
        [array addObject:@"Helvetica-Oblique"];
        [array addObject:@"Thonburi-Light"];
        [array addObject:@"HoeflerText-BlackItalic"];
        [array addObject:@"Georgia-Italic"];
        [array addObject:@"Superclarendon-Light"];
        [array addObject:@"Verdana-Bold"];
        [array addObject:@"CourierNewPSMT"];
        [array addObject:@"CourierNewPS-BoldItalicMT"];
        [array addObject:@"Didot-Bold"];
        [array addObject:@"DINAlternate-Bold"];
        [array addObject:@"ChalkboardSE-Regular"];
        [array addObject:@"AvenirNext-Medium"];
        [array addObject:@"Copperplate-Bold"];
        [array addObject:@"Baskerville-SemiBold"];
        [array addObject:@"Avenir-Heavy"];
        [array addObject:@"AmericanTypewriter-Condensed"];
        [array addObject:@"AmericanTypewriter-CondensedBold"];
        [array addObject:@"STHeitiTC-Medium"];
        [array addObject:@"TimesNewRomanPS-ItalicMT"];
        [array addObject:@"TimesNewRomanPS-BoldMT"];
        [array addObject:@"SavoyeLetPlain"];
        [array addObject:@"HiraMinProN-W6"];
        [array addObject:@"Verdana-BoldItalic"];
        [array addObject:@"Cochin-Bold"];
    }
    // Add common tip fonts
    else {
        [array addObject:@"PTMono-Bold"];
        [array addObject:@"Instruction-Italic"];
    }
    
    // build list of font names for specified language
    switch (lang) {
        // Build English fonts
        case kLanguage_English:
            if (tips == TRUE) {
                [array addObject:@"saxmono"];
                [array addObject:@"Pointfree-Regular"];
                [array addObject:@"SourceCodePro-Bold"];
            }
            else {
                [array addObject:@"PTMono-Bold"];
                [array addObject:@"saxmono"];
                [array addObject:@"Pointfree-Regular"];
                [array addObject:@"SourceCodePro-Bold"];
                [array addObject:@"Instruction-Italic"];
            }
            break;
        // Build Russian fonts
        case kLanguage_Russian:
        case kLanguage_German:
        case kLanguage_Italian:
        case kLanguage_French:
            break;
        // Build Spanish fonts
        case kLanguage_Spanish:
            if (tips == TRUE) {
                [array addObject:@"saxmono"];
                [array addObject:@"Pointfree-Regular"];
                [array addObject:@"SourceCodePro-Bold"];
            }
            break;
        default:
            break;
    }
    
    // return the results
    return array;
}

//To get hexEncoded string to pass to server:
-(NSString*)converTotHex:(NSString*)source
{
    size_t theLength = strlen([source cStringUsingEncoding:NSWindowsCP1251StringEncoding]);
    const char *selfChar = [source cStringUsingEncoding:NSWindowsCP1251StringEncoding];
    NSData *stringData = [NSData dataWithBytes:selfChar length:theLength];
    NSString * hexStr = [NSString stringWithFormat:@"%@", stringData];
    for(NSString * toRemove in [NSArray arrayWithObjects:@"<", @">", @" ", nil])
    {
        hexStr = [hexStr stringByReplacingOccurrencesOfString:toRemove withString:@""];
    }
    return hexStr;
}


-(NSString*)convertFromHex:(NSString*)source
{
    NSData *bytes = [self dataFromHexString:source];
    NSString *toReturn = [[NSString alloc] initWithData:bytes encoding:NSWindowsCP1251StringEncoding];
    return toReturn;
}

-(NSData*)dataFromHexString:(NSString*)source
{
    const char *chars = [source UTF8String];
    int i = 0, len = source.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

// takes the input font size and adds to it a value that is determined by our selectedFontSize
-(float)applySelectedFontSize:(float)fontSize
{
    PrimaryFontSize preferenceSize = [SettingsViewController getPreferenceFontSize];
    switch (preferenceSize) {
        case kPrimaryFontSize_Extra_Small:      return fontSize - 4.0f;
        case kPrimaryFontSize_Small:            return fontSize - 2.0f;
        case kPrimaryFontSize_Medium:           return fontSize + 0.0f;
        case kPrimaryFontSize_Large:            return fontSize + 3.0f;
        case kPrimaryFontSize_ExtraLarge:       return fontSize + 6.0f;
        default:                                return fontSize + 0.0f;
    }
}

// Clears out all stored user defaults
-(void)clearUserDefaults
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defaults dictionaryRepresentation];
    for (id key in dict) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
    
    [NSUserDefaults resetStandardUserDefaults];
}

// Play a specifc sound
-(BOOL)playSound:(SoundType)sound
{
    NSString* filename = @"";
    switch (sound) {
        case kSoundType_ButtonClick:
            filename = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"mp3"];
            break;
        default:
            filename = @"";
            break;
    }
    
    NSURL* url =  [NSURL fileURLWithPath:filename];
    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    player.delegate = self;
    
    // if we could not get the player then return early
    if (player == nil) {
        return FALSE;
    }
    
    [player play];
    return TRUE;
}

// Called when the sound completes, at which point we can trash the player to free resource
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    [player release];
}

// Invokes the functionality to hit google translate api to get some text translated
-(void)translateText:(NSString*)source
  withSourceLanguage:(Language)sourceLang
   andTargetLanguage:(Language)targetLang
         andCallback:(void(^)(NSString*,NSString*, NSMutableDictionary*))callback
        withUserData:(NSMutableDictionary*)userData;
{
    struct TranslateTextInfo info;
    info._source = [source copy];
    info._sourceLang = sourceLang;
    info._targetLang = targetLang;
    info._callback = [callback copy];
    info._userData = [[NSMutableDictionary dictionaryWithCapacity:32] retain];
    
    // copy elements in userData dictionary
    if (userData != nil) {
        for (NSString* key in [userData allKeys]) {
            [info._userData setObject:[userData objectForKey:key] forKey:key];
        }
    }
    
    // append our info to the queue to be processed at a later time
    NSValue* value = [NSValue valueWithBytes:&info objCType:@encode(struct TranslateTextInfo)];
    [_translationQueue addObject:value];
}

-(BOOL)translateQueuedInfo {
    
    if ([_translationQueue count] == 0) {
        return FALSE;
    }
    
    NSValue* value = [_translationQueue objectAtIndex:0];
    
    // recover the translation info
    struct TranslateTextInfo info;
    [value getValue:&info];
    
    // read our needed variables
    NSString* source = info._source;
    Language sourceLang = info._sourceLang;
    Language targetLang = info._targetLang;
    TranslateTextCallback callback = info._callback;
    NSMutableDictionary* userData = info._userData;
    
    // get the country codes to use so that google will know which languages we are
    // using for the translation
    NSString* sourceCountryCode = [EnumHelper getCountryCodeForLanguage:sourceLang];
    NSString* targetCountryCode = [EnumHelper getCountryCodeForLanguage:targetLang];
    
    // convert our text to html so that we can take advantage of the "notranslate" feature
    NSString* htmlSource = [NSString stringWithFormat:@"<p>%@<p>", source];
    htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"%d" withString:@"<span class=\"notranslate\">%d</span>"];
    htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"%@" withString:@"<span class=\"notranslate\">%@</span>"];
    htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"'" withString:@"<span class=\"notranslate\">'</span>"];
    
    // we need to escape our translation text
    NSString *textEscaped = [htmlSource stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // now we build the url to make the request to goole
    NSMutableString* url = [NSMutableString stringWithCapacity:256];
    [url appendString:@"https://www.googleapis.com/language/translate/v2?key="];
    [url appendString:googleApiKey];
    [url appendString:[NSString stringWithFormat:@"&q=%@", textEscaped]];
    [url appendString:[NSString stringWithFormat:@"&source=%@", sourceCountryCode]];
    [url appendString:[NSString stringWithFormat:@"&target=%@", targetCountryCode]];
    
    [userData setObject:sourceCountryCode forKey:@"sourceLanguage"];
    [userData setObject:targetCountryCode forKey:@"targetLanguage"];
    
    // Use synchronous connection to avoid hangs on threads..
    NSError* error = nil;
    NSURLRequest *request = [[NSURLRequest requestWithURL:[NSURL URLWithString:url]] retain];
    NSURLResponse* response = [[NSURLResponse alloc] init];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [self handleConnectionData:data withUserData:userData andCallback:callback];
    
    // free user data
    [info._source release];
    [info._callback release];
    
    [_translationQueue removeObjectAtIndex:0];
    
    return TRUE;
    
}

// Translate all items in the queue
-(void)translateQueuedInfos {
    
    while (_translationQueue.count > 0) {
        [self translateQueuedInfo];
    }
    [_translationQueue removeAllObjects];
    
//    // iterate over all translation data to ensure that we translate
//    // each and every string needed
//    for (NSValue* value in _translationQueue) {
//        
//        // recover the translation info
//        struct TranslateTextInfo info;
//        [value getValue:&info];
//        
//        // read our needed variables
//        NSString* source = info._source;
//        Language sourceLang = info._sourceLang;
//        Language targetLang = info._targetLang;
//        TranslateTextCallback callback = info._callback;
//        NSMutableDictionary* userData = info._userData;
//        
//        // get the country codes to use so that google will know which languages we are
//        // using for the translation
//        NSString* sourceCountryCode = [EnumHelper getCountryCodeForLanguage:sourceLang];
//        NSString* targetCountryCode = [EnumHelper getCountryCodeForLanguage:targetLang];
//        
//        // convert our text to html so that we can take advantage of the "notranslate" feature
//        NSString* htmlSource = [NSString stringWithFormat:@"<p>%@<p>", source];
//        htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"%d" withString:@"<span class=\"notranslate\">%d</span>"];
//        htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"%@" withString:@"<span class=\"notranslate\">%@</span>"];
//        htmlSource = [htmlSource stringByReplacingOccurrencesOfString:@"'" withString:@"<span class=\"notranslate\">'</span>"];
//
//        // we need to escape our translation text
//        NSString *textEscaped = [htmlSource stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        
//        // now we build the url to make the request to goole
//        NSMutableString* url = [NSMutableString stringWithCapacity:256];
//        [url appendString:@"https://www.googleapis.com/language/translate/v2?key="];
//        [url appendString:googleApiKey];
//        [url appendString:[NSString stringWithFormat:@"&q=%@", textEscaped]];
//        [url appendString:[NSString stringWithFormat:@"&source=%@", sourceCountryCode]];
//        [url appendString:[NSString stringWithFormat:@"&target=%@", targetCountryCode]];
//        
//        [userData setObject:sourceCountryCode forKey:@"sourceLanguage"];
//        [userData setObject:targetCountryCode forKey:@"targetLanguage"];
//        
//        // Use synchronous connection to avoid hangs on threads..
//        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//        NSURLResponse* response = [[NSURLResponse alloc] init];
//        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
//        [self handleConnectionData:data withUserData:userData andCallback:callback];
//    }
    
    // free the queues of objects to translate
    [_translationQueue removeAllObjects];
}

// This function is called when the data for an NSURLConnection is returned
-(void)handleConnectionData:(NSData*)data withUserData:(NSMutableDictionary*)userData andCallback:(TranslateTextCallback)callback
{
    // use the data to init a json dictionary
    NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableDictionary* responseDict = [NSDictionary dictionaryWithJSONString:responseString error:nil];
    
    // free json string result
    [responseString release];
    
    // if we were able to create a valid dictionary from the json... then were in golden!!
    if (responseDict != nil) {
        
        NSDictionary* dataDict = [responseDict objectForKey:@"data"];
        if (dataDict != nil) {
            
            NSArray* translationArray = [dataDict objectForKey:@"translations"];
            for (int i = 0; i < translationArray.count; ++i) {
                
                NSDictionary* translationDict = [translationArray objectAtIndex:i];
                NSString* translatedText = [translationDict objectForKey:@"translatedText"];
                
                // if we have a callback set, then make that call now and delete
                // the block after we have passed the result
                if (callback != nil) {
                    callback([userData objectForKey:@"sourceText"], translatedText, userData);
                }
            }
        }
    }
}

//// Called when we first get a response
//-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    [_translateData setLength:0];
//}
//
//// Called when we have received data back
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data {
//    [_translateData appendData:data];
//}
//
//// Called when an error occurs
//-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError*)error {
//    if (_translateCallback != nil) {
//        [_translateCallback release];
//        _translateCallback = nil;
//    }
//}
//
//// Called when the url has been successfully connected to and we now have a result
//-(void)connectionDidFinishLoading:(NSURLConnection*)connection
//{
//    // retrieve source text and then free the connection that was allocated
//    NSURLRequest* userDataKey = [connection currentRequest];
//    NSMutableDictionary* userData = [_translateSourceDictionary objectForKey:userDataKey];
//    [connection release];
//    
//    NSString* responseString = [[NSString alloc] initWithData:_translateData encoding:NSUTF8StringEncoding];
//    NSMutableDictionary* responseDict = [NSDictionary dictionaryWithJSONString:responseString error:nil];
//    
//    // free json string result
//    [responseString release];
//    
//    // if we were able to create a valid dictionary from the json... then were in golden!!
//    if (responseDict != nil) {
//        
//        NSDictionary* dataDict = [responseDict objectForKey:@"data"];
//        if (dataDict != nil) {
//            
//            NSArray* translationArray = [dataDict objectForKey:@"translations"];
//            for (int i = 0; i < translationArray.count; ++i) {
//                
//                NSDictionary* translationDict = [translationArray objectAtIndex:i];
//                NSString* translatedText = [translationDict objectForKey:@"translatedText"];
//            
//                // if we have a callback set, then make that call now and delete
//                // the block after we have passed the result
//                if (_translateCallback != nil) {
//                    _translateCallback([userData objectForKey:@"sourceText"], translatedText, userData);
//                }
//            }
//        }
//        
//        // Alternate handling code...
//        //        NSDecimalNumber * responseStatus = [responseDict objectForKey:@"responseStatus"];
//        //        if ([responseStatus intValue] != 200) {
//        //            return;
//        //        }
//        //
//        //        NSMutableDictionary *responseDataDict = [responseDict objectForKey:@"responseData"];
//        //        if (responseDataDict != nil) {
//        //            NSString *translatedText = [responseDataDict objectForKey:@"translatedText"];
//        //
//        //            // make the callback
//        //            if (_translateCallback != nil) {
//        //                _translateCallback(translatedText);
//        //            }
//        //            [_translateCallback release];
//        //        }
//    }
//    
//    [_translateData release];
//    _translateData = nil;
//}

// Replaces any unnecessary sapces and other characters that have issues
-(NSString*)fixTranslatedString:(NSString*)source
{
    NSString* result = [source stringByReplacingOccurrencesOfString:@" ," withString:@","];
    result = [result stringByReplacingOccurrencesOfString:@" ." withString:@"."];
    result = [result stringByReplacingOccurrencesOfString:@". <" withString:@".<"];
    result = [result stringByReplacingOccurrencesOfString:@"> " withString:@">"];
    result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    result = [result stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    
    // fix all spacing issues in relation to the string "%d" appearing in the result
    int count = 0;
    NSMutableString* newStr = [NSMutableString stringWithCapacity:2048];
    NSArray* arr = [result componentsSeparatedByString:@"%d"];
    if (arr != nil && [arr count] > 1) {

        BOOL mayNeedAfterSpace = FALSE;
        
        // iterate over all components that were separated by "%d"
        for (NSString* str in arr) {
            
            // skip, no length here
            if (str.length == 0) {
                ++count;
                continue;
            }
            
            if (count == [arr count] - 1) {
                if (mayNeedAfterSpace && [str characterAtIndex:0] != ' ') {
                    [newStr appendString:@" "];
                    mayNeedAfterSpace = FALSE;
                }
                
                [newStr appendString:str];
                break;
            }
            
            // if are string does not begin with a space, then
            // manually enter one
            bool added = FALSE;
            if (count > 0 && [str characterAtIndex:0] != ' ') {
                [newStr appendString:@" "];
                added = TRUE;
            }
            
            // append the component string
            [newStr appendString:str];
            
            // if the newly appended string does not end in a space
            if ([str characterAtIndex:str.length - 1] != ' ') {
                if (added == FALSE) {
                    [newStr appendString:@" %d"];
                }
                else {
                    [newStr appendString:@"%d"];
                }
            }
            // otherwise append regular spaced
            else {
                [newStr appendString:@"%d"];
            }
            mayNeedAfterSpace = TRUE;
            
            // signifies that we are not on the first component
            count++;
        }
        
        // copy the result to a new string
        result = [newStr copy];
    }
    
    count = 0;
    NSMutableString* newStr2 = [NSMutableString stringWithCapacity:2048];
    arr = [result componentsSeparatedByString:@"%@"];
    if (arr == nil || [arr count] <= 1) {
        result = [result stringByReplacingOccurrencesOfString:@" ," withString:@","];
        return result;
    }
    
    BOOL mayNeedAfterSpace = FALSE;
    
    // iterate over all components that were separated by "%d"
    for (NSString* str in arr) {
        
        // skip, no length here
        if (str.length == 0) {
            ++count;
            continue;
        }
        
        if (count == [arr count] - 1) {
            if (mayNeedAfterSpace && [str characterAtIndex:0] != ' ') {
                [newStr2 appendString:@" "];
                mayNeedAfterSpace = FALSE;
            }
            
            [newStr appendString:str];
            break;
        }
        
        // if are string does not begin with a space, then
        // manually enter one
        bool added = FALSE;
        if (count > 0 && [str characterAtIndex:0] != ' ') {
            [newStr2 appendString:@" "];
            added = TRUE;
        }
        
        // append the component string
        [newStr2 appendString:str];
        
        // if the newly appended string does not end in a space
        if ([str characterAtIndex:str.length - 1] != ' ') {
            if (added == FALSE) {
                [newStr2 appendString:@" %@"];
            }
            else {
                [newStr2 appendString:@"%@"];
            }
        }
        // otherwise append regular spaced
        else {
            [newStr2 appendString:@"%@"];
        }
        mayNeedAfterSpace = TRUE;
        
        // signifies that we are not on the first component
        count++;
    }
    
    // copy the result to a new string
    result = [newStr2 copy];

    result = [result stringByReplacingOccurrencesOfString:@" ," withString:@","];
    
    return result;
}

// fix the spacing around certain substrings
-(NSString*)fixSpacesForSubstring:(NSString*)source forSubstring:(NSString*)substr
{
    // fix all spacing issues in relation to the string "%d" appearing in the result
    int count = 0;
    NSMutableString* newStr = [NSMutableString stringWithCapacity:2048];
    NSArray* arr = [source componentsSeparatedByString:@"%d"];
    if (arr == nil || [arr count] <= 1) {
        return source;
    }
    
    BOOL mayNeedAfterSpace = FALSE;
    
    // iterate over all components that were separated by "%d"
    for (NSString* str in arr) {
        
        // skip, no length here
        if (str.length == 0) {
            ++count;
            continue;
        }
        
        if (count == [arr count] - 1) {
            if (mayNeedAfterSpace && [str characterAtIndex:0] != ' ') {
                [newStr appendString:@" "];
                mayNeedAfterSpace = FALSE;
            }
            
            [newStr appendString:str];
            break;
        }
        
        // if are string does not begin with a space, then
        // manually enter one
        bool added = FALSE;
        if (count > 0 && [str characterAtIndex:0] != ' ') {
            [newStr appendString:@" "];
            added = TRUE;
        }
        
        // append the component string
        [newStr appendString:str];
        
        // if the newly appended string does not end in a space
        if ([str characterAtIndex:str.length - 1] != ' ') {
            if (added == FALSE) {
                [newStr appendString:[NSString stringWithFormat:@" %@", substr]];
            }
            else {
                [newStr appendString:substr];
            }
        }
        // otherwise append regular spaced
        else {
            [newStr appendString:substr];
        }
        mayNeedAfterSpace = TRUE;
        
        // signifies that we are not on the first component
        count++;
    }
    
    // return the new string
    return newStr;
}

// Hides/Shows an activity indicator to indicate something is happening
-(void)showSpinner:(BOOL)show onView:(UIView*)view
{
    if (show) {
        
        int xPos = [UIScreen mainScreen].bounds.size.width / 2;
        int yPos = [UIScreen mainScreen].bounds.size.height / 2 - 125;
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.center = CGPointMake(xPos, yPos);
        spinner.hidesWhenStopped = YES;
        
        [view addSubview:spinner];
        [spinner startAnimating];
    }
    else {
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        [spinner release];
        spinner = nil;
    }
}

@end
