//
//  Enums.h
//  PasswordVault
//
//  Created by David Leistiko on 1/24/14.
//
//

#ifndef PasswordVault_Enums_h
#define PasswordVault_Enums_h

typedef enum
{
    kAlertType_None,
    kAlertType_WebHasChanges,
    kAlertType_CancelHasChanges,
    kAlertType_BackHasChanges,
    kAlertType_ForwardHasChanges,
    kAlertType_AreYouSureAlert,
    kAlertType_ChangePassword,
    kAlertType_ChangePasswordFailure,
    kAlertType_ChangePasswordMismatch,
    kAlertType_ChangePasswordLengthMismatch,
    kAlertType_ChangePasswordMatch,
    kAlertType_EnterPassword,
    kAlertType_EnterNewPassword,
    kAlertType_Hint,
    kAlertType_ConfirmChanges,
    kAlertType_InvalidField,
    kAlertType_UnsubmittedChanges,
    kAlertType_DuplicateVault,
    kAlertType_DuplicateVaultError,
    kAlertType_DuplicateVaultOverwrite,
    kAlertType_DuplicateVaultInvalidName,
    kAlertType_DuplicateVaultSuccess,
    kAlertType_RenameVault,
    kAlertType_RenameVaultError,
    kAlertType_RenameVaultOverwrite,
    kAlertType_RenameVaultInvalidName,
    kAlertType_RenameVaultSuccess,
    kAlertType_OverwriteVault,
    kAlertType_Generic,
} AlertType;

typedef enum
{
    kPrimaryFontSize_Extra_Small,
    kPrimaryFontSize_Small,
    kPrimaryFontSize_Medium,
    kPrimaryFontSize_Large,
    kPrimaryFontSize_ExtraLarge,
    kPrimaryFontSize_COUNT

} PrimaryFontSize;

typedef enum
{
    kAutoCompleteType_Category,
    kAutoCompleteType_Title,
    kAutoCompleteType_Username,
} AutoCompleteType;

typedef enum
{
    kSoundType_ButtonClick,
} SoundType;

typedef enum
{
    kForceLoadType_None     = 0x0,
    kForceLoadType_Strings  = 0x1,
    kForceLoadType_Tips     = 0x2,
    kForceLoadType_All      = 0xFF,
} ForceLoadType;


// NOTE: how to add a new language
// 1) create new enum constant
// 2) update xmlStrings.xml to have an empty entry for the new language for each translated string... (ie. if adding french,
//    you will add <fr></fr> to each string entry
// 3) update xmlTips.xml to have an empty entry for the new language for each tip similar to what we did for strings
// 4) update xmlFontMetrics to have an entry for the new language for each supported font, in this case it is not an empty
//    entry but instead is a copy of an entry for any other langugae
// 5) add support for the new language in EnumHelper functions
// 6) update font choices for language in Utility.h
// 7) add NSNumber numberWithBool to the forceLanguages in Utility.m

typedef enum
{
    kLanguage_Invalid = -1,
    kLanguage_English,
    kLanguage_Spanish,
    kLanguage_Russian,
    kLanguage_German,
    kLanguage_French,
    kLanguage_Italian,
    kLanguage_Dutch,
    kLanguage_Greek,
    kLanguage_Irish,
    kLanguage_COUNT
} Language;

struct LanguageInfo
{
    Language _lang;
    NSString* _code;
    NSString* _displayName;
};

struct FontSizeInfo
{
    PrimaryFontSize _size;
};

// The enum helper class
@interface EnumHelper : NSObject
{
    
}
+(NSString*)getStringForFontSize:(PrimaryFontSize)size;
+(NSString*)getStringForLanguage:(Language) lang;
+(NSString*)getCountryCodeForLanguage:(Language)lang;
+(Language)getLanguageFromCountryCode:(NSString*)code;
+(NSArray*)getLanguageInfo;
+(NSArray*)getFontSizeInfo;

@end

#endif
