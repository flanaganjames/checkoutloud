//
//  CPLSecondViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/10/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <OpenEars/PocketsphinxController.h>
#import <OpenEars/AcousticModel.h>
#import <OpenEars/OpenEarsEventsObserver.h>
#import <OpenEars/OpenEarsLogging.h>
#import "CPLTableViewController.h"
#import <Slt/Slt.h> 
#import <Kal/Kal.h>
#import <OpenEars/FliteController.h>

FliteController *fliteController;
Slt *slt;
Kal *kal;

@interface CPLSecondViewController : UITableViewController <OpenEarsEventsObserverDelegate>
- (IBAction)readList:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *listLabel;
- (IBAction)checkItem:(id)sender;

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *checklistDB;
@property NSString *listParent;
@property NSString *listGrandParent;
@property long currentrow;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;
@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@property (strong, nonatomic) Kal *kal;
@property (strong, nonatomic) CPLTableViewController *originView;
@property BOOL suspendSpeechCommands;
@property BOOL saveStateSpeechCommand;
@property CPLTableViewController *mainView;
@end
