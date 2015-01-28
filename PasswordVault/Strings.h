//
//  Strings.h
//  PasswordVault
//
//  Created by David Leistiko on 9/15/14.
//
//

#import "Enums.h"

@interface Strings : NSObject <NSXMLParserDelegate>
{
    Language _currentLanguage;
    NSMutableDictionary* _stringDict;
    NSString* _activeXmlElement;
    Language _activeXmlLanguage;
    int _translationCount;
}
@property (nonatomic, readonly) Language CurrentLanguage;
@property (nonatomic, readonly, getter=IsLoading) BOOL isLoading;

+(Strings*)sharedInstance;
+(NSString*)getFilename;
+(NSString*)getEscapedFilename;
-(NSString*)lookupString:(NSString*)key;
-(NSString*)lookupString:(NSString*)key withLanguage:(Language)lang;
-(void)changeCurrentLanguage:(Language)lang;
-(void)setCurrentLanguageFromSettings;
-(void)buildStrings:(BOOL)initial;
-(NSString*)setString:(NSString*)key withValue:(NSString*)value andLanguage:(Language)lang;
-(BOOL)needsTranslation;
-(void)finishTranslations;
@end
