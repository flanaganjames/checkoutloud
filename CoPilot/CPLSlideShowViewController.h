//
//  CPLSlideShowViewController.h
//  CheckOutLoud
//
//  Created by James Flanagan on 4/27/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckListItem.h"
#import "CPLTimeDelayItem.h"
#import <OpenEars/OpenEarsEventsObserver.h>
#import <OpenEars/FliteController.h>
#import <Slt/Slt.h>
#import <OpenEars/OpenEarsLogging.h>
#import <OpenEars/PocketsphinxController.h>
#import "CPLTableViewController.h"

@interface CPLSlideShowViewController : UIViewController  <OpenEarsEventsObserverDelegate>
- (IBAction)quitChecking:(id)sender;
@property BOOL allowSpeak;
@property BOOL allowListen;
@property (weak, nonatomic) IBOutlet UITextView *warningText;

@property (weak, nonatomic) IBOutlet UITextView *listParentHierarchy;

@property (weak, nonatomic) IBOutlet UITextField *listItemNumber;
@property (weak, nonatomic) IBOutlet UITextField *listItemName;
@property (weak, nonatomic) IBOutlet UIView *clickView;
@property BOOL checkedItemsHaveBeenSkipped;
@property NSMutableArray *checkedItemKeys;
@property NSString *listParent;
@property CheckListItem *currentCheckListItem;
@property NSMutableArray *checkListItems;
@property NSMutableArray *listOfLists;
@property NSMutableArray *listOfListNames;
@property NSMutableArray *unscheduledTDItems;
@property NSMutableArray *tobescheduledTDItems;
@property long currentrow;
@property long currentlist;
@property FliteController *fliteController;
@property (strong, nonatomic) PocketsphinxController *pocketsphinxController;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;
@property (strong, nonatomic) Slt *slt;
@property (strong, nonatomic) CPLTableViewController *sendingController;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *upSwipeGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;
@end
