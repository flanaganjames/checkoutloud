//
//  CPLMUDViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListItem.h"

@interface CPLMUDViewController : UIViewController
@property CheckListItem *checkListItem;
@property (weak, nonatomic) IBOutlet UITextField *itemName;

@property (weak, nonatomic) IBOutlet UITextField *itemPriority;
@property (weak, nonatomic) IBOutlet UISwitch *deleteSwitch;
@property BOOL *setDelete;
@end
