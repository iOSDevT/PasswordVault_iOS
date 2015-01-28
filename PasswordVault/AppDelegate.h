//
//  AppDelegate.h
//  PasswordVault
//
//  Created by David Leistiko on 11/28/11.
//  Copyright (c) 2011 David Leistiko. All rights reserved.
//

#import <UIKit/UIKit.h>

// forward declaration...
@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

// Properties...
@property (strong, nonatomic) IBOutlet UIWindow *window;

// Functions...
-(UINavigationController*)navigationController;
-(MainViewController*)mainViewController;

@end
