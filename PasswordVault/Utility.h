//
//  Utility.h
//  PasswordVault
//
//  Created by David Leistiko on 10/15/13.
//
//

#import "Enums.h"
#import "PasswordVaultItem.h"
#import "PasswordVaultItemList.h"

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

struct Animation
{
    int animId;
    UIView* control;
    CGRect startFrame;
    CGRect endFrame;
    float time;
};

struct SearchResult
{
    PasswordVaultItemList* _list;
    PasswordVaultItem* _item;
};

typedef void (^TranslateTextCallback)(NSString*, NSString*, NSMutableDictionary* userData);

struct TranslateTextInfo
{
    NSString* _source;
    Language _sourceLang;
    Language _targetLang;
    TranslateTextCallback _callback;
    NSMutableDictionary* _userData;
};

// storehouse for general/common pieces of code that
// are used throughout the codebase
@interface Utility : NSObject <AVAudioPlayerDelegate, NSXMLParserDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSMutableDictionary* _animations;
    UIFont* _primaryFont;
    UIFont* _tipFont;
    NSString* _defaultPrimaryFontName;
    NSString* _primaryFontName;
    float _primaryFontSize;
    NSString* _defaultTipFontName;
    NSString* _tipFontName;
    float _tipFontSize;
    float _textfieldTextWidth;
    float _textviewTextWidth;
    float _buttonTextWidth;
    float _buttonLabelTextWidth;
    float _headerTextWidth;
    float _headerSmallTextWidth;
    float _tableviewHeaderFooterTextWidth;
    float _tableviewCellTextWidth;
    float _largeLabelTextWidth;
    float _smallLabelTextWidth;
    float _searchbarTextWidth;
    NSMutableDictionary* _languageAndFontMetrics;
    Language _activeXmlLanguage;
    NSString* _activeXmlFontName;
    NSString* _activeXmlSizeName;
    float _activeXmlSizeValue;
    NSMutableArray* _translationQueue;
    UIActivityIndicatorView *spinner;
    ForceLoadType _forceLoadType;
    NSMutableArray* _forceLangauges;
}

@property (nonatomic, readonly) NSInteger maxTitleWidth;
@property (nonatomic, readonly) UIFont* primaryFont;
@property (nonatomic, readonly) NSString* primaryFontName;
@property (nonatomic, readonly) float primaryFontSize;
@property (nonatomic, readonly) UIFont* tipFont;
@property (nonatomic, readonly) NSString* tipFontName;
@property (nonatomic, readonly) float tipFontSize;
@property (nonatomic, readonly, getter=getDefaultPrimaryFontSize) float defaultPrimaryFontSize;
@property (nonatomic, readonly, getter=getDefaultTipFontSize) float defaultTipFontSize;
@property (nonatomic, readonly, getter=getHeaderFontSize) float headerFontSize;
@property (nonatomic, readonly, getter=getButtonFontSize) float buttonFontSize;
@property (nonatomic, readonly, getter=getTextfieldFontSize) float textfieldFontSize;
@property (nonatomic, readonly, getter=getTextviewFontSize) float textviewFontSize;
@property (nonatomic, readonly, getter=getTableviewHeaderFooterFontSize) float tableviewHeaderFooterFontSize;
@property (nonatomic, readonly, getter=getTableviewCellFontSize) float tableviewCellFontSize;
@property (nonatomic, readonly, getter=getLargeLabelFontSize) float largeLabelFontSize;
@property (nonatomic, readonly, getter=getSmallLabelFontSize) float smallLabelFontSize;
@property (nonatomic, readonly, getter=getSearchbarFontSize) float searchbarFontSize;
@property (nonatomic, readonly, getter=getLargeTitleFontSize) float largeTitleFontSize;
@property (nonatomic, readonly, getter=getSmallTitleFontSize) float smallTitleFontSize;
@property (nonatomic, readonly) float textfieldTextWidth;
@property (nonatomic, readonly) float textviewTextWidth;
@property (nonatomic, readonly) float buttonTextWidth;
@property (nonatomic, readonly) float buttonLabelTextWidth;
@property (nonatomic, readonly) float headerTextWidth;
@property (nonatomic, readonly) float headerSmallTextWidth;
@property (nonatomic, readonly) float tableviewHeaderFooterTextWidth;
@property (nonatomic, readonly) float tableviewCellTextWidth;
@property (nonatomic, readonly) float largeLabelTextWidth;
@property (nonatomic, readonly) float smallLabelTextWidth;
@property (nonatomic, readonly) float searchbarTextWidth;
@property (nonatomic, readonly) float largeTitleTextWidth;
@property (nonatomic, readonly) float smallTitleTextWidth;
@property (nonatomic, readonly) ForceLoadType forceLoadType;
@property (nonatomic, readonly) NSArray* forceLanguages;

// class functions
+(Utility*)sharedInstance;
+(NSString*)getFontMetricFilename;
+(NSString*)getFontMetricXmlFilename;
-(unsigned long long)getCurrentTime;
-(UIImage*)addImageAlpha:(UIImage*)image withAlpha:(CGFloat)alpha;
-(UIImage*)resizeImage:(UIImage*)image withSize:(CGSize)size;
-(void)animateControl:(UIView*)control withStart:(CGRect)start withEnd:(CGRect)end withTime:(float)time andDelay:(float)delay;
-(int)getPendingAnimationCount;
-(CGSize)measureString:(NSString*)str withFont:(UIFont*)font;
-(NSString*)convertStringForEncoding:(NSString*)source;

-(NSString*)converTotHex:(NSString*)source;
-(NSString*)convertFromHex:(NSString*)source;

-(void)adjustTitleView:(UIViewController*)controller
         withStringKey:(NSString*)text
          withMaxWidth:(float)maxWidth
       andIsLargeTitle:(BOOL)large
          andAlignment:(NSTextAlignment)alignment;
-(BOOL)adjustActionSheetButtonColor:(UIActionSheet*)actionSheet withButtonTitle:(NSString*)title andColor:(UIColor*)color;
-(void)changePrimaryFont:(NSString*)fontName withSize:(float)size;
-(void)changeTipFont:(NSString*)fontName withSize:(float)size;
-(float)determineAndSetFontForTextfield:(UITextField*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForTextview:(UITextView*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForButton:(UIButton*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForButtonLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForTableviewHeaderFooter:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForTableviewCell:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForLargeLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForSmallLabel:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForSearchbar:(UISearchBar*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForLargeTitle:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(float)determineAndSetFontForSmallTitle:(UILabel*)view withText:(NSString*)text andMaxWidth:(float)width andIsTip:(BOOL)tip;
-(BOOL)doesFontContainCharacter:(UIFont*)font withChar:(unichar)character;
-(BOOL)doesFontSupportLanguage:(UIFont*)font withLanguague:(Language)lang;
-(NSArray*)findAlternateFontsThatSupportLanguage:(Language)lang withFontSize:(float)size;
-(BOOL)addFontMetric:(NSString*)fontName withSizeDict:(NSMutableDictionary*)dict;
-(BOOL)doesFontMetricExist:(NSString*)fontName withLanguage:(Language)lang;
-(NSDictionary*)getDefaultFontMetrics;
-(NSDictionary*)getFontMetricFor:(NSString*)font forLanguage:(Language)lang;
-(NSArray*)getDefaultSupportiveFontsFor:(Language)lang andForTips:(BOOL)tips;
-(void)clearUserDefaults;
-(BOOL)playSound:(SoundType)sound;
-(void)translateQueuedInfos;
-(BOOL)translateQueuedInfo;
-(void)translateText:(NSString*)source withSourceLanguage:(Language)sourceLang andTargetLanguage:(Language)targetLang andCallback:(void(^)(NSString*,NSString*, NSMutableDictionary* userData))callback withUserData:(NSMutableDictionary*)dict;
-(NSString*)fixTranslatedString:(NSString*)source;
-(void)showSpinner:(BOOL)show onView:(UIView*)view;
-(BOOL)checkForceLanguageValidity:(Language)lang;

@end