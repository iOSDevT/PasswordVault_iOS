//
//  TipManager.h
//  PasswordVault
//
//  Created by David Leistiko on 8/11/14.
//
//

#import "Enums.h"

struct Tip {
    NSString* _tipDetail;
    int _tipId;
    BOOL _hasBeenSeen;
    Language _language;
};

@interface TipManager : NSObject <NSXMLParserDelegate>
{
    NSMutableDictionary* _tipDictionary;
    NSString* _activeXmlElement;
    Language _activeXmlLanguage;
    int _shownCount;
    int _lastTipId;
    int _translationCount;
}

//// class properties
@property (nonatomic, readonly) NSMutableDictionary* tipDictionary;
@property (nonatomic, readonly) int shownCount;
@property (nonatomic, readonly) int lastTipId;
@property (nonatomic, readonly, getter=IsLoading) BOOL isLoading;

// class functions
+(TipManager*)sharedInstance;
+(NSString*)getFilename;
+(NSString*)getEscapedFilename;
-(NSString*)showRandomNextTip:(BOOL)onlyUnseen forLanguage:(Language)lang;
-(NSString*)showSpecificTip:(int)tipId forLanguage:(Language)lang;
-(void)reset:(Language)lang;
-(void)intializeTip:(struct Tip*)tip withDetail:(NSString*)detail andId:(int)tipId forLanguage:(Language)lang;
-(BOOL)save:(Language)lang;
-(BOOL)load:(Language)lang;
-(void)buildTips:(BOOL)initial;
-(int)getTipCount:(Language)lang;
-(BOOL)needsTranslation;
-(void)finishTranslations;

@end
