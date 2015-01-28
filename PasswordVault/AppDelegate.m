//
//  AppDelegate.m
//  PasswordVault
//
//  Created by David Leistiko on 11/28/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "PasswordVault.h"
#import "Strings.h"
#import "TipManager.h"

@implementation AppDelegate

@synthesize window = _window;

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
        
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 5.0)
        self.window.RootViewController = [self navigationController];
    else
        [self.window addSubview:[self navigationController].view];
    
    [self navigationController].navigationItem.title = @"Password Vault";
    
    [[[self mainViewController] AutoLockViewController] updateAutoLockType:kAutoLockEvent_Load];
    
    return YES;
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    // save the vault
    [[PasswordVault sharedInstance] saveVault];
    
    //[[self navigationController] popToRootViewControllerAnimated:NO];
    
    // clear the clipboard
    //UIPasteboard* pastebaord = [UIPasteboard generalPasteboard];
    //pastebaord.string = @"";
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    // save the vault
    [[PasswordVault sharedInstance] saveVault];
    
    //[[self navigationController] popToRootViewControllerAnimated:NO];
    
    // clear the clipboard
    //UIPasteboard* pastebaord = [UIPasteboard generalPasteboard];
    //pastebaord.string = @"";
    
    // if we have not started our autolock timeout do so now
    if ([[[self mainViewController] AutoLockViewController] isStarted] == false)
    {
        [[[self mainViewController] AutoLockViewController] resetAutoLockTimeout];
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [[Strings sharedInstance] setCurrentLanguageFromSettings];
    
    if ([self mainViewController] != nil && [[self mainViewController] AutoLockViewController] != nil)
    {
        [[[self mainViewController] AutoLockViewController] evaluateAutoLockTimeout];
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    // save the vault
    [[PasswordVault sharedInstance] saveVault];
    
    // clear the clipboard
    UIPasteboard* pastebaord = [UIPasteboard generalPasteboard];
    pastebaord.string = @"";
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
}

// Returns the primary nav controller for use
-(UINavigationController*)navigationController
{
    return (UINavigationController*)self.window.rootViewController;
}

// Returns the primary view controller within the navigation controller
-(MainViewController*)mainViewController
{
    return (MainViewController*)[[self navigationController].viewControllers objectAtIndex:0];
}

@end
