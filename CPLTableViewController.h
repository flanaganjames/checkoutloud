//
//  CPLTableViewController.h
//  CoPilot
//
//  Created by James Flanagan on 3/8/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <OpenEars/PocketsphinxController.h>
#import <OpenEars/AcousticModel.h>
#import <OpenEars/OpenEarsEventsObserver.h>
#import <OpenEars/OpenEarsLogging.h>
#import <Slt/Slt.h>
#import <Kal/Kal.h>
#import <OpenEars/FliteController.h>
#import "CustomIOS7AlertView.h"

PocketsphinxController *pocketsphinxController;
OpenEarsEventsObserver *openEarsEventsObserver;
FliteController *fliteController;
Slt *slt;
Kal *kal;

@interface CPLTableViewController : UITableViewController <OpenEarsEventsObserverDelegate>
@property (weak, nonatomic) IBOutlet UIButton *readListButton;
- (IBAction)readListButton:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *listLabel;
- (IBAction)speechCommandToggle:(id)sender;

- (IBAction)backToParent:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backToParentButton;

@property BOOL suspendSpeechCommands;
@property BOOL saveStateSpeechCommand;
@property (weak, nonatomic) IBOutlet UIButton *speechCommandButton;

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *checklistDB;
@property NSString *listParent;
@property NSString *listGrandParent;
@property long listParentKey;
@property long listGrandParentKey;
@property (strong, nonatomic) PocketsphinxController *pocketsphinxController;
@property (strong, nonatomic) OpenEarsEventsObserver *openEarsEventsObserver;
@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@property (strong, nonatomic) Kal *kal;
- (IBAction) loadSpeechCommands;
- (IBAction) loadLanguageSet;
- (IBAction) changelanguageset;
@end
