//
//  CPLTableViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/8/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//
// Plans: cut and Move, prepopulate database, timer functions, dressing it up

#import "CPLTableViewController.h"
#import "CheckListItem.h"
#import <OpenEars/LanguageModelGenerator.h>
//#import "CPLSecondViewController.h"
#import "CPLAddListItemViewController.h"
#import "CPLMUDViewController.h"


@interface CPLTableViewController ()
 @property NSMutableArray *checkListItems;
@property NSMutableArray *speechCommands;
@property NSMutableArray *descendants;
@property NSMutableArray *unchecked_descendants;
@property CheckListItem *updatingItem;
// @property UITableView *tableView;   // for loadView which cases failure

@property  NSString *lmPath;
@property NSString *dicPath;
@property long currentrow;
@property NSArray *currentcells;
@property NSArray *currentcellpaths;
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


- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID
{
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);

if (self.suspendSpeechCommands == NO)
{
    if ([self.readListButton.currentTitle  isEqual: @"Read List"])
    {// in this mode reading a list member's name drills down to its children,, if any
        NSArray *cells = self.currentcells;
        NSArray *visible = self.currentcellpaths;
        
        [cells enumerateObjectsUsingBlock:^(UITableViewCell *cell,
                                            NSUInteger idx,
                                            BOOL *stop)
         {
             if ([hypothesis  isEqual: cell.textLabel.text])
             {

                 NSIndexPath* index = visible[idx];
                 
                 [self.tableView selectRowAtIndexPath:index animated:NO scrollPosition:            UITableViewScrollPositionMiddle];
                 
                [self respondSelectRow];
                 
             }
         }];
        
        if ([hypothesis  isEqual: @"READ LIST"])
        {
            if (![self.listParent isEqual: @"MASTER LIST"])
            {
            [self.readListButton setTitle: @"Check" forState: UIControlStateNormal];
            }
            self.currentrow = 0;
            [self readCurrent];
        }
        
        if ([hypothesis  isEqual: @"NEXT"] | [hypothesis  isEqual: @"OK"])
        {
            if (self.currentrow < [self.currentcells count] - 1)
            {
                self.currentrow += 1;
                [self readCurrent]; // this also selects that row
            }
            else
            {
                [self.fliteController say:@"List Ended" withVoice:self.slt];
            }
        }
        
        if ([hypothesis  isEqual: @"RETURN"])
        {
            if (![self.listParent isEqual: @"MASTER LIST"]) //
            {
                self.listParent = self.listGrandParent;
                [self.fliteController say:self.listParent withVoice:self.slt];
                self.listParentKey = self.listGrandParentKey;
                [self getGrandParent];
                self.listLabel.text = self.listParent;
                [self loadCurrentParentList];
                [self cellreloader]; //[self.tableView reloadData];
                [self loadSpeechCommands];
                [self loadLanguageSet];
                [self changelanguageset]; //changes to the recreated language model
                [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];

            }
        }
    }// end if readlistbutton is "Read List"
    else  // readListButton is "Check
    {   CheckListItem *item = self.checkListItems[self.currentrow];
        [self.tableView selectRowAtIndexPath:self.currentcellpaths[self.currentrow ] animated:NO scrollPosition:            UITableViewScrollPositionMiddle];
        NSString *text = item.itemName;
        
        if ([hypothesis  isEqual: text] | [hypothesis  isEqual: @"CONSIDER IT DONE"])
        {
            if (self.currentrow < [self.currentcells count] - 1)
            {
                //cell is selected in the readcurrent method
                
                // set checkmark on currentrow
                UITableViewCell *cell = self.currentcells[self.currentrow ];
                cell.accessoryType = UITableViewCellAccessoryCheckmark; //sets visible checkmark
                //also need to add a property to checklistitems indicating their checked status
                // then increment currentrow pointer
                // then read new current
                self.currentrow += 1;
                [self readCurrent]; // this also selects that row
            }
            else
            {   // set checkmark on currentrow
                UITableViewCell *cell = self.currentcells[self.currentrow ];
                cell.accessoryType = UITableViewCellAccessoryCheckmark; //sets visible checkmark
                //also need to add a property to checklistitems indicating their checked status
                
                [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];
                [self.fliteController say:@"List Ended" withVoice:self.slt];
            }
        }
        
        if ([hypothesis  isEqual: @"CHECK"] | [hypothesis  isEqual: @"NEXT"]| [hypothesis  isEqual: @"OK"] | [hypothesis  isEqual: @"DONE"])
        {
            NSString *saythis =  [NSString stringWithFormat:
             @"Please repeat item   '%@'   to mark it as done ", text];
            
             // tell user that they must repeat the list item to mark it as checked
             [self.fliteController say: saythis withVoice:self.slt];
        }
        
        if ([hypothesis  isEqual: @"RETURN"])
        {
            if (![self.listParent isEqual: @"MASTER LIST"]) //
            {
                self.listParent = self.listGrandParent;
                [self.fliteController say:self.listParent withVoice:self.slt];
                self.listParentKey = self.listGrandParentKey;
                [self getGrandParent];
                self.listLabel.text = self.listParent;
                [self loadCurrentParentList];
                [self cellreloader]; //[self.tableView reloadData];
                [self loadSpeechCommands];
                [self loadLanguageSet];
                [self changelanguageset]; //changes to the recreated language model
                [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];
                
            }
        }
        
    } // end if readlistbutton is "Check"

}// end if (self.suspendSpeechCommands == NO)
}//end pocketsphinxDidReceiveHypothesis

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
    [self.tableView selectRowAtIndexPath:self.currentcellpaths[self.currentrow ] animated:NO scrollPosition:            UITableViewScrollPositionMiddle];
    NSString *text = item.itemName;
    
    [self.fliteController say: text withVoice:self.slt];
    //    [self.fliteController say: text withVoice:self.kal];
}

- (void)loadCurrentParentList {

    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE PARENTKEY=\'%ld\'",self.listParentKey];
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
            long taskparentkey = sqlite3_column_int(statement, 3);
            long taskkey = sqlite3_column_int(statement, 0);
            CheckListItem *item = [[CheckListItem alloc] init];
            item.itemName = taskname;
            item.itemKey = *(&(taskkey));
            item.itemPriority = *(&(taskpriority));
            item.itemParent = self.listParent;
            item.itemParentKey = *(&(taskparentkey));
            [self.checkListItems addObject:item];
            
        }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }

    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
    
    [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
}

- (void) deleteOneByKey:(long) aKey {
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
    {
        NSString *updateSQL = [NSString stringWithFormat:
                               @"DELETE FROM CHECKLISTSBYKEY WHERE ID=%ld", aKey];
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
    }
}



- (void) findAllDescendantsbyKey:(long) parentKey {
    
    [self.descendants removeAllObjects];
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE PARENTKEY=\'%ld\'",parentKey];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                long taskkey = sqlite3_column_int(statement, 0);

//    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"find DIRECT descendents WITH Key"
//        message:[NSString stringWithFormat: @"%ld", taskkey]
//                                                     delegate:nil
//                                            cancelButtonTitle:@"OK"
//                                            otherButtonTitles:nil];
//    [message show];

            [self.unchecked_descendants addObject:[NSNumber numberWithInt:(taskkey)]];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }
    
    while ([self.unchecked_descendants count] > 0) {
    long aKey = [self.unchecked_descendants[0] longValue];
    
//UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"indirect descendents of key "
//    message:[NSString stringWithFormat: @"%ld", aKey]
//                                                 delegate:nil
//                                        cancelButtonTitle:@"OK"
//                                        otherButtonTitles:nil];
//[message show];
        
        const char *dbpath = [_databasePath UTF8String];
        sqlite3_stmt    *statement;
        
        if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE PARENTKEY=\'%ld\'",aKey];
            const char *query_stmt = [querySQL UTF8String];
            
            if (sqlite3_prepare_v2(_checklistDB,
                                   query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    long taskkey = sqlite3_column_int(statement, 0);
                    NSNumber *aNumber = [NSNumber numberWithInt:(taskkey)];
                    [self.unchecked_descendants addObject:aNumber]; // add desc of 0th item to unchecked list
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_checklistDB);
        }
        
        [self.descendants addObject: self.unchecked_descendants[0]]; // place the 0th item in descendants list
        [self.unchecked_descendants removeObject: self.unchecked_descendants[0]]; // remove the 0th item from unchecked list
    }
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
    [self.speechCommands addObject:@"DONE"];
    [self.speechCommands addObject:@"CONSIDER IT DONE"];

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


- (void) respondSelectRow {
    NSIndexPath *myIndexPath = [self.tableView
                                indexPathForSelectedRow];
    long row = [myIndexPath row];
    CheckListItem *item  = self.checkListItems[row];
    
    self.listGrandParent = self.listParent;
    self.listGrandParentKey = self.listParentKey;
    self.listParent = item.itemName;
    self.listParentKey = item.itemKey;
    self.listLabel.text = self.listParent;
    [self loadCurrentParentList];
    [self cellreloader]; //[self.tableView reloadData];
    [self loadSpeechCommands];
    [self loadLanguageSet];
    [self changelanguageset]; //changes to the recreated language model
    [self.fliteController say:self.listParent withVoice:self.slt];
    [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//  self.listenerStatus.text = @"selected";
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self respondSelectRow];
    

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
    self.descendants = [[NSMutableArray alloc] init];
    self.unchecked_descendants = [[NSMutableArray alloc] init];
    
    NSString *docsDir;
    
    NSArray *dirPaths;
    
    self.listParent = @"MASTER LIST";
    self.listGrandParent = @"MASTER LIST";
    self.listParentKey = 0;
    self.listGrandParentKey = 0;
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
            "CREATE TABLE IF NOT EXISTS CHECKLISTSBYKEY (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME, PRIORITY, PARENTKEY)";
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

    
    [self loadCurrentParentList];
    [self loadSpeechCommands];
    [self loadLanguageSet];
    [self startlanguageset];
    [self cellreloader]; //[self.tableView reloadData];
//    [self changelanguageset];
    
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
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
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
    item.itemParent = self.listParent;
    item.itemParentKey = self.listParentKey;
    if (item != nil)
    {

        // save the task in the database
        sqlite3_stmt    *statement;
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *insertSQL = [NSString stringWithFormat:
                                   @"INSERT INTO CHECKLISTSBYKEY (name, priority, parentkey) VALUES (\'%@\', %ld, %ld)",
                                item.itemName, item.itemPriority, item.itemParentKey];
            const char *insert_stmt = [insertSQL UTF8String];
            sqlite3_prepare_v2(_checklistDB, insert_stmt,
                               -1, &statement, NULL);
            
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
            }
            else
            {
            }
            sqlite3_finalize(statement);
//            sqlite3_close(_checklistDB);
//to do the followin (get itemkey, need to do it before the close
        }
        
        //need to get the added item's itemkey

//        if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
//        {
            NSString *querySQL = [NSString stringWithFormat: @"SELECT last_insert_rowid()"];
            const char *query_stmt = [querySQL UTF8String];
            
            if (sqlite3_prepare_v2(_checklistDB,
                                   query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    long taskkey = sqlite3_column_int(statement, 0);
                    item.itemKey = *(&(taskkey));
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_checklistDB);
//        }
        
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"check itemkey just added"
//    message:  [NSString stringWithFormat: @"%ld", item.itemKey]
//    delegate:self
//    cancelButtonTitle:@"OK"
//    otherButtonTitles:nil];
//    [alert show];
        
        // now that we have its itemkey we can add the item to the checklists
        [self.checkListItems addObject:item];
        // want to sort this list by itemPriority
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
        [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        [self cellreloader]; //[self.tableView reloadData];
        
    [self loadSpeechCommands];  //reloads database as speechcommands
    [self loadLanguageSet]; // recreates language model from speechcommands
    [self changelanguageset]; //changes to the recreated language model
    }
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue  sender:(id)sender
{
[self cellreloader]; //[self.tableView reloadData];

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
        [self cellreloader]; //[self.tableView reloadData];
        long aKey =  item.itemKey;
        [self findAllDescendantsbyKey:aKey];
        while ([self.descendants count] > 0) {
            long eachKey = [self.descendants[0] longValue];
            [self deleteOneByKey:eachKey];
            [self.descendants removeObject:self.descendants[0]];
        }
        [self deleteOneByKey:aKey];
        
    } //close if delete
    else
    {
        [self.checkListItems removeObject:self.updatingItem];
        [self.checkListItems addObject:item];
        
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
        [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        [self cellreloader]; //[self.tableView reloadData];
        
        
        // update the task in the database
        sqlite3_stmt    *statement;
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_checklistDB) == SQLITE_OK)
        {
            NSString *updateSQL = [NSString stringWithFormat:
                                   @"UPDATE CHECKLISTSBYKEY SET PRIORITY=%ld WHERE ID=%ld",
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
                                   @"UPDATE CHECKLISTSBYKEY SET NAME=\"%@\" WHERE ID=%ld",
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
    

}

- (IBAction)speechCommandToggle:(id)sender
{
    
    if ([self.speechCommandButton.currentTitle  isEqual: @"Suspend Speech"])
        {  self.suspendSpeechCommands = YES;
            [self.speechCommandButton setTitle: @"Activate Speech" forState: UIControlStateNormal];
        }
    else
        { self.suspendSpeechCommands = NO;
            [self.speechCommandButton setTitle: @"Suspend Speech" forState: UIControlStateNormal];
        }
}

- (IBAction)backToParent:(id)sender {
    if (![self.listParent isEqual: @"MASTER LIST"]) //
    {
        self.listParent = self.listGrandParent;
        self.listParentKey = self.listGrandParentKey;
        [self getGrandParent];
        self.listLabel.text = self.listParent;
        [self loadCurrentParentList];
        [self cellreloader]; //[self.tableView reloadData];
        [self loadSpeechCommands];
        [self loadLanguageSet];
        [self changelanguageset]; //changes to the recreated language model
        [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];
    }
}

//the following cannot be done for MASTER LIST which has no parent
- (void) getGrandParent
{
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE ID=%ld", self.listParentKey];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_checklistDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                long taskparentkey = sqlite3_column_int(statement, 3);
                self.listGrandParentKey = *(&(taskparentkey));
                //this is the parentkeyfor the current list parent

            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }

    if (self.listGrandParentKey != 0) //if grandparentkey is 0 that means current list is MASTER LIST
    {
        if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
        {
            NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE ID=%ld", self.listGrandParentKey];
            const char *query_stmt = [querySQL UTF8String];
            
            if (sqlite3_prepare_v2(_checklistDB,
                                   query_stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    NSString *taskname =
                    [[NSString alloc] initWithUTF8String:
                     (const char *) sqlite3_column_text(statement, 1)];
                    
                    self.listGrandParent = taskname;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_checklistDB);
        }
    }
    else
    {  self.listGrandParent = @"MASTER LIST";
        self.listGrandParentKey = 0;
    }
}

    
- (IBAction)readListButton:(id)sender {
    if ([self.readListButton.currentTitle  isEqual: @"Read List"])
    {   [self cellreloader];
        [self.readListButton setTitle: @"Check" forState: UIControlStateNormal];
        self.currentrow = 0;
        [self readCurrent];
    }
    else
    {
        if (self.currentrow < [self.currentcells count] - 1)
        {
            //cell is selected in the readcurrent method
            
            // set checkmark on currentrow
            UITableViewCell *cell = self.currentcells[self.currentrow ];
            cell.accessoryType = UITableViewCellAccessoryCheckmark; //sets visible checkmark
            //also need to add a property to checklistitems indicating their checked status
            // then increment currentrow pointer
            // then read new current
            self.currentrow += 1;
            [self readCurrent]; // this also selects that row
        }
        else
        {
            // set checkmark on currentrow
            UITableViewCell *cell = self.currentcells[self.currentrow ];
            cell.accessoryType = UITableViewCellAccessoryCheckmark; //sets visible checkmark
            //also need to add a property to checklistitems indicating their checked status
            
            [self.readListButton setTitle: @"Read List" forState: UIControlStateNormal];
            [self.fliteController say:@"List Ended" withVoice:self.slt];
        }
    }

}


- (void) cellreloader
{
    [self.tableView reloadData];
    self.currentrow = 0;
    self.currentcells = [self.tableView visibleCells]; //how to get array of all rows?
    self.currentcellpaths = [self.tableView indexPathsForVisibleRows];
}


@end
