//
//  WebViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 1/6/12.
//  Copyright (c) 2012 David Leistiko. All rights reserved.
//
#import "Enums.h"

@interface WebViewController : UIViewController <UIWebViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
    IBOutlet UIWebView* _webView;
    IBOutlet UITextField* _webTextField;
    IBOutlet UIBarButtonItem* _backButton;
    IBOutlet UIBarButtonItem* _forwardButton;
    IBOutlet UIBarButtonItem* _refreshButton;
    IBOutlet UIBarButtonItem* _stopButton;
    IBOutlet UIBarButtonItem* _spacer;
    IBOutlet UIToolbar* _bottomToolBar;
    BOOL _internetConnectionFound;
    NSString* _address;
    BOOL _triedHttp;
    BOOL _triedHttps;
    UIActivityIndicatorView* _spinner;
    UILabel* _loadingLabel;
    UIImageView* _imageView;
    AlertType _currentAlertType;
}

@property (nonatomic, readonly) IBOutlet UIWebView* webView;

-(void)loadPage:(NSString*)address;
-(IBAction)textFieldPressDone:(id)sender;
-(IBAction)handleUsernameButton:(id)sender;
-(IBAction)handlePasswordButton:(id)sender;
-(IBAction)handleWebBackButton:(id)sender;
-(IBAction)handleWebForwardButton:(id)sender;
-(IBAction)handleWebRefreshButton:(id)sender;
-(IBAction)handleWebStopButton:(id)sender;
@end
