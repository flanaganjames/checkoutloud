//
//  CPLMUDViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListItem.h"
#import "CPLTimeDelayItem.h"

@interface CPLMUDViewController : UIViewController
@property CheckListItem *checkListItem;
@property CPLTimeDelayItem *timeDelayItem;
@property (weak, nonatomic) IBOutlet UITextField *itemName;

@property (weak, nonatomic) IBOutlet UITextField *delaySeconds;
@property (weak, nonatomic) IBOutlet UITextField *delayMinutes;
@property (weak, nonatomic) IBOutlet UITextField *delayHours;
@property (weak, nonatomic) IBOutlet UITextField *repeatTimes;

@property (weak, nonatomic) IBOutlet UITextField *itemPriority;
@property (weak, nonatomic) IBOutlet UISwitch *deleteSwitch;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property BOOL *setDelete;
-(IBAction)textFieldReturn:(id)sender;
@end
