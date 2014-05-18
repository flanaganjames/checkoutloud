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
@property (weak, nonatomic) IBOutlet UISwitch *speakSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *listenSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *skipCheckedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *resetCheckedNow;
@property (weak, nonatomic) IBOutlet UISwitch *enabledragSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *savecurrentorderSwitch;
@property BOOL skipCheckedItems;
@property BOOL resetNow;
@property BOOL saveNow;
@property BOOL allowSpeak;
@property BOOL allowListen;
@end