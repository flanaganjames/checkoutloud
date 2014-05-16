//
//  CPLPreferencesViewController.h
//  CheckOutLoud
//
//  Created by James Flanagan on 5/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPLTableViewController.h"

@interface CPLPreferencesViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *speekSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *listenSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *skipCheckedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *resetCheckedNow;
@property BOOL skipCheckedItems;
@property BOOL resetNow;
@end
