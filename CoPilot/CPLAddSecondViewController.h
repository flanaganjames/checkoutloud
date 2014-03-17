//
//  CPLAddSecondViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/13/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenEars/OpenEarsEventsObserver.h>
#import "CheckListItem.h"
#import "CPLTableViewController.h"

@interface CPLAddSecondViewController : UIViewController <OpenEarsEventsObserverDelegate>
@property (weak, nonatomic) IBOutlet UITextField *itemName;
@property (weak, nonatomic) IBOutlet UITextField *itemPriority;


@property CheckListItem *checkListItem;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;
@property NSString *listParent;
@end
