//
//  CPLSlideShowViewController.h
//  CheckOutLoud
//
//  Created by James Flanagan on 4/27/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListItem.h"
#import <OpenEars/OpenEarsEventsObserver.h>
#import <OpenEars/FliteController.h>
#import <Slt/Slt.h>

@interface CPLSlideShowViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *listName;

@property (weak, nonatomic) IBOutlet UITextField *listItemNumber;
@property (weak, nonatomic) IBOutlet UITextField *listItemName;
@property (weak, nonatomic) IBOutlet UIView *clickView;
@property NSString *listParent;
@property CheckListItem *currentCheckListItem;
@property NSMutableArray *checkListItems;
@property long currentrow;
@property FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@end
