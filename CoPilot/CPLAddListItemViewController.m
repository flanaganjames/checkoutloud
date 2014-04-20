//
//  CPLAddListItemViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/13/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLAddListItemViewController.h"

@interface CPLAddListItemViewController ()

@end

@implementation CPLAddListItemViewController

//start openears stuff
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    
    if ([hypothesis  isEqual: @"SAVE"])
    {
        [self performSegueWithIdentifier: @"unwindAddToList" sender: self];
    }
    
}
//end openears stuff

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.itemName.text.length > 0) {
       	self.checkListItem = [[CheckListItem alloc] init];
        
        self.checkListItem.itemName = [self.itemName.text uppercaseString];
        self.checkListItem.itemPriority = [self.itemPriority.text longLongValue];
    }
        //
}
        


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //start openears stuff
    [self.openEarsEventsObserver setDelegate:self];
    self.itemPriority.text = [NSString stringWithFormat:@"%d", self.defaultPriority];

    //end of openears stuff
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction) textFieldReturn:(id)sender{
    [sender resignFirstResponder];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([_itemPriority isFirstResponder] && [touch view] != _itemPriority) {
        [_itemPriority resignFirstResponder];
    }
    if ([_itemName isFirstResponder] && [touch view] != _itemName) {
        [_itemName resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}
@end
