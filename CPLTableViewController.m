//
//  CPLTableViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/8/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLTableViewController.h"
#import "CheckListItem.h"
#import <OpenEars/LanguageModelGenerator.h>
//#import "CPLSecondViewController.h"
#import "CPLAddListItemViewController.h"
#import "CPLMUDViewController.h"


@interface CPLTableViewController ()
 @property NSMutableArray *checkListItems;
@property NSMutableArray *speechCommands;
@property CheckListItem *updatingItem;
// @property UITableView *tableView;   // for loadView which cases failure

@property  NSString *lmPath;
@property NSString *dicPath;
@property long currentrow;
@end

@implementation CPLTableViewController

@synthesize pocketsphinxController;

@synthesize openEarsEventsObserver;

@synthesize fliteController;

@synthesize slt;
@synthesize kal;


- (FliteController *)fliteController { if (fliteController == nil) { fliteController = [[FliteController alloc] init]; } return fliteController; } - (Slt *)slt { if (slt == nil) { slt = [[Slt alloc] init]; } return slt; }
//- (FliteController *)fliteController { if (fliteController == nil) { fliteController = [[FliteController alloc] init]; } return fliteController; } - (Kal *)kal { if (kal == nil) { kal = [[Kal alloc] init]; } return kal; }

- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return openEarsEventsObserver;
}


- (PocketsphinxController *)pocketsphinxController {
	if (pocketsphinxController == nil) {
		pocketsphinxController = [[PocketsphinxController alloc] init];
	}
	return pocketsphinxController;
}


- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);

if (self.suspendSpeechCommands == NO)
{
    NSArray *cells = [self.tableView visibleCells]; //how to get array of all rows?
    NSArray *visible = [self.tableView indexPathsForVisibleRows];
    
    [cells enumerateObjectsUsingBlock:^(UITableViewCell *cell,
                                        NSUInteger idx,
                                        BOOL *stop)
     {
         if ([hypothesis  isEqual: cell.textLabel.text])
         {

             NSIndexPath* index = visible[idx];
             
             [self.tableView selectRowAtIndexPath:index animated:NO scrollPosition:            UITableViewScrollPositionMiddle];
             
            [self respondSelectRow];
             
//             [self performSegueWithIdentifier: @"showDetailList" sender: self];
         }
     }];
    
    if ([hypothesis  isEqual: @"READ LIST"])
    {
        self.currentrow = 0;
        [self readCurrent];
    }
    
    if ([hypothesis  isEqual: @"CHECK"])
    {
        if (self.currentrow < [self.checkListItems count] - 1)
        {// set checkmark on currentrow
            // then increment currentrow pointer
            // then read new current
            
            self.currentrow += 1;
            [self readCurrent];
        }
    }
    
    if ([hypothesis  isEqual: @"NEXT"])
    {
        if (self.currentrow < [self.checkListItems count] - 1)
        {// set checkmark on currentrow
            // then increment currentrow pointer
            // then read new current
            
            self.currentrow += 1;
            [self readCurrent];
        }
    }
    
    if ([hypothesis  isEqual: @"OK"])
    {
        if (self.currentrow < [self.checkListItems count] - 1)
        {// set checkmark on currentrow
            // then increment currentrow pointer
            // then read new current
            
            self.currentrow += 1;
            [self readCurrent];
        }
    }
    
    if ([hypothesis  isEqual: @"RETURN"])
    {
        if (![self.listParent isEqual: @"ROOT"]) //
        {
            self.listParent = self.listGrandParent;
            [self getGrandParent];
            self.listLabel.text = self.listParent;
            [self loadInitialData];
            [self.tableView reloadData];
            [self loadSpeechCommands];
            [self loadLanguageSet];
            [self changelanguageset]; //changes to the recreated language model
        }
    }
    

}
}

- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started.");
}

- (void) pocketsphinxDidCompleteCalibration {
	NSLog(@"Pocketsphinx calibration is complete.");
}

- (void) pocketsphinxDidStartListening {
	NSLog(@"Pocketsphinx is now listening.");
}

- (void) pocketsphinxDidDetectSpeech {
	NSLog(@"Pocketsphinx has detected speech.");
}

- (void) pocketsphinxDidDetectFinishedSpeech {
	NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening.");
}

- (void) pocketsphinxDidSuspendRecognition {
	NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
	NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFail { // This can let you know that something went wrong with the recognition loop startup. Turn on OPENEARSLOGGING to learn why.
	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on OpenEarsLogging to learn more.");
}
- (void) testRecognitionCompleted {
	NSLog(@"A test file that was submitted for recognition is now complete.");
}

- (void) readCurrent {
    //read current row of checkListItems
    CheckListItem *item = self.checkListItems[self.currentrow];
    
    NSString *text = item.itemName;
    
    [self.fliteController say: text withVoice:self.slt];
    //    [self.fliteController say: text withVoice:self.kal];
}

- (void)loadInitialData {

    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTS WHERE PARENT=\'%@\'", self.listParent];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
        [self.checkListItems removeAllObjects]; // remove the current list of checklistitems
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSString *taskname =
            [[NSString alloc] initWithUTF8String:
             (const char *) sqlite3_column_text(statement, 1)];
            int taskpriority = sqlite3_column_int(statement, 2);
            NSString *taskparent =
            [[NSString alloc] initWithUTF8String:
             (const char *) sqlite3_column_text(statement, 3)];
            long taskkey = sqlite3_column_int(statement, 0);
            CheckListItem *item = [[CheckListItem alloc] init];
            item.itemName = taskname;
            item.itemKey = *(&(taskkey));
            item.itemPriority = *(&(taskpriority));
            item.itemParent = taskparent;
            [self.checkListItems addObject:item];
            
        }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }

    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
    
    [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
}

//creates array of NSStrings to be recognized as speech commands, all uppercase
- (void)loadSpeechCommands {
    
    [self.speechCommands removeAllObjects];
// default commands
    [self.speechCommands addObject:@"RETURN"];
    [self.speechCommands addObject:@"READ LIST"];
    [self.speechCommands addObject:@"CHECK"];
    [self.speechCommands addObject:@"OK"];
    [self.speechCommands addObject:@"ADD"];
    [self.speechCommands addObject:@"UPDATE"];
    [self.speechCommands addObject:@"SAVE"];
    [self.speechCommands addObject:@"NEXT"];

//commands for items in all checklists
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTS"];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {  while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSString *taskname =
            [[NSString alloc] initWithUTF8String:
             (const char *) sqlite3_column_text(statement, 1)];
            NSString *upperCaseTaskName = [taskname uppercaseString];
            [self.speechCommands addObject:upperCaseTaskName];
        }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }
    
//    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Loading speechCommand"
//                                                      message:[NSString stringWithFormat: @"%d", self.speechCommands.count]
//                                                     delegate:nil
//                                            cancelButtonTitle:@"OK"
//                                            otherButtonTitles:nil];
//    
//    [message show];
}

- (void)reloadArrayData {
    
    for (CheckListItem *item in self.checkListItems) {
        [self.checkListItems removeObject:item];
    }
    
    [self.tableView reloadData];
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTS WHERE PARENT=\'%@\'", self.listParent];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {  while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSString *taskname =
            [[NSString alloc] initWithUTF8String:
             (const char *) sqlite3_column_text(statement, 1)];
            int taskpriority = sqlite3_column_int(statement, 2);
            NSString *taskparent =
            [[NSString alloc] initWithUTF8String:
             (const char *) sqlite3_column_text(statement, 3)];
            long taskkey = sqlite3_column_int(statement, 0);
            CheckListItem *item = [[CheckListItem alloc] init];
            item.itemName = taskname;
            item.itemKey = *(&(taskkey));
            item.itemPriority = *(&(taskpriority));
            item.itemParent = taskparent;
            [self.checkListItems addObject:item];
            
        }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }
    
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
    
    [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
    [self.tableView reloadData];
    
}

- (void) respondSelectRow {
    NSIndexPath *myIndexPath = [self.tableView
                                indexPathForSelectedRow];
    long row = [myIndexPath row];
    CheckListItem *item  = self.checkListItems[row];
    
    self.listGrandParent = self.listParent;
    self.listParent = item.itemName;
    self.listLabel.text = self.listParent;
    [self loadInitialData];
    [self.tableView reloadData];
    [self loadSpeechCommands];
    [self loadLanguageSet];
    [self changelanguageset]; //changes to the recreated language model
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//  self.listenerStatus.text = @"selected";
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self respondSelectRow];
    
//    [self reloadArrayData];
//    [self.tableView reloadData];
//
}



//- (void)loadView
//{
//    self.tableView = [[UITableView alloc]
//                 initWithFrame:  [[UIScreen mainScreen] applicationFrame]
//                 style:          UITableViewStylePlain
//                 ];
//    
//    self.tableView.autoresizingMask =
//    UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    
//    self.tableView.delegate = self;
//    self.tableView.dataSource = self;
//    [self.tableView reloadData];
//    self.view = self.tableView;
////    [self.tableView release];
//}



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadLanguageSet
{
    LanguageModelGenerator *lmGenerator = [[LanguageModelGenerator alloc] init];
    
    NSArray *words = self.speechCommands;
    
    NSString *name = @"CheckListWords";
    NSError *err = [lmGenerator generateLanguageModelFromArray:words withFilesNamed:name forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to create a Spanish language model instead of an English one.
    
    NSDictionary *languageGeneratorResults = nil;
    

	
    if([err code] == noErr) {
        
        languageGeneratorResults = [err userInfo];
		
        self.lmPath = [languageGeneratorResults objectForKey:@"LMPath"];
        self.dicPath = [languageGeneratorResults objectForKey:@"DictionaryPath"];
		
    } else {
        NSLog(@"Error: %@",[err localizedDescription]);
    }
    
}

- (void) startlanguageset
{
    
    [self.pocketsphinxController startListeningWithLanguageModelAtPath:self.lmPath dictionaryAtPath:self.dicPath acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to perform Spanish recognition instead of English.
}

- (void) changelanguageset
{
[self.pocketsphinxController changeLanguageModelToFile:self.lmPath withDictionary:self.dicPath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.suspendSpeechCommands = NO;

    self.checkListItems = [[NSMutableArray alloc] init];
    self.speechCommands = [[NSMutableArray alloc] init];
    
    NSString *docsDir;
    
    NSArray *dirPaths;
    
    self.listParent = @"ROOT";
    self.listGrandParent = @"ROOT";
    self.listLabel.text = self.listParent;

    
    // Get the documents directory
    
    dirPaths = NSSearchPathForDirectoriesInDomains(
                    NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    
    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"checklist.db"]];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS CHECKLISTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME, PRIORITY, PARENT)";
            if (sqlite3_exec(_checklistDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                //_status.text = @"Failed to create table";
            }
            sqlite3_close(_checklistDB);
        }
        else
        {
            //    _status.text = @"Failed to open/create database";
        }
    }
    
    [self loadInitialData];
    [self loadSpeechCommands];
    [self loadLanguageSet];
    [self startlanguageset];
    
    //start openears stuff
    
    
    [OpenEarsLogging startOpenEarsLogging];
    
    [self.openEarsEventsObserver setDelegate:self];
    
    
    [self.fliteController say:@"Hi Boss" withVoice:self.slt];
//    [self.fliteController say:@"Hey Boss.  Another day, another dollar." withVoice:self.kal];
    
// remember to add <OpenEarsEventsObserverDelegate> to the interface definition line in the .h file
    

    
//    self.listenerStatus.text = @"Listening";
    
//end of openears stuff
// Uncomment the following line to preserve selection between presentations.
// self.clearsSelectionOnViewWillAppear = NO;

// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewDidAppear:(BOOL)animated
{
    [self.openEarsEventsObserver setDelegate:self];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.checkListItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CheckListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    // Configure the cell...
    
    CheckListItem *checkItem = [self.checkListItems objectAtIndex:indexPath.row];
	
	cell.textLabel.text = checkItem.itemName;
    
    return cell;
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"AddToRoot"])
    {
        self.saveStateSpeechCommand = self.suspendSpeechCommands;
        self.suspendSpeechCommands = YES;
        CPLAddListItemViewController *addViewController =
        [segue destinationViewController];
        
        addViewController.listParent = self.listParent;
        addViewController.openEarsEventsObserver = self.openEarsEventsObserver;

    }
    
    if ([[segue identifier] isEqualToString:@"UpdateMainList"])
    {
        self.saveStateSpeechCommand = self.suspendSpeechCommands;
        self.suspendSpeechCommands = YES;
        CPLMUDViewController *updateViewController =
        [segue destinationViewController];
        
//        NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
//        long row = [myIndexPath row];
        
        long row = [self.tableView indexPathForCell:sender].row;
        
//        CheckListItem *item = self.checkListItems[row];
        self.updatingItem = self.checkListItems[row];

        updateViewController.checkListItem = self.updatingItem;
        
    }

}



- (IBAction)unwindAddToList:(UIStoryboardSegue *)segue  sender:(id)sender
{
    self.suspendSpeechCommands = self.saveStateSpeechCommand;
    CPLAddListItemViewController *source = [segue sourceViewController];
    CheckListItem *item = source.checkListItem;
    if (item != nil)
    {
        [self.checkListItems addObject:item];
        // want to sort this list by itemPriority
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
    [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    [self.tableView reloadData];
        // save the task in the database
        sqlite3_stmt    *statement;
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *insertSQL = [NSString stringWithFormat:
                                   @"INSERT INTO CHECKLISTS (name, priority, parent, haschild) VALUES (\'%@\', %ld,\'%@\',\'%@\')",
                                   item.itemName, item.itemPriority, self.listParent, @"NO"];
            const char *insert_stmt = [insertSQL UTF8String];
            //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SQL in Unwind"
            //    message:  [NSString stringWithFormat: @"%s", insert_stmt ]
            //    delegate:self
            //    cancelButtonTitle:@"OK"
            //    otherButtonTitles:nil];
            //    [alert show];
            sqlite3_prepare_v2(_checklistDB, insert_stmt,
                               -1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
            }
            else
            {
            }
            sqlite3_finalize(statement);
            sqlite3_close(_checklistDB);
        }
    [self loadSpeechCommands];  //reloads database as speechcommands
    [self loadLanguageSet]; // recreates language model from speechcommands
    [self changelanguageset]; //changes to the recreated language model
    }
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue  sender:(id)sender
{
[self.tableView reloadData];

}

- (IBAction)unwindUpdateMainList:(UIStoryboardSegue *)segue  sender:(id)sender
{
    self.suspendSpeechCommands = self.saveStateSpeechCommand;
    CPLMUDViewController *source = [segue sourceViewController];
    CheckListItem *item = source.checkListItem;
    
    if (source.setDelete)
    {// delete task from database
        [self.checkListItems removeObject:item];
        
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
        [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        [self.tableView reloadData];
        
        sqlite3_stmt    *statement;
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat:
                                   @"DELETE FROM CHECKLISTS WHERE ID=%ld",item.itemKey];
            const char *update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(_checklistDB, update_stmt,
                               -1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
            }
            else
            {
            }
            sqlite3_finalize(statement);
            sqlite3_close(_checklistDB);
        } // SQLITE_OK
        
    } //close if delete
    else
    {
        [self.checkListItems removeObject:self.updatingItem];
        [self.checkListItems addObject:item];
        
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
        [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        [self.tableView reloadData];
        
        
        // update the task in the database
        sqlite3_stmt    *statement;
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat:
                                   @"UPDATE CHECKLISTS SET PRIORITY=%ld WHERE ID=%ld",
                                   item.itemPriority, item.itemKey];
            const char *update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(_checklistDB, update_stmt,
                               -1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
            }
            else
            {
            }
            sqlite3_finalize(statement);
            sqlite3_close(_checklistDB);
        } // SQLITE_OK
        
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat:
                                   @"UPDATE CHECKLISTS SET NAME=\"%@\" WHERE ID=%ld",
                                   item.itemName, item.itemKey];
            
            const char *update_stmt = [updateSQL UTF8String];
            sqlite3_prepare_v2(_checklistDB, update_stmt,
                               -1, &statement, NULL);
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
            }
            else
            {
            }
            sqlite3_finalize(statement);
            sqlite3_close(_checklistDB);
        } // SQLITE_OK
        
    } // close else update
    
//    [self reloadArrayData];
    // this crashes with message "NSArray mutated while enumerated"
}

- (IBAction)speechCommandToggle:(id)sender
{
    
    if ([self.speechCommandButton.currentTitle  isEqual: @"Suspend Speech Commands"])
        {  self.suspendSpeechCommands = YES;
            [self.speechCommandButton setTitle: @"Activate Speech Commands" forState: UIControlStateNormal];
        }
    else
        { self.suspendSpeechCommands = NO;
            [self.speechCommandButton setTitle: @"Suspend Speech Commands" forState: UIControlStateNormal];
        }
}

- (IBAction)backToParent:(id)sender {
    if (![self.listParent isEqual: @"ROOT"]) //
    {
        self.listParent = self.listGrandParent;
        [self getGrandParent];
        self.listLabel.text = self.listParent;
        [self loadInitialData];
        [self.tableView reloadData];
        [self loadSpeechCommands];
        [self loadLanguageSet];
        [self changelanguageset]; //changes to the recreated language model
    }
}

//the following cannot be done for ROOT which has no parent
- (void) getGrandParent {
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTS WHERE NAME=\'%@\'", self.listParent];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *taskparent =
                [[NSString alloc] initWithUTF8String:
                 (const char *) sqlite3_column_text(statement, 3)];

                self.listGrandParent = taskparent;
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }

//    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Got GrandParent"
//    message:[NSString stringWithFormat: @"%@", self.listGrandParent]
//                                                     delegate:nil
//                                            cancelButtonTitle:@"OK"
//                                            otherButtonTitles:nil];
//
//    [message show];
}
    
@end
