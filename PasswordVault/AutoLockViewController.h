//
//  AutoLockViewController.h
//  PasswordVault
//
//  Created by David Leistiko on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    kAutoLockType_None,
    kAutoLockType_Timed,
}AutoLockType;

typedef enum
{
    kAutoLockEvent_Load,
    kAutoLockEvent_Save,
}AutoLockEvent;

@interface AutoLockViewController : UIViewController
{
    IBOutlet UITextField* _autoLockTextField;
    IBOutlet UIButton* _backButton;
    IBOutlet UIButton* _forwardButton;
    int _autoLockTimeInSeconds;
    AutoLockType _autoLockType;
    unsigned long long _startTime;
    NSTimer* _repeatButtonTimer;
}

-(IBAction)handleBackButton;
-(IBAction)handleForwardButton;
-(IBAction)handleBackButtonRelease;
-(IBAction)handleForwardButtonRelease;
-(void)resetAutoLockTimeout;
-(void)cancelAutoLockTimeout;
-(void)evaluateAutoLockTimeout;
-(BOOL)isStarted;
-(void)updateAutoLockType:(AutoLockEvent)event;
@end
