//
//  NSStringExtension.m
//  PasswordVault
//
//  Created by David Leistiko on 9/19/14.
//
//

#import <CommonCrypto/CommonDigest.h>
#import "NSStringExtension.h"

@implementation NSString (Extension)

// Checks if the string is empty or null
+(BOOL)isEmptyOrNull:(NSString*)str
{
    return str == nil || str.length == 0;
}

// Checks if the string is only whitespace chars
+(BOOL)isWhiteSpace:(NSString*)str
{
    for (int i = 0; i < str.length; ++i) {
        NSString* charStr = [str substringWithRange:NSMakeRange(i, 1)];
        if (!([charStr isEqualToString:@""] ||
              [charStr isEqualToString:@" "] ||
              [charStr isEqualToString:@"\n"] ||
              [charStr isEqualToString:@"\t"] ||
              [charStr isEqualToString:@"\r"] ||
              [charStr isEqualToString:@"\v"] ||
              [charStr isEqualToString:@"\f"])) {
            return FALSE;
        }
    }
    
    // Success, all chars were whitepsace
    return TRUE;
}

// Converts html to regular text
+(NSString*)htmlToText:(NSString*)html
{
    NSScanner *theScanner;
    NSString *text = nil;
    theScanner = [NSScanner scannerWithString:html];
    
    while ([theScanner isAtEnd] == NO) {
        [theScanner scanUpToString:@"<" intoString:NULL] ;
        [theScanner scanUpToString:@">" intoString:&text] ;
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return html;
}

// Takes a stirng removes all whitespace
+(NSString*)removeAllWhitespace:(NSString*)str
{
    return [str stringByReplacingOccurrencesOfString:@"\\s"
                                          withString:@""
                                             options:NSRegularExpressionSearch range:NSMakeRange(0, [str length])];
}

// Calculate the md5 of a string
-(NSString*)md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

@end
