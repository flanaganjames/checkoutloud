//
//  CPLSlideShowViewController.m
//  CheckOutLoud
//
//  Created by James Flanagan on 4/27/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLSlideShowViewController.h"

@interface CPLSlideShowViewController ()

@end

@implementation CPLSlideShowViewController

//start openears stuff
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    
    if ([hypothesis  isEqual: @" CONSIDER IT DONE"] |[hypothesis  isEqual: @" CHECK"] |[hypothesis  isEqual: @" AFFIRMATIVE"])
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"heard check Name"
        message:[NSString stringWithFormat: @"%@", @"no message"]
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        
        
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
    
    _listName.text = self.listParent;
    _listItemName.text = self.currentCheckListItem.itemName;
    _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
    NSString *sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listName.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
    [self.fliteController say:sayThis withVoice:self.slt];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    

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
    _listName.text = self.listParent;
    CheckListItem *item = self.currentCheckListItem;
    _listItemName.text = item.itemName;
    _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];
    NSString *sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listName.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
    [self.fliteController say:sayThis withVoice:self.slt];
}

- (void) nextSlide
{  if (self.currentrow < [self.checkListItems count] - 1)
    {
        self.currentrow += 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
        _listItemName.text = self.currentCheckListItem.itemName;
        _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
        NSString *sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        [self.fliteController say:sayThis withVoice:self.slt];
    }
    else
    {
        if (self.currentlist < [self.listOfLists count] - 1)
        {
            self.currentlist += 1;
            self.currentrow = 0;
            self.checkListItems = self.listOfLists[self.currentlist];
            self.listParent = self.listOfListNames[self.currentlist];
            _listName.text = self.listParent;
            CheckListItem *item = self.checkListItems[self.currentrow];
            _listItemName.text = item.itemName;
            _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];
            NSString *sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listName.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
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
        NSString *sayThis = [NSString stringWithFormat: @"item %ld is %@", self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
        [self.fliteController say:sayThis withVoice:self.slt];
    }
    else
    {
        if (self.currentlist > 0)
        {
             self.currentlist -= 1;
            self.currentrow = 0;
            self.checkListItems = self.listOfLists[self.currentlist];
            self.listParent = self.listOfListNames[self.currentlist];
            _listName.text = self.listParent;
            CheckListItem *item = self.checkListItems[self.currentrow];
            _listItemName.text = item.itemName;
            _listItemNumber.text = [NSString stringWithFormat: @"%ld", item.itemPriority];
            NSString *sayThis = [NSString stringWithFormat: @"Checking list named \'%@\'. item %ld is %@", self.listName.text, self.currentCheckListItem.itemPriority, self.currentCheckListItem.itemName ];
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
