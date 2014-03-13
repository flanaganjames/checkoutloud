//
//  CPLSecondViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/10/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLSecondViewController.h"
#import "CheckListItem.h"

@interface CPLSecondViewController ()
    @property NSMutableArray *checkListItems;

@end

@implementation CPLSecondViewController

//start openears stuff


- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    
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
    
    if ([hypothesis  isEqual: @"DONE"])
    {
//        [self.originView performSegueWithIdentifier: @"unwindToList" sender: self];
        [self performSegueWithIdentifier: @"unwindToList" sender: self];
    }
    
}
//end openears stuff


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.listLabel.text = self.listParent;

    
    self.checkListItems = [[NSMutableArray alloc] init];
    
    NSString *docsDir;
    
    NSArray *dirPaths;
    
    // Get the documents directory
    
    dirPaths = NSSearchPathForDirectoriesInDomains(
                                                   NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    
    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"checklist.db"]];
    
    [self loadInitialData];
    

    
    //start openears stuff
    [self.openEarsEventsObserver setDelegate:self];
    //end of openears stuff

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return [self.checkListItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CheckListCell2";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
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


// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        [tableView deselectRowAtIndexPath: indexPath animated:NO];
        
        CheckListItem *tappedItem = [self.checkListItems objectAtIndex:indexPath.row];
        tappedItem.completed = !tappedItem.completed;
    
        NSString *text = tappedItem.itemName;
    
        [self.fliteController say: text withVoice:self.slt];
//        [self.fliteController say: text withVoice:self.kal];
}


- (IBAction)unwindToList:(id)sender {
}
@end
