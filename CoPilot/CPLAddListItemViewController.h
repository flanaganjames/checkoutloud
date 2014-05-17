//
//  CPLAddListItemViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/13/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenEars/OpenEarsEventsObserver.h>
#import "CheckListItem.h"
#import "CPLTableViewController.h"

@interface CPLAddListItemViewController : UIViewController
@property CheckListItem *checkListItem;

@property (weak, nonatomic) IBOutlet UITextField *itemName;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (weak, nonatomic) IBOutlet UITextField *itemPriority;
@property NSString *listParent;
@property NSInteger defaultPriority;
-(IBAction)textFieldReturn:(id)sender;
@end
