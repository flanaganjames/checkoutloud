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
@end

@implementation CPLSlideShowViewController

//start openears stuff
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)rawhypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID

{
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", rawhypothesis, recognitionScore, utteranceID);
    
    NSString *hypothesis = [NSString stringWithFormat: @" %@", rawhypothesis];
    
    if ([hypothesis  isEqual: @" CONSIDER IT DONE"] |[hypothesis  isEqual: @" CHECK"] |[hypothesis  isEqual: @" AFFIRMATIVE"])
    {

        
        
        [self nextSlide];
    }
    
    if ([hypothesis  isEqual: @" SAY AGAIN"] | [hypothesis  isEqual: @" REPEAT"])
    {
        [self previousSlide];
    }
    
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
    [self.fliteController say:sayThis withVoice:self.slt];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    [self.fliteController say:sayThis withVoice:self.slt];
}

- (void) nextSlide
{  if (self.currentrow < [self.checkListItems count] - 1)
    {
        self.currentrow += 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
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
        [self.parentHierarchy removeObject:self.currentCheckListItem.itemName];
        [self setParentHierarchyText];
        _listItemNumber.text =  @"End children of ...";
        }
        else
        {
        sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        }
        [self.fliteController say:sayThis withVoice:self.slt];
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

            [self.fliteController say:sayThis withVoice:self.slt];
        }
        else
        {
        //perform unwind programmatically
        [self.fliteController say:@"check list completed" withVoice:self.slt];
        [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void) previousSlide
{  if (self.currentrow > 0)
    {
        self.currentrow -= 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
        _listItemName.text = self.currentCheckListItem.itemName;
        _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
        NSString *sayThis = @"";
        if (self.currentCheckListItem.itemPriority == 0)
        {
            sayThis = [NSString stringWithFormat: @"item %@ has children ",  self.currentCheckListItem.itemName ];
           // [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
           // [self setParentHierarchyText];
            _listItemNumber.text =  @"Begin children of ...";
        }
        else if (self.currentCheckListItem.itemPriority == -1)
        {
            sayThis = [NSString stringWithFormat: @"end of children of item %@",  self.currentCheckListItem.itemName ];
            CheckListItem *anItem = self.checkListItems[self.currentrow + 1];
            [self.parentHierarchy removeObject:anItem.itemName];
            [self.parentHierarchy addObject:self.currentCheckListItem.itemName];
            [self setParentHierarchyText];
            _listItemNumber.text =  @"End children of ...";
        }
        else
        {
            sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        }
        [self.fliteController say:sayThis withVoice:self.slt];
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

            [self.fliteController say:sayThis withVoice:self.slt];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    [self nextSlide];
//    [super touchesBegan:touches withEvent:event];
//}

- (void) handleTap:(UITapGestureRecognizer *)sender
{
    [self nextSlide];
}

- (void) handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        [self previousSlide];
        //[self nextSlide];
    }
    
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
       // [self previousSlide];
        [self nextSlide];
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
    while (aCounter < [self.parentHierarchy count])
    {
        _listParentHierarchy.text = [NSString stringWithFormat: @"%@\n%@", _listParentHierarchy.text, self.parentHierarchy[aCounter] ];
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

@end
