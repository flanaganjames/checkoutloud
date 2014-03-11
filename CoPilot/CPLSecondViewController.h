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

@interface CPLSecondViewController : UITableViewController <OpenEarsEventsObserverDelegate>
@property (weak, nonatomic) IBOutlet UILabel *listLabel;
- (IBAction)unwindToList:(id)sender;

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *checklistDB;
@property NSString *listParent;
@property NSString *listGrandParent;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;
@end
