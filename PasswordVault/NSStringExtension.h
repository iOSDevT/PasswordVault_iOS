//
//  NSStringExtension.h
//  PasswordVault
//
//  Created by David Leistiko on 9/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Extension)
+(BOOL)isEmptyOrNull:(NSString*)str;
+(BOOL)isWhiteSpace:(NSString*)str;
+(NSString*)htmlToText:(NSString*)html;
+(NSString*)removeAllWhitespace:(NSString*)str;
-(NSString*)md5;

@end