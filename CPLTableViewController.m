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
#import "CPLAddListItemViewController.h"
#import "CPLMUDViewController.h"
#import "CPLSlideShowViewController.h"
#import "CustomSegue.h"
#import "CustomUnwindSegue.h"
#import "CPLPreferencesViewController.h"
#import "CPLTimeDelayItem.h"


@interface CPLTableViewController ()
@property NSMutableArray *checkListItems;
@property NSMutableArray *speechCommands;
@property NSMutableArray *descendantKeys;
@property NSMutableArray *descendantItems;
@property NSMutableArray *listOfLists;
@property NSMutableArray *listOfListNames;
@property NSMutableArray *unchecked_descendantKeys;
@property NSMutableArray *unchecked_descendantItems;
@property NSMutableArray *unscheduledTDItems;
@property NSMutableArray *tobescheduledTDItems;
@property NSMutableArray *timeDelayItems;
@property CheckListItem *updatingItem;
@property CheckListItem *checkingItem;
@property long addItemPriority;
@property BOOL *updatingDelete;
@property BOOL skipCheckedItems;
@property NSString *editMode;


// @property UITableView *tableView;   // for loadView which cases failure

@property  NSString *lmPath;
@property NSString *dicPath;
@property long currentrow;
@property NSArray *currentcells;
@property NSArray *currentcellpaths;
@property NSInteger currentcellcount;

@property BOOL allowSpeak;
@property BOOL allowListen;
@property BOOL waitForFlite;

@end

@implementation CPLTableViewController

@synthesize pocketsphinxController;

@synthesize openEarsEventsObserver;

@synthesize fliteController;

@synthesize slt;
@synthesize kal;


- (FliteController *)fliteController { if (fliteController == nil) { fliteController = [[FliteController alloc] init]; } return fliteController; } - (Slt *)slt { if (slt == nil) { slt = [[Slt alloc] init]; } return slt; }


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


- (void) pocketsphinxDidReceiveHypothesis:(NSString *)rawhypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID
{
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", rawhypothesis, recognitionScore, utteranceID);
    
    NSString *hypothesis = [NSString stringWithFormat: @" %@", rawhypothesis];
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
                     
                    // [self respondSelectRow:index];
                    [self slideShowForSelectRow:index];//speak name of list starts checking
                     
                 }
             }];
            
            if ([hypothesis  isEqual: @" READ LIST"] | [hypothesis  isEqual: @" CHECK ALL LISTS"])
            {
                [self readListButton:self];
            }
            
            if ([hypothesis  isEqual: @" RETURN"])
            {
                if (![self.listParent isEqual: @"MASTER LIST"]) //
                {
                    self.listParent = self.listGrandParent;
                    [self passToFlite:self.listParent];

                    self.listParentKey = self.listGrandParentKey;
                    [self getGrandParent];
                    self.listLabel.text = self.listParent;
                    [self loadCurrentParentList];
                    [self cellreloader]; //[self.tableView reloadData];
                    [self loadSpeechCommands];
                    [self loadLanguageSet];
                    [self changelanguageset]; //changes to the recreated language model
                }
            }
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
    
    [self passToFlite:text];
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


- (NSMutableArray *) findImmediateDescendantsbyKey:(long) parentKey
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
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
            {CheckListItem *item = [[CheckListItem alloc] init];
                NSString *taskname =
                [[NSString alloc] initWithUTF8String:
                 (const char *) sqlite3_column_text(statement, 1)];
                int taskpriority = sqlite3_column_int(statement, 2);
                long taskparentkey = sqlite3_column_int(statement, 3);
                long taskkey = sqlite3_column_int(statement, 0);
                
                item.itemName = taskname;
                item.itemKey = *(&(taskkey));
                item.itemPriority = *(&(taskpriority));
                item.itemParent = self.listParent;
                item.itemParentKey = *(&(taskparentkey));
                [tempArray addObject:item];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
        
        //sort immediate descendents so they are in proper order
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
        [tempArray sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
    }
    return tempArray;
}

//this completes self.descendentitems which is used vy slideShowForEntireList (and some other similar methods) to create slide shows; would be better to change this to return the array; it also completes self.unscheduledTDItems which stages TDI for scheduling if the slide show returns having gone past that item's priority; see slideShowForEntireList for example
- (void) findAllDescendantItemsbyKey:(long) parentKey
{
    self.checkedItemsHaveBeenSkipped = NO;
    [self.descendantItems removeAllObjects];
    [self.unscheduledTDItems removeAllObjects];
    int currentGeneration = 0;
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    NSMutableArray *workingArray = [[NSMutableArray alloc] init];
    NSMutableArray *tempLists = [[NSMutableArray alloc] init];
    
    //start with immediate descendants in workingArray, work the workingArray: work the 0th item, as item is found that has no descendants, move 0th item to the self.descendantItems.  As 0th item descendants are discovered (in tempArray), create the 0-copy and put into self.descendantItems, change 0th item to the -1-copy, push the workingArray to the next item of tempLists, increment currentGeneration by 1, put the elements of tempArray into workingArray; when workingArray is empty if current Generation = 0 DONE, if currentGeneration > 0 pop the mostrecent (highest)list of tempLists into workingArray, decrement currentGeneration by 1, upon reaching a -1-copy put it in self.descendantItems
    
    //first get the immediate descendents and put into the unchecked list
    tempArray = [self findImmediateDescendantsbyKey: parentKey];

    if (self.skipCheckedItems && [tempArray count] > 0) //remove items already checked
    {
        NSMutableArray *anotherTempArray = [[NSMutableArray alloc] init];
        int innerCounter = 0;
        NSNumber *aNumber = [[NSNumber alloc] init];
        while (innerCounter < [tempArray count])
        {
            CheckListItem *item = tempArray[innerCounter];
            aNumber = [NSNumber numberWithLong:item.itemKey];
            
            if (![self.checkedItemKeys containsObject: aNumber])
            {
                [anotherTempArray addObject: item];
            }
            else
            {
                self.checkedItemsHaveBeenSkipped = YES;
            }
            innerCounter += 1;
        }
        [tempArray removeAllObjects];
        
        if ([anotherTempArray count] > 0)
        {   innerCounter = 0;
            while (innerCounter < [anotherTempArray count])
            {
                CheckListItem *item  = anotherTempArray[innerCounter];
                [tempArray addObject: item];
                innerCounter += 1;
            }
        }
        
    }
    
    // put items of temarray into workingArray
    int aCounter = 0;
    while (aCounter < [tempArray count])
    {
        [workingArray addObject: tempArray[aCounter]];
        aCounter += 1;
    }
    
    while (currentGeneration > -1)
    {
    while ([workingArray count] > 0)
    {   // should I be destroying the old item?
        CheckListItem *item = [[CheckListItem alloc] init];
        item = workingArray[0];
        if (item.itemPriority == -1)
        {
            [self.descendantItems addObject: item];
            [workingArray removeObject: item];
        }
        else
        {
            CPLTimeDelayItem *aTDItem = [self returnTDItem: item];
            if (!aTDItem)

            {
                tempArray = [self findImmediateDescendantsbyKey: item.itemKey];
                // now remove from this list any that are already ckecked if "skipcheckeditems = YES"

                if (self.skipCheckedItems && [tempArray count] > 0) //remove items already checked
                {
                    NSMutableArray *anotherTempArray = [[NSMutableArray alloc] init];
                    int innerCounter = 0;
                    NSNumber *aNumber = [[NSNumber alloc] init];
                    while (innerCounter < [tempArray count])
                    {
                        CheckListItem *item = tempArray[innerCounter];
                        aNumber = [NSNumber numberWithLong:item.itemKey];
                        
                        if (![self.checkedItemKeys containsObject: aNumber])
                        {
                            [anotherTempArray addObject: item];
                        }
                        else
                        {
                            self.checkedItemsHaveBeenSkipped = YES;
                        }
                        innerCounter += 1;
                    }
                    [tempArray removeAllObjects];
                    
                    if ([anotherTempArray count] > 0)
                    {   innerCounter = 0;
                        while (innerCounter < [anotherTempArray count])
                        {
                            CheckListItem *item  = anotherTempArray[innerCounter];
                            [tempArray addObject: item];
                            innerCounter += 1;
                        }
                    }
                    
                }
                if ([tempArray count] > 0)
                {
                    CheckListItem *anotherItem = [[CheckListItem alloc] init];
                    anotherItem.itemName = item.itemName;
                    anotherItem.itemPriority = 0;
                    anotherItem.itemKey = item.itemKey;
                   //[self.descendantItems addObject: anotherItem];
                    [self.descendantItems addObject: anotherItem];
                    item.itemPriority = -1; // this should change the 0th item itemPriority
                    //push the currentworkingArray into tempLists
                    [tempLists addObject:[workingArray copy]];
                    [workingArray removeAllObjects];
                    int aCounter = 0;
                    while (aCounter < [tempArray count])
                    {
                        [workingArray addObject: tempArray[aCounter]];
                        aCounter += 1;
                    }
                    currentGeneration += 1;
                }
                else // item has no descendants
                {
                    [self.descendantItems addObject: item];
                    [workingArray removeObject: item];
                }
            }
            else //it is a time delay item; its children do not get added to current slide show
            {
                //[self.descendantItems addObject: item];
                [workingArray removeObject: item];
             //   [self scheduleTimeDelayItem:aTDItem];
                [self.unscheduledTDItems addObject:aTDItem];
            }
        }
    }// workingArray is now empty
        if (currentGeneration > 0) //pop a list of tempLists into workArray
        {
            [workingArray removeAllObjects];// get rid of this
            NSMutableArray *anArray = tempLists[currentGeneration - 1];
            int aCounter = 0;
            while (aCounter < [anArray count])
            {
                [workingArray addObject: anArray[aCounter]];
                aCounter += 1;
            }
            [tempLists removeObject: anArray];
        }
        currentGeneration -= 1;
    }
}


// returns the suffix describing the time delay if an item is a time delay item; returns nil otherwise indicating it is not a TDI.
- (NSString *) suffixForTimeDelayItem: (CheckListItem *) aCLItem
{
    NSString *tdsig = @""; // initialize suffix to empty
    
    NSString *string = aCLItem.itemName;
    NSError *error = NULL;
    // this finds " | td*****"
    NSRegularExpression *regexsuffix = [NSRegularExpression regularExpressionWithPattern:@"\\ \\| td.+"
        options:NSRegularExpressionCaseInsensitive
        error:&error];
    NSTextCheckingResult *match = [regexsuffix firstMatchInString:string
        options:0
        range:NSMakeRange(0, [string length])];
    if (match) // if it has a suffix, get the suffix's tdsig
    {
        NSRange matchRange = [match range];
        NSString *suffix = [string substringWithRange: matchRange]; // here is the entire suffix
        NSRegularExpression *regextdprefix = [NSRegularExpression regularExpressionWithPattern:@"\\ \\| td-"
            options:NSRegularExpressionCaseInsensitive
            error:&error];
        NSTextCheckingResult *match2 = [regextdprefix firstMatchInString:suffix
            options:0
            range:NSMakeRange(0, [suffix length])];
        if (match2) // if the suffix has a prefix indicating a time delay item
        {
            tdsig = [regextdprefix stringByReplacingMatchesInString:suffix
            options:0
            range:NSMakeRange(0, [suffix length])
            withTemplate:@""];
            // here is the part of the suffix that specifies time and repeat
        }
    }
    return tdsig;
}

//desciphers the suffix of a CLItem, if it is a TDI, to create a TDI object
- (CPLTimeDelayItem *) returnTDItem: (CheckListItem *) aCLItem
{
    NSString *tdsig = @""; // initialize suffix to empty
    
    NSString *string = aCLItem.itemName;
    NSError *error = NULL;
    // this finds " | td*****"
    NSRegularExpression *regexsuffix = [NSRegularExpression regularExpressionWithPattern:@"\\ \\| td.+"
                                                                options:NSRegularExpressionCaseInsensitive
                                                                                   error:&error];
    NSTextCheckingResult *match = [regexsuffix firstMatchInString:string
                                                          options:0
                                                            range:NSMakeRange(0, [string length])];
    if (match) // if it has a suffix, get the suffix's tdsig
    {
        NSRange matchRange = [match range];
        NSString *suffix = [string substringWithRange: matchRange]; // here is the entire suffix
        NSRegularExpression *regextdprefix = [NSRegularExpression regularExpressionWithPattern:@"\\ \\| td-"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
        NSTextCheckingResult *match2 = [regextdprefix firstMatchInString:suffix
                                                                 options:0
                                                                   range:NSMakeRange(0, [suffix length])];
        if (match2) // if the suffix has a prefix indicating a time delay item
        {
            tdsig = [regextdprefix stringByReplacingMatchesInString:suffix
                                                            options:0
                                                              range:NSMakeRange(0, [suffix length])
                                                       withTemplate:@""];
            // here is the part of the suffix that specifies time and repeat
        }
    }
    
    NSString *emptyString = @"";
    
    if (![tdsig  isEqual: emptyString]) // if the suffix is not an empty string then this is a time delay item
    {
        CPLTimeDelayItem *aTDItem = [[CPLTimeDelayItem alloc] init];
        aTDItem.itemName = [regexsuffix stringByReplacingMatchesInString:string
                                                                   options:0
                                                                     range:NSMakeRange(0, [string length])
                                                              withTemplate:@""];
        aTDItem.itemKey = aCLItem.itemKey;
        aTDItem.itemParentKey = aCLItem.itemParentKey;
        aTDItem.itemPriority = aCLItem.itemPriority;
        NSRegularExpression *regexrepeat = [NSRegularExpression regularExpressionWithPattern:@"\\d+rpt"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
        NSTextCheckingResult *match3 = [regexrepeat firstMatchInString:tdsig
                                                                 options:0
                                                                   range:NSMakeRange(0, [tdsig length])];
        if (match3)
        {
            NSRange matchRange = [match3 range];
            NSString *repeatstring = [tdsig substringWithRange: matchRange];
            NSRegularExpression *regexrpt = [NSRegularExpression regularExpressionWithPattern:@"rpt"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
            
            repeatstring = [regexrpt stringByReplacingMatchesInString:repeatstring
                                                          options:0
                                                            range:NSMakeRange(0, [repeatstring length])
                                                     withTemplate:@""];
            aTDItem.repeatNumber = [repeatstring intValue];
            
        }
        
        
        NSRegularExpression *regexnumberhours = [NSRegularExpression regularExpressionWithPattern:@"\\d+h"
                                                                                     options:NSRegularExpressionCaseInsensitive
                                                                                       error:&error];
        NSTextCheckingResult *match4 = [regexnumberhours firstMatchInString:tdsig
                                                               options:0
                                                                 range:NSMakeRange(0, [tdsig length])];
        if (match4)
        {
            NSRange matchRange = [match4 range];
            NSString *hourstring = [tdsig substringWithRange: matchRange];
            NSRegularExpression *regexh = [NSRegularExpression regularExpressionWithPattern:@"h"
                                                                                          options:NSRegularExpressionCaseInsensitive
                                                                                            error:&error];
        
            hourstring = [regexh stringByReplacingMatchesInString:hourstring
                                                        options:0
                                                          range:NSMakeRange(0, [hourstring length])
                                                   withTemplate:@""];
            aTDItem.delayHours = [hourstring intValue];
        
        }
        
        NSRegularExpression *regexnumberminutes = [NSRegularExpression regularExpressionWithPattern:@"\\d+m"
                                                                                          options:NSRegularExpressionCaseInsensitive
                                                                                            error:&error];
        NSTextCheckingResult *match5 = [regexnumberminutes firstMatchInString:tdsig
                                                                    options:0
                                                                      range:NSMakeRange(0, [tdsig length])];
        if (match5)
        {
            NSRange matchRange = [match5 range];
            NSString *minutestring = [tdsig substringWithRange: matchRange];
            NSRegularExpression *regexm = [NSRegularExpression regularExpressionWithPattern:@"m"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
            
            minutestring = [regexm stringByReplacingMatchesInString:minutestring
                                                          options:0
                                                            range:NSMakeRange(0, [minutestring length])
                                                     withTemplate:@""];
            aTDItem.delayMinutes = [minutestring intValue];
            
        }
        
        NSRegularExpression *regexnumberseconds = [NSRegularExpression regularExpressionWithPattern:@"\\d+s"
                                                                                            options:NSRegularExpressionCaseInsensitive
                                                                                              error:&error];
        NSTextCheckingResult *match6 = [regexnumberseconds firstMatchInString:tdsig
                                                                      options:0
                                                                        range:NSMakeRange(0, [tdsig length])];
        if (match6)
        {
            NSRange matchRange = [match6 range];
            NSString *secondstring = [tdsig substringWithRange: matchRange];
            NSRegularExpression *regexs = [NSRegularExpression regularExpressionWithPattern:@"s"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
            
            secondstring = [regexs stringByReplacingMatchesInString:secondstring
                                                            options:0
                                                              range:NSMakeRange(0, [secondstring length])
                                                       withTemplate:@""];
            aTDItem.delaySeconds = [secondstring intValue];
            
        }
        
        aTDItem.totalDelaySeconds = 3600*aTDItem.delayHours + 60*aTDItem.delayMinutes + aTDItem.delaySeconds;
        
        return aTDItem;
    }
    else
    {
        return nil;
    }

}


- (void) slideShowForEntireList
{
    
    //this new approach simplifies slideshow so that there will never be more than one list in lists of lists;  need to remove logic that handles possible multiple lists
    [self.listOfLists removeAllObjects];
    [self.listOfListNames removeAllObjects];
    
    CheckListItem *item  = self.checkListItems[0];
    CheckListItem *itemParent = [[CheckListItem alloc] init];
    itemParent.itemName = self.listParent;
    itemParent.itemKey = item.itemParentKey;
    //self.checkingItem = itemParent;
    

    CPLTimeDelayItem *aTDItem = [self returnTDItem: itemParent];
    
    if (aTDItem) // if a TDItem is returned
    {
        [self scheduleTimeDelayItem:aTDItem];
    }
    else
    {
        [self findAllDescendantItemsbyKey:itemParent.itemKey];
        if (self.checkedItemsHaveBeenSkipped)
        {
            [self passToFlite:@"Previously checked Items Will be Skipped"];
        }
        if ([self.descendantItems count] > 0)
        {
            [self.listOfLists addObject:self.descendantItems];
            [self.listOfListNames addObject:itemParent.itemName];
            [self performSegueWithIdentifier: @"slideShow" sender: self];
        }
    }
}

- (void) slideShowForSelectRow: (NSIndexPath *) myIndexPath
{
    //    NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
    [self.listOfLists removeAllObjects];
    [self.listOfListNames removeAllObjects];
    long row = [myIndexPath row];
    //    UITableViewCell *cell = self.currentcells[row];
    
    
    // when a checklist is initiated, assume user wants to uncheck all descendent items if checked.
    
    
    CheckListItem *item  = self.checkListItems[row];
    
    CPLTimeDelayItem *aTDItem = [self returnTDItem: item];
    if (aTDItem)
    {
        [self scheduleTimeDelayItem:aTDItem];
    }
    else
    {
        //self.checkingItem = item;
        long aKey =  item.itemKey;
        [self findAllDescendantItemsbyKey:aKey];
        if (self.checkedItemsHaveBeenSkipped)
        {
            [self passToFlite:@"Previously checked Items Will be Skipped"];
        }
        if ([self.descendantItems count] > 0)
        {
            [self.listOfLists addObject:self.descendantItems];
            [self.listOfListNames addObject:item.itemName];
            [self performSegueWithIdentifier: @"slideShow" sender: self];
            
        }
        else //if there are no descendants then create slideshow of one item
        {
            [self.descendantItems addObject: item];
            [self.listOfLists addObject:self.descendantItems];
            [self.listOfListNames addObject:self.listParent];
            [self performSegueWithIdentifier: @"slideShow" sender: self];
        }
    }
}



-(void) checkForUnscheduledTDItems
//these are saved in the process of creating a slideshow (findAllDescItems) and then scheduled when the slideshow returns in viewdidappear
{
    int aCounter = 0;
    while (aCounter < [self.tobescheduledTDItems count])
    {
        CPLTimeDelayItem *aTDItem = self.tobescheduledTDItems[aCounter];
        [self scheduleTimeDelayItem:aTDItem];
        aCounter += 1;
    }
    
    [self.tobescheduledTDItems removeAllObjects];
    [self.unscheduledTDItems removeAllObjects];
}

-(void) checkForScheduledItemsPastDue
{
    CPLTimeDelayItem *aTDItem = [[CPLTimeDelayItem alloc] init];
    NSDate *now = [NSDate date];
    
    for (aTDItem in self.timeDelayItems)
    {
        if ([aTDItem.setDateTime earlierDate:now])
        {
          [self slideShowForTimeDelayItem: aTDItem];
        }
    }
}

//used by above checkForUnscheduledTDItems
- (void) scheduleTimeDelayItem: (CPLTimeDelayItem *) aTDItem
{
    int aCounter = 0;
    while (aCounter < aTDItem.repeatNumber)
    {
        CPLTimeDelayItem *aTDItemCopy = [self copyTDItem:aTDItem];
        long aTimeinSeconds = (aCounter+1)*aTDItem.totalDelaySeconds;
        NSDate *now = [NSDate date];
        NSDate *newDate1 = [now addTimeInterval:aTimeinSeconds];
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        localNotif.fireDate = newDate1;
        localNotif.alertBody = @"Alert! CheckoutLoud scheduled check list due";
        localNotif.alertAction = NSLocalizedString(@"View Details", nil);
        localNotif.soundName = @"CheckOutLoudAlert.wav"; //UILocalNotificationDefaultSoundName;
        
        
//        localNotif.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
        
        aTDItemCopy.setDateTime = newDate1;
        

        [self performSelector:@selector(slideShowForTimeDelayItem:) withObject:aTDItemCopy afterDelay:aTimeinSeconds];
        //add it to the list of things to be done by the operating system
        [self.timeDelayItems addObject:aTDItemCopy];
        //add it to the list showing the things that will be done
        
        // sort the timeDelayItems
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"setDateTime" ascending:YES];
        [self.timeDelayItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        aCounter += 1;
    }
    
    NSInteger anInt = [self.timeDelayItems count];
    [UIApplication sharedApplication].applicationIconBadgeNumber = anInt;
    
        NSString *aTitle = [NSString stringWithFormat: @"%@ Item Scheduled", aTDItem.itemName];
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:aTitle
            message:[NSString stringWithFormat: @"Repetitions: %d at intervals of %d hours, %d minutes and %d seconds",aTDItem.repeatNumber, aTDItem.delayHours, aTDItem.delayMinutes, aTDItem.delaySeconds ]

                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
        [message show];
    
}

// used by above scheduleTimeDelayItem
- (void) slideShowForTimeDelayItem: (CPLTimeDelayItem *) aTDItem
{
    if (self.isViewLoaded && self.view.window)
    {
        [self.listOfLists removeAllObjects];
        [self.listOfListNames removeAllObjects];
        //self.checkingItem = aCLItem;
        long aKey =  aTDItem.itemKey;
        [self findAllDescendantKeysbyKey:aKey];
        [self resetSelectedCheckMarks:self.descendantKeys];
        
        aTDItem.itemPriority = 1;
        [self findAllDescendantItemsbyKey:aKey];
        if (self.checkedItemsHaveBeenSkipped)
        {
            [self passToFlite:@"Previously checked Items Will be Skipped"];
        }
        if ([self.descendantItems count] > 0)
        {
            [self.listOfLists addObject:self.descendantItems];
            [self.listOfListNames addObject:aTDItem.itemName];
            [self performSegueWithIdentifier: @"slideShow" sender: self];
        }
        else
        {
            [self.descendantItems addObject: aTDItem];
            [self.listOfLists addObject:self.descendantItems];
            [self.listOfListNames addObject:@"Time Delay Item"];
            [self performSegueWithIdentifier: @"slideShow" sender: self];
        }
        
        [self removeScheduledItemFromList:aTDItem];
    }
    else
    {
        //note this flite call deliberately is not contingent upon preferences allowing speech.  This occurs when main view is not in view and user needs to be reminded to return to main view for this time delayed scheduled event
        [self.fliteController say:@"Scheduled item delayed - please return to main window" withVoice:self.slt];
        
        [self performSelector:@selector(slideShowForTimeDelayItem:) withObject:aTDItem afterDelay:5]; // try again in 5 seconds
    }
}

- (CPLTimeDelayItem *) copyTDItem: (CPLTimeDelayItem *) aTDItem
{
    CPLTimeDelayItem *aTDItemCopy = [[CPLTimeDelayItem alloc] init];
    
    aTDItemCopy.itemName = aTDItem.itemName;
    aTDItemCopy.itemKey = aTDItem.itemKey;
    aTDItemCopy.itemParentKey = aTDItem.itemParentKey;
    aTDItemCopy.itemPriority = aTDItem.itemPriority;
    aTDItemCopy.repeatNumber = aTDItem.repeatNumber;
    aTDItemCopy.delayHours = aTDItem.delayHours;
    aTDItemCopy.delayMinutes = aTDItem.delayMinutes;
    aTDItemCopy.delaySeconds = aTDItem.delaySeconds;
    aTDItemCopy.totalDelaySeconds = aTDItem.totalDelaySeconds;
    aTDItemCopy.setDateTime = aTDItem.setDateTime;
    
    return aTDItemCopy;
}

- (void) removeScheduledItemFromList: (CPLTimeDelayItem *) aTDItem
{
    [self.timeDelayItems removeObject: aTDItem];
    NSInteger anInt = [self.timeDelayItems count];
    [UIApplication sharedApplication].applicationIconBadgeNumber = anInt;
}

- (void) cancelScheduledReminders
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.timeDelayItems removeAllObjects];

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

-(void)appWillTerminate:(NSNotification*)note
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
}

// used to find descendants when deleting an item (which also deletes its descendants
- (void) findAllDescendantKeysbyKey:(long) parentKey {
    
    [self.descendantKeys removeAllObjects];
    [self.unchecked_descendantKeys removeAllObjects];

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

            [self.unchecked_descendantKeys addObject:[NSNumber numberWithInt:(taskkey)]];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_checklistDB);
    }
    
    while ([self.unchecked_descendantKeys count] > 0)
    {
    long aKey = [self.unchecked_descendantKeys[0] longValue];
        
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
                    [self.unchecked_descendantKeys addObject:aNumber]; // add desc of 0th item to unchecked list
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_checklistDB);
        }
        
        [self.descendantKeys addObject: self.unchecked_descendantKeys[0]]; // place the 0th item in descendants list; this is just the key as a NSNumber
        
        [self.unchecked_descendantKeys removeObject: self.unchecked_descendantKeys[0]]; // remove the 0th item from unchecked list
    }
    
}



//creates array of NSStrings to be recognized as speech commands, all uppercase
- (void)loadSpeechCommands {
    
    [self.speechCommands removeAllObjects];
// default commands
    [self.speechCommands addObject:@"RETURN"];
    [self.speechCommands addObject:@"READ LIST"];
    [self.speechCommands addObject:@"CHECK ALL LISTS"];
    [self.speechCommands addObject:@"SAY AGAIN"];
    [self.speechCommands addObject:@"REPEAT"];
    [self.speechCommands addObject:@"CHECK"];
    [self.speechCommands addObject:@"CONSIDER IT DONE"];
    [self.speechCommands addObject:@"AFFIRMATIVE"];
    [self.speechCommands addObject:@"OK"];
    [self.speechCommands addObject:@"ADD"];
    [self.speechCommands addObject:@"UPDATE"];
    [self.speechCommands addObject:@"SAVE"];
    [self.speechCommands addObject:@"NEXT"];
    [self.speechCommands addObject:@"DONE"];



//also support commands for items in Master List
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &(_checklistDB)) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM CHECKLISTSBYKEY WHERE PARENTKEY=0"];
        // this change means only the master list names can be accessed by voice
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

}

//used by handletap in Check Mode
- (void) respondSelectRow: (NSIndexPath *) myIndexPath
{
    //NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
    long row = [myIndexPath row];
    CheckListItem *item  = self.checkListItems[row];
    
    self.backToParentButton.title = @"Return";
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
    [self passToFlite:self.listParent];
    
}

//used by handletap in Edit Mode
- (void) respondModifyRow: (NSIndexPath *) myIndexPath
{
    UITableViewCell *cell  = [self.tableView cellForRowAtIndexPath:myIndexPath];
    [self performSegueWithIdentifier: @"UpdateMainList" sender: cell];
}


// no longer used but this shows how to have and handle a second type of alertview
- (void) handleAskResetCheckMarks
{
    UIAlertView *alerttwo = [[UIAlertView alloc] initWithTitle:@"Do you want to reset " message:@" and review items already marked with checkmarks?" delegate:self cancelButtonTitle:@"No, SKIP them." otherButtonTitles:@"YES!",nil];
    alerttwo.tag = 2;
    [alerttwo show];
    return;
}

- (void) resetBeforeSlideShow
{
    [self.checkedItemKeys removeAllObjects];
    [self performSegueWithIdentifier: @"slideShow" sender: self];
}

- (void) resetSelectedCheckMarks: (NSMutableArray *) removeKeys
{
    NSNumber *key = [[NSNumber alloc ] init];
    
    for (key in removeKeys)
    {
        [self.checkedItemKeys removeObject:key];
    }
}

- (void) dontresetBeforeSlideShow
{
    [self performSegueWithIdentifier: @"slideShow" sender: self];
}


//this method should no longer get called - see handleTap gesture
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{


}


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
    
    //readListButton is the button at the bottom of the main view
    self.readListButton.layer.borderWidth = 2;
    self.readListButton.layer.cornerRadius = 10.0;
    self.readListButton.layer.borderColor = [UIColor blueColor].CGColor;

    self.skipCheckedItems = YES;
    self.allowSpeak = YES;
    self.allowListen = YES;
    [self setEditing: NO];
    self.waitForFlite = NO;
    self.editMode = @"Navigate";
    self.editModeButton.title = @"-> Edit";
    self.backToParentButton.title = @"Read Me";

    self.checkListItems = [[NSMutableArray alloc] init];
    self.speechCommands = [[NSMutableArray alloc] init];
    self.descendantKeys = [[NSMutableArray alloc] init];
    self.descendantItems = [[NSMutableArray alloc] init];
    self.unscheduledTDItems = [[NSMutableArray alloc] init];
    self.tobescheduledTDItems = [[NSMutableArray alloc] init];
    self.listOfLists = [[NSMutableArray alloc] init];
    self.listOfListNames = [[NSMutableArray alloc] init];
    self.unchecked_descendantKeys = [[NSMutableArray alloc] init];
    self.unchecked_descendantItems = [[NSMutableArray alloc] init];
    self.checkedItemKeys = [[NSMutableArray alloc] init];
    self.timeDelayItems = [[NSMutableArray alloc] init];
    NSString *docsDir;
    
    NSArray *dirPaths;
    
    self.listParent = @"MASTER LIST";
    self.listGrandParent = @"MASTER LIST";
    self.listParentKey = 0;
    self.listGrandParentKey = 0;
    self.listLabel.text = self.listParent;

    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSError *error;
    NSString *currentPath;
    currentPath = [filemgr currentDirectoryPath]; // this should be root
    NSString *distributedDB;
    
    distributedDB = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"checklist.db"];

    // Get the documents directory
    
    dirPaths = NSSearchPathForDirectoriesInDomains(
                NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @"checklist.db"]];



    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        if ([filemgr fileExistsAtPath: distributedDB])
        {
            if([filemgr copyItemAtPath:distributedDB toPath:_databasePath error:&error])
            {
                NSLog(@"%@", @"file copied");
            }
            else
            {
                NSLog(@"%@", error);
            }
        }
        else
        { NSLog(@"%@", @"distributed file not found");}
        
        
    }

    
    [self loadCurrentParentList];
    [self loadSpeechCommands];
    [self loadLanguageSet];
    [self startlanguageset];
    [self cellreloader];

//[self.tableView reloadData];
//    [self changelanguageset];
    
//start openears stuff
    
    
    [OpenEarsLogging startOpenEarsLogging];
    
    [self.openEarsEventsObserver setDelegate:self];
    
    [self passToFlite:@"WELCOME TO CHECK OUT LOUD"];

    
//NOTE when speech enabling a object, remember to add <OpenEarsEventsObserverDelegate> to the interface definition line in the .h file
    
//end of openears stuff
    
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.upSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.downSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.upSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    self.downSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    
    [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.upSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.downSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(appWillTerminate:)
                                                   name:UIApplicationWillTerminateNotification
                                                 object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Did appear"
//                                                    message:  [NSString stringWithFormat: @"Do What needs to be done!"]
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
    
    [self.openEarsEventsObserver setDelegate:self];
    [self cellreloader];
    [self checkForUnscheduledTDItems];// used when return from slideshow
    [self checkForScheduledItemsPastDue];
}

- (void)appWillEnterForegroundNotification
{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Did enter foreground"
//                                                    message:  [NSString stringWithFormat: @"Do What needs to be done!"]
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
    
    [self checkForScheduledItemsPastDue];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Memory warning received"
                                                    message:  [NSString stringWithFormat: @"Do Something!"]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
    [self.tableView setRowHeight:40.0f];
    return [self.checkListItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CheckListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    CheckListItem *checkItem = [self.checkListItems objectAtIndex:indexPath.row];
	NSString *paddedName = [NSString stringWithFormat: @" %@", checkItem.itemName];
	cell.textLabel.text = paddedName;
    cell.accessoryType = UITableViewCellAccessoryNone;
//    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.backgroundColor = [UIColor greenColor];
    cell.textLabel.layer.cornerRadius = 10.0;
    cell.textLabel.layer.masksToBounds = YES;
    cell.textLabel.layer.borderWidth = 1;
    cell.textLabel.layer.borderColor = [UIColor blueColor].CGColor;
    
    return cell;
    
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
        return UITableViewCellEditingStyleInsert;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
// Delete is enabled only for left swipe
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        
//        long row = [indexPath row];
//        CheckListItem *itemupdating  = self.checkListItems[row];
//        long aKey =  itemupdating.itemKey;
//        [self findAllDescendantKeysbyKey:aKey];
//        while ([self.descendantKeys count] > 0) {
//            long eachKey = [self.descendantKeys[0] longValue];
//            [self deleteOneByKey:eachKey];
//            [self.descendantKeys removeObject:self.descendantKeys[0]];
//        }
//        [self deleteOneByKey:aKey];
//        
//        [self.checkListItems removeObjectAtIndex:indexPath.row];
//
//        
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//
//    }
//    else
        if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        
            long row = [indexPath row];
            CheckListItem *itemInsertBelow  = self.checkListItems[row];
            long insertItemPriority =  itemInsertBelow.itemPriority + 1;
            long changedPriority = insertItemPriority + 2;
            //change the priorities of this and all subsequent items to +1
            int aCounter = row + 1;
            int theCount = [self.checkListItems count] ;
            while (aCounter < theCount)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = changedPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                changedPriority += 1;
            }
            self.addItemPriority = insertItemPriority; //this item now has updatePriority
            
            [self performSegueWithIdentifier: @"AddToList" sender: self];
//        }
    }
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    long priorrow = [fromIndexPath row];
    long newrow = [toIndexPath row];
    CheckListItem *item  = self.checkListItems[priorrow];// this is the item that moved
    
    
    if (newrow < priorrow) //item moved up
    {
        if (newrow > 0) // the new position is after the start of the list
        {
            long rowabove = newrow - 1;
            CheckListItem *itemAbove = self.checkListItems[rowabove];
            long aPriority = itemAbove.itemPriority + 1;

            item.itemPriority = aPriority;// 1 + the priority of the item above
            [self updatePriorityofItem:item];
            aPriority += 1;
            int aCounter = newrow;
            while (aCounter < priorrow)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = aPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                aPriority += 1;
            }
        }
        else // the new position is at the start of the list
        {
            int aPriority = 1;
            item.itemPriority = aPriority;
            [self updatePriorityofItem:item];
            aPriority += 1;
            int aCounter = 0;
            while (aCounter < priorrow)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = aPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                aPriority += 1;
            }
        }
    }
    else if (priorrow < newrow)
        // item moved down, renumber everything from prior point down to new point
    {
        if (priorrow > 0)
        {
            int aCounter = priorrow - 1;
            CheckListItem *itemAbove = self.checkListItems[aCounter];
            int aPriority = itemAbove.itemPriority + 1;
            aCounter = priorrow + 1;
            CheckListItem *itemBelow = self.checkListItems[aCounter];
            itemBelow.itemPriority = aPriority;
            [self updatePriorityofItem:itemBelow];
            aCounter += 1;
            aPriority += 1;
            while (aCounter < newrow + 1)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = aPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                aPriority += 1;
            }
            item.itemPriority = aPriority;
            [self updatePriorityofItem:item];
        }
        else //item moved was at beginning of list as item 0
        {
            int aCounter = 1;//what was item 1 is now priority 1
            CheckListItem *itemBelow = self.checkListItems[aCounter];
            int aPriority = 1;
            itemBelow.itemPriority = aPriority;
            [self updatePriorityofItem:itemBelow];
            aCounter += 1;
            aPriority += 1;
            while (aCounter < newrow + 1)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = aPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                aPriority += 1;
            }
            item.itemPriority = aPriority;
            [self updatePriorityofItem:item];
        }
    }
    [self loadCurrentParentList];
    [self cellreloader];
}


- (void) updatePriorityofItem: (CheckListItem *) item
{

    
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
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue isKindOfClass:[CustomSegue class]]) {
        // Set the start point for the animation to center of the button for the animation
        
        NSIndexPath *myIndexPath = [self.tableView
                                    indexPathForSelectedRow];
        
        CGRect myRect = [self.tableView rectForRowAtIndexPath:myIndexPath];
        
        CGPoint mypoint = CGPointMake(myRect.origin.x + (myRect.size.width / 2), myRect.origin.y + (myRect.size.height / 2));
        
        ((CustomSegue *)segue).originatingPoint = mypoint;
    }
    
    if ([[segue identifier] isEqualToString:@"AddToList"])
    {
        CPLAddListItemViewController *addViewController =
        [segue destinationViewController];
        
        addViewController.listParent = self.listParent;
        addViewController.defaultPriority = self.addItemPriority;
        
    }
    
    if ([[segue identifier] isEqualToString:@"UpdateMainList"])
    {
        CPLMUDViewController *updateViewController =
        [segue destinationViewController];
        
        long row = [self.tableView indexPathForCell:sender].row;
        self.updatingItem = self.checkListItems[row];
        
        CPLTimeDelayItem *aTDItem = [self returnTDItem:self.updatingItem];
        
        self.updatingItemCopied = [[CheckListItem alloc] init];
        self.updatingItemCopied.itemName = [self.updatingItem.itemName copy];
        self.updatingItemCopied.itemPriority = self.updatingItem.itemPriority;
        self.updatingItemCopied.itemKey = self.updatingItem.itemKey;
        self.updatingItemCopied.itemParent = [self.updatingItem.itemParent copy];
        self.updatingItemCopied.itemParentKey = self.updatingItem.itemParentKey;
        
        updateViewController.checkListItem = self.updatingItemCopied;
        updateViewController.timeDelayItem = aTDItem;
        
    }
    
    if ([[segue identifier] isEqualToString:@"slideShow"])
    {
        CPLSlideShowViewController *slideShowViewController =
        [segue destinationViewController];
        slideShowViewController.listOfLists = self.listOfLists;
        slideShowViewController.listOfListNames = self.listOfListNames;
        slideShowViewController.checkedItemKeys = self.checkedItemKeys;
        slideShowViewController.checkedItemsHaveBeenSkipped = self.checkedItemsHaveBeenSkipped;
        
//        slideShowViewController.checkListItems = self.descendantItems;
//        slideShowViewController.listParent = self.checkingItem.itemName;
        
        slideShowViewController.fliteController = self.fliteController;
        slideShowViewController.slt = self.slt;
        slideShowViewController.openEarsEventsObserver = self.openEarsEventsObserver;
        slideShowViewController.allowSpeak = self.allowSpeak;
        slideShowViewController.allowListen = self.allowListen;
        slideShowViewController.unscheduledTDItems = self.unscheduledTDItems;
        slideShowViewController.tobescheduledTDItems = self.tobescheduledTDItems;
//        slideShowViewController.sendingController = [segue sourceViewController];
    }
    
    if ([[segue identifier] isEqualToString:@"setPreferences"])
    {
        CPLPreferencesViewController *preferencesViewController =
        [segue destinationViewController];
        if (self.skipCheckedItems)
        {
            preferencesViewController.skipCheckedItems = YES;
        }
        else
        {
            preferencesViewController.skipCheckedItems = NO;
        }
        
        preferencesViewController.resetNow = NO;
        preferencesViewController.allowSpeak = self.allowSpeak;
        preferencesViewController.allowListen = self.allowListen;
        preferencesViewController.timeDelayItems = self.timeDelayItems;

        
    }

}



- (IBAction)unwindAddToList:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
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

        }
        

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

- (IBAction)unwindCancelUpdate:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
    [self cellreloader]; //[self.tableView reloadData];
}

- (IBAction)unwindCancelAdd:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
    [self cellreloader]; //[self.tableView reloadData];
}


- (IBAction) unwindCancelPreferences:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
}

- (IBAction) unwindChangePreferences:(UIStoryboardSegue *)segue  sender:(id)sender
{
    CPLPreferencesViewController *source = [segue sourceViewController];
    if (source.skipCheckedItems)
    {
        self.skipCheckedItems = YES;
    }
    else
    {
        self.skipCheckedItems = NO;
    }
    
    if (source.resetNow)
    {
        [self.checkedItemKeys removeAllObjects];
        [self cellreloader];
    }
    
    
    if (source.allowListen)
    {
        self.allowListen = YES;
        [self.pocketsphinxController resumeRecognition ];
    }
    else
    {
        self.allowListen = NO;
        [self.pocketsphinxController suspendRecognition ];
    }
    
    if (source.allowSpeak)
    {
        self.allowSpeak = YES;
    }
    else
    {
        self.allowSpeak = NO;
    }
    
    if (source.cancelScheduledItems)
    {
        [self cancelScheduledReminders];
    }
    
    
}


- (void) handleUpdateDelete: (CheckListItem *) anItem
{
    self.updatingItem = anItem;
    UIAlertView *alertone = [[UIAlertView alloc] initWithTitle:@"Are you Sure?" message:@"Do you want to delete item and all its descendants?" delegate:self cancelButtonTitle:@"No, Do NOT Delete." otherButtonTitles:@"Yes, Delete Now!",nil];
    alertone.tag = 1;
    [alertone show];

}

//no alert for delete is shown since changed to using edit mode
//no alert for reset checkmarks is shown; may use in future
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case 1:
            if (buttonIndex == 0) {
                NSLog(@"Do nothing");
            }
            else if (buttonIndex == 1) {
                NSLog(@"OK Tapped. Delete item and descendants");
                
                CheckListItem *itemupdating = self.updatingItem;
                [self.checkListItems removeObject:itemupdating];
                
                NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"itemPriority" ascending:YES];
                [self.checkListItems sortUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
                [self cellreloader]; //[self.tableView reloadData];
                long aKey =  itemupdating.itemKey;
                [self findAllDescendantKeysbyKey:aKey];
                while ([self.descendantKeys count] > 0) {
                    long eachKey = [self.descendantKeys[0] longValue];
                    [self deleteOneByKey:eachKey];
                    [self.descendantKeys removeObject:self.descendantKeys[0]];
                }
                [self deleteOneByKey:aKey];
            }
            break;
        case 2:
            if (buttonIndex == 0) {
                NSLog(@"Do not reset; show slide show");
                [self dontresetBeforeSlideShow];
            }
            else if (buttonIndex == 1) {
                NSLog(@"OK Tapped. Reset Check Marks, show slideshow");
                [self resetBeforeSlideShow];

            }
            break;
    }
    
}

- (IBAction)unwindUpdateMainList:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
    CPLMUDViewController *source = [segue sourceViewController];
    CheckListItem *item = source.checkListItem;
    CheckListItem *itemupdating = self.updatingItem;
    self.updatingDelete = source.setDelete;
    
    if (source.setDelete)
    {// confirm delete
        [self handleUpdateDelete:itemupdating];
    }
    else
    {
        [self.checkListItems removeObject:itemupdating];
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


- (IBAction)changeEditMode:(id)sender
{
    if ([self.editMode isEqual: @"Navigate"])
    {
        if ([self.checkListItems count] > 0)
        {
            self.editMode = @"Edit";
            self.backToParentButton.title = @"Read Me";
            [self setEditing: YES];
            self.editModeButton.title = @"-> Check";
            [self cellreloader];
            self.preferencesandModeName.titleLabel.text = @"Edit Mode";
        }
        else
        {
            self.editMode = @"Edit";
            self.editModeButton.title = @"-> Check";
            self.backToParentButton.title = @"Read Me";
             self.preferencesandModeName.titleLabel.text = @"Edit Mode";
            [self setEditing: YES];
            self.addItemPriority = 1;
            [self performSegueWithIdentifier: @"AddToList" sender: self];
            
        }
        
    }
    else if ([self.editMode isEqual: @"Edit"])
    {
        self.editMode = @"Navigate";
        self.preferencesandModeName.titleLabel.text = @"Check Mode";
        if ([self.listParent isEqual: @"MASTER LIST"])
        {
            self.backToParentButton.title = @"Read Me";
        }
        else
        {
            self.backToParentButton.title = @"Return";
        }
        [self setEditing: NO];
        self.editModeButton.title = @"-> Edit";
        [self cellreloader];
    }
}

- (IBAction)backToParent:(id)sender {
    if (![self.listParent isEqual: @"MASTER LIST"] && [self.editMode isEqual: @"Navigate"]) //
    {
        self.listParent = self.listGrandParent;
        self.listParentKey = self.listGrandParentKey;
        [self getGrandParent];
        self.listLabel.text = self.listParent;
        if ([self.listParent isEqual: @"MASTER LIST"])
        {
            self.backToParentButton.title = @"Read Me";
        }
            
        [self loadCurrentParentList];
        [self passToFlite:self.listParent];
       
        [self cellreloader]; //[self.tableView reloadData];
        
        [self passToFlite:self.listParent];
        [self loadSpeechCommands];
        [self loadLanguageSet];
        [self changelanguageset]; //changes to the recreated language model

    }
    else
    {[self showReadMe];}
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
    
- (IBAction)readListButton:(id)sender
{
    if (self.currentcellcount > 0  && [self.editMode isEqual: @"Navigate"])
    {
        [self slideShowForEntireList];

    }// end if currentcellcount > 0
}

-(void) showReadMe
{
    
CustomIOS7AlertView *alert = [[CustomIOS7AlertView alloc] init];

NSString *message = [NSString stringWithFormat:@"Instructions & Disclaimers\n%CSwipe right to start checking an item and its descendants. A \"slide show\"  will be created to \"wrap\" through the descendants - try the built in example PREFLIGHT to illustrate the \"wrap\". \n%CIn the \"slide show\" you may tap anywhere to indicate an item is done. You may also respond by saying \"check\", \"affirmative\", \"consider it done\". Say \"repeat\" or \"say again\" or swipe left to repeat an item. \n%CAny item or one of its descendants may schedule a time-delayed checklist w repetitions of itself and its descendants. See examples on BEFORE TAKEOFF list.\n%CModify this checklist w Edit mode. Swipe right in Edit mode to add. Swipe left in Edit mode to delete.\n%CWhen ambient noise causes unwanted results, voice commands can be disabled: see \"Preferences\" (gear symbol) for app options.\n%CSpeech recognition uses the OpenEars(R) engine.\n%CNot intended to replace any other required checklist. \n%CUse wisely and at your own risk.", (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022, (unichar) 0x2022  ];
    
[alert setContainerView:[self createAlertView:message]];

[alert show];
    
}

- (UIView *)createAlertView:(NSString *)msg
{
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 475)];
    demoView.layer.cornerRadius = 8.0f;
    demoView.layer.masksToBounds = YES;
    demoView.backgroundColor = [UIColor whiteColor];
    
    
    UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 0, 290, 475)];
    myTextView.text = msg;
    myTextView.font = [UIFont fontWithName:@"verdana" size:14];
    myTextView.editable = NO;

    [demoView addSubview:myTextView];
    
    return demoView;
}



- (void) cellreloader
{
    [self.tableView reloadData];
    self.currentrow = 0;
    self.currentcells = [self.tableView visibleCells]; //how to get array of all rows?
    self.currentcellpaths = [self.tableView indexPathsForVisibleRows];
    self.currentcellcount = [self.currentcells count];
    [self cellchecker];
}

- (void) cellchecker
{
    int aCounter = 0;
    while (aCounter < [self.currentcellpaths count])
    {
        NSIndexPath *myIndexpath = self.currentcellpaths[aCounter];
        UITableViewCell *cell  = self.currentcells[aCounter];
        long row = [myIndexpath row];
        CheckListItem *item  = self.checkListItems[row];
        long aKey =item.itemKey;
        NSNumber *aKeyNumber = [NSNumber numberWithLong:aKey];
        if ([self.checkedItemKeys containsObject:aKeyNumber])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        // if all descendents checked then check self
        [self findAllDescendantKeysbyKey:aKey];
        if ([self.descendantKeys count] > 0)
        {
            int innerCounter = 0;
            int checkedDescendants = 0;
            
            while (innerCounter < [self.descendantKeys count])
            {
                 NSNumber *anotherKeyNumber = [NSNumber numberWithLong:aKey];
                anotherKeyNumber = self.descendantKeys[innerCounter];
                if ([self.checkedItemKeys containsObject:anotherKeyNumber])
                {
                    checkedDescendants += 1;
                }
                innerCounter += 1;
            }
        
            if (checkedDescendants == [self.descendantKeys count])
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [self.checkedItemKeys addObject: aKeyNumber];
            }
        }
        aCounter += 1;
        
    }
}


- (void) handleTap:(UITapGestureRecognizer *)sender
{
    if (self.waitForFlite)
    {
        // do nothing
    }
    else
    {
        CGPoint location = [sender locationInView:self.tableView];
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
        
        if ([self.editMode isEqual: @"Navigate"] && swipedIndexPath)
        {
        [self respondSelectRow:swipedIndexPath];
        }
        
        if ([self.editMode isEqual: @"Edit"] && swipedIndexPath)
        {
            [self respondModifyRow:swipedIndexPath];
        }
    }
}


- (void) handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
       //check slide show for the current selected element and its descendants
    
        if (self.waitForFlite)
        {
            // do nothing
        }
        else if ([self.editMode isEqualToString:@"Navigate"])
        {
            CGPoint location = [sender locationInView:self.tableView];
            NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
            [self slideShowForSelectRow:swipedIndexPath];
        }
        else if ([self.editMode isEqualToString:@"Edit"])
        {
            CGPoint location = [sender locationInView:self.tableView];
            NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
            long row = [swipedIndexPath row];
            CheckListItem *itemInsertBelow  = self.checkListItems[row];
            long insertItemPriority =  itemInsertBelow.itemPriority + 1;
            long changedPriority = insertItemPriority + 2;
            //change the priorities of this and all subsequent items to +1
            int aCounter = row + 1;
            int theCount = [self.checkListItems count] ;
            while (aCounter < theCount)
            {
                CheckListItem *nextItem = self.checkListItems[aCounter];
                nextItem.itemPriority = changedPriority;
                [self updatePriorityofItem:nextItem];
                aCounter += 1;
                changedPriority += 1;
            }
            self.addItemPriority = insertItemPriority; //this item now has updatePriority
            
            [self performSegueWithIdentifier: @"AddToList" sender: self];
        }

    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        //check slide show for the current selected element and its descendants
        
        if (self.waitForFlite)
        {
            // do nothing
        }
        else if ([self.editMode isEqualToString:@"Edit"])
        {
            CGPoint location = [sender locationInView:self.tableView];
            NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
            long row = [swipedIndexPath row];
            CheckListItem *itemdeleting  = self.checkListItems[row];
            
            [self handleUpdateDelete:itemdeleting];
        }
        
    }
    
    
    

    
    if (sender.direction == UISwipeGestureRecognizerDirectionDown)
    {
        //check the entire list and their descendants
    }
}

- (void) fliteDidFinishSpeaking {
    self.waitForFlite = NO;

}

- (void) passToFlite: (NSString *) sayThis
{
    if (self.allowSpeak)
    {
        self.waitForFlite = YES;
        [self.fliteController say:sayThis withVoice:self.slt];}
}

@end

//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flite Finished"
//                                                    message:  [NSString stringWithFormat: @"Resume"]
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
