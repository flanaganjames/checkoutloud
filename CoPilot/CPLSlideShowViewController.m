//
//  CPLSlideShowViewController.m
//  CheckOutLoud
//
//  Created by James Flanagan on 4/27/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLSlideShowViewController.h"

@interface CPLSlideShowViewController ()
@property NSMutableArray *parentHierarchy;
@property NSString *removingParent;
@property int fliteWaitInterval;
@end

@implementation CPLSlideShowViewController

//start openears stuff
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)rawhypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID

{
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", rawhypothesis, recognitionScore, utteranceID);
    
    NSString *hypothesis = [NSString stringWithFormat: @" %@", rawhypothesis];
    
    if ([hypothesis  isEqual: @" CONSIDER IT DONE"] |[hypothesis  isEqual: @" CHECK"] |[hypothesis  isEqual: @" AFFIRMATIVE"])
    {

        
        
        [self nextSlideAfterWait];
    }
    
    if ([hypothesis  isEqual: @" SAY AGAIN"] | [hypothesis  isEqual: @" REPEAT"])
    {
        [self previousSlideAfterWait];
    }
    
}

- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"SlideShow Pocketsphinx has resumed recognition.");
    


}

//end openears stuff

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) startOneList
{     self.currentrow = 0;
    
    [self setParentHierarchyText];
    //_listParentHierarchy.text = self.listParent;
    _listItemName.text = self.currentCheckListItem.itemName;
    _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
    NSString *sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listParentHierarchy.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
    [self passToFlite:sayThis];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.removingParent = @"";
    
    self.waitForFlite =NO;
    
    if (self.checkedItemsHaveBeenSkipped)
    {
        self.warningText.text =@"WARNING: previously checked items will be skipped - per settings";
    }
    
    
    self.parentHierarchy = [[NSMutableArray alloc] init];
    self.currentCheckListItem = [[CheckListItem alloc] init];
    //start openears stuff
    [self.openEarsEventsObserver setDelegate:self];
    //end of openears stuff
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.upSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.upSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    
    [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.upSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    self.currentlist = 0;
    self.currentrow = 0;
    
    self.checkListItems = self.listOfLists[self.currentlist];
    self.currentCheckListItem = self.checkListItems[self.currentrow];
    self.listParent = self.listOfListNames[self.currentlist];
    [self.parentHierarchy removeAllObjects];
    [self.parentHierarchy addObject:self.listParent];
    
    _listParentHierarchy.font = [UIFont systemFontOfSize:20.0];
    
    [self setParentHierarchyText];
   // _listParentHierarchy.text = self.listParent;
    CheckListItem *item = self.currentCheckListItem;
    _listItemName.text = item.itemName;
    _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];

    NSString *sayThis = @"";
    if (self.currentCheckListItem.itemPriority == 0)
    {
        sayThis = [NSString stringWithFormat: @" Checking list named \'%@\'.  item %@ has children ", self.listParentHierarchy.text, self.currentCheckListItem.itemName ];
        [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
        [self setParentHierarchyText];
        _listItemNumber.text =  @"Begin children of ...";
    }
    else
    {
        sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listParentHierarchy.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
    }
    [self passToFlite:sayThis];
    
    //if first item is resuming a checklist immeidately after some TD items move the TD items to the tobscheduled array
    [self moveifpassScheduledItem:self.currentCheckListItem];
}

- (void) moveifpassScheduledItem: (CheckListItem *) aCLItem
{
    NSMutableArray *anArray = [[NSMutableArray alloc] init];
    
    CPLTimeDelayItem *aTDItem = [[CPLTimeDelayItem alloc] init];
    for (aTDItem in self.unscheduledTDItems)
    {
        if (aTDItem.itemPriority < aCLItem.itemPriority)
            //once the slide show has passed the priority position of a TDItem in unscheduled move that TDItem from unshceuled to tobescheduled
        {
            [self.tobescheduledTDItems addObject:aTDItem];
        }
        else
        {
            [anArray addObject: aTDItem];
        }
    }
    self.unscheduledTDItems = anArray;
}

- (void) moveremainingScheduledItem
{
    CPLTimeDelayItem *aTDItem = [[CPLTimeDelayItem alloc] init];
    for (aTDItem in self.unscheduledTDItems)
    {
            [self.tobescheduledTDItems addObject:aTDItem];
    }
    [self.unscheduledTDItems removeAllObjects];
}

- (void) nextSlideAfterWait
{
    if (self.waitForFlite)
    {
        [self performSelector:@selector(nextSlideAfterWait) withObject:nil afterDelay: 1]; // try every second until waitForFlite is NO;
    }
    else
    {
        [self nextSlide];//then go to next slide
    }
}

- (void) nextSlide
{
    
    CheckListItem *anItem = self.checkListItems[self.currentrow];

    
    NSNumber *aKeyNumber = [NSNumber numberWithLong:anItem.itemKey];
    [self.checkedItemKeys addObject: aKeyNumber];
    
    if (anItem.itemPriority == -1) //if item from which came is a "0"
    {
        [self.parentHierarchy removeObject:anItem.itemName];
        self.removingParent = @"";
    }
    [self setParentHierarchyText];
    
    
    if (self.currentrow < [self.checkListItems count] - 1)
    {
        self.currentrow += 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
        [self moveifpassScheduledItem:self.currentCheckListItem];
        _listItemName.text = self.currentCheckListItem.itemName;
        _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
        NSString *sayThis = @"";
        if (self.currentCheckListItem.itemPriority == 0)
        {
        sayThis = [NSString stringWithFormat: @"item %@ has children ",  self.currentCheckListItem.itemName ];

        [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
        [self setParentHierarchyText];
        _listItemNumber.text =  @"Begin children of ...";
        }
        else if (self.currentCheckListItem.itemPriority == -1)
        {
         sayThis = [NSString stringWithFormat: @"end of children of item %@",  self.currentCheckListItem.itemName ];
        self.removingParent = self.currentCheckListItem.itemName;
        [self setParentHierarchyText];
        _listItemNumber.text =  @"End children of ...";
        }
        else
        {
        sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        }
        [self passToFlite:sayThis];
    }
    else // go to the next list
    {
        if (self.currentlist < [self.listOfLists count] - 1)
        {
            self.currentlist += 1;
            self.currentrow = 0;
            self.checkListItems = self.listOfLists[self.currentlist];
            self.currentCheckListItem = self.checkListItems[self.currentrow];
            self.listParent = self.listOfListNames[self.currentlist];
            [self.parentHierarchy removeAllObjects];
            [self.parentHierarchy addObject:self.listParent];
            [self setParentHierarchyText];
            //_listParentHierarchy.text = self.listParent;
            CheckListItem *item = self.currentCheckListItem;
            _listItemName.text = item.itemName;
            _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];
            NSString *sayThis = @"";
            if (self.currentCheckListItem.itemPriority == 0)
            {
                sayThis = [NSString stringWithFormat: @" Checking list named \'%@\'.  item %@ has children ", self.listParentHierarchy.text, self.currentCheckListItem.itemName ];
                [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
                [self setParentHierarchyText];
                _listItemNumber.text =  @"Begin children of ...";
            }
            else
            {
                sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listParentHierarchy.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
            }
            [self passToFlite:sayThis];
        }
        else
        {
        //perform unwind programmatically
            NSString *sayThis = @"check list completed";
            [self passToFlite: sayThis];
        // if arrive at end of list move all remaining unscheduled TD items to the tobescheduled array
            [self moveremainingScheduledItem];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void) previousSlideAfterWait
{
    if (self.waitForFlite)
    {
        [self performSelector:@selector(nextSlideAfterWait) withObject:nil afterDelay: 1]; // try every second until waitForFlite is NO;
    }
    else
    {
        [self previousSlide];//then go to next slide
    }
}

- (void) previousSlide
{
    CheckListItem *anItem = self.checkListItems[self.currentrow];
    
    NSNumber *aKeyNumber = [NSNumber numberWithLong:anItem.itemKey];
    [self.checkedItemKeys removeObject: aKeyNumber];
    
    if (anItem.itemPriority == 0) //if item from which came is a "0"
    {
        [self.parentHierarchy removeObject:anItem.itemName];
        self.removingParent = @"";
    }
    [self setParentHierarchyText];
    
    if (self.currentrow > 0)
    {
        self.currentrow -= 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
        _listItemName.text = self.currentCheckListItem.itemName;
        _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
        NSString *sayThis = @"";
        if (self.currentCheckListItem.itemPriority == 0)
        {
            sayThis = [NSString stringWithFormat: @"item %@ has children ",  self.currentCheckListItem.itemName ];
            _listItemNumber.text =  @"Begin children of ...";
        }
        else if (self.currentCheckListItem.itemPriority == -1)
        {
            sayThis = [NSString stringWithFormat: @"end of children of item %@",  self.currentCheckListItem.itemName ];
            
            [self.parentHierarchy addObject:self.currentCheckListItem.itemName];

            [self setParentHierarchyText];
            _listItemNumber.text =  @"End children of ...";
        }
        else
        {
            sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        }
        [self passToFlite: sayThis];
    }
    else
    {
        if (self.currentlist > 0)
        {
             self.currentlist -= 1;
            self.currentrow = 0;
            self.checkListItems = self.listOfLists[self.currentlist];
            self.currentCheckListItem = self.checkListItems[self.currentrow];
            self.listParent = self.listOfListNames[self.currentlist];
            [self.parentHierarchy removeAllObjects];
            [self.parentHierarchy addObject:self.listParent];
            [self setParentHierarchyText];
           // _listParentHierarchy.text = self.listParent;
            CheckListItem *item = self.currentCheckListItem;
            _listItemName.text = item.itemName;
            _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];
            NSString *sayThis = @"";
            if (self.currentCheckListItem.itemPriority == 0)
            {
                sayThis = [NSString stringWithFormat: @" Checking list named \'%@\'.  item %@ has children ", self.listParentHierarchy.text, self.currentCheckListItem.itemName ];
                
                [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
                [self setParentHierarchyText];
                _listItemNumber.text =  @"Begin children of ...";
            }
            else
            {
                sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listParentHierarchy.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
            }
            [self passToFlite: sayThis];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) handleTap:(UITapGestureRecognizer *)sender
{
    //[self nextSlideAfterWait];
    if (self.waitForFlite)
    {
        // do nothing
    }
    else
    {
        [self nextSlide];
    }
}

- (void) handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        //[self previousSlideAfterWait];
        if (self.waitForFlite)
        {
            // do nothing
        }
        else
        {
            [self previousSlide];
        }
    
    }
    
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
       // [self nextSlideAfterWait];
        if (self.waitForFlite)
        {
            // do nothing
        }
        else
        {
            [self nextSlide];
        }
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionUp)
    {
        [self handleQuitConfirm];
    }
}

- (void) handleQuitConfirm
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you Sure?" message:@"Do you want to quit checking this list?" delegate:self cancelButtonTitle:@"No, Do NOT quit." otherButtonTitles:@"Yes, Quit Now!",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Do nothing");
    }
    else if (buttonIndex == 1) {
        NSLog(@"OK Tapped. Quit checking this list");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) setParentHierarchyText
{
    
    _listParentHierarchy.text = [NSString stringWithFormat: @"%@", self.parentHierarchy[0] ];
    int aCounter = 1;
    NSString *tabCounter = @"";
    NSString *aTabChar = @"\t";
    
    while (aCounter < [self.parentHierarchy count])
    {
        tabCounter = [NSString stringWithFormat: @"%@%@", tabCounter, aTabChar];
        
        _listParentHierarchy.text = [NSString stringWithFormat: @"%@\n%@%@", _listParentHierarchy.text, tabCounter, self.parentHierarchy[aCounter] ];
        aCounter += 1;
    }
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)quitChecking:(id)sender {
    [self handleQuitConfirm];
}


- (void) fliteDidFinishSpeaking {
     self.waitForFlite = NO;
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flite Finished"
//                                                    message:  [NSString stringWithFormat: @"Resume"]
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
}

- (void) fliteDidStartSpeaking
{
    self.waitForFlite = YES;
}


- (void) passToFlite: (NSString *) sayThis
{
    if (self.allowSpeak)
    {
        [self.fliteController say:sayThis withVoice:self.slt];
    }
}
@end
