//
//  CustomTableViewCell.m
//  PasswordVault
//
//  Created by David Leistiko on 10/24/14.
//
//

#import "CustomTableViewCell.h"
#import "Utility.h"

@implementation CustomTableViewCell

// override function
-(void)willTransitionToState:(UITableViewCellStateMask)state {
    if (state & UITableViewCellStateShowingDeleteConfirmationMask) {
        [[Utility sharedInstance] playSound:kSoundType_ButtonClick];
    }
    [super willTransitionToState:state];
}

@end
