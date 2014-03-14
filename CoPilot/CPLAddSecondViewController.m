//
//  CPLAddSecondViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/13/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLAddSecondViewController.h"

@interface CPLAddSecondViewController ()

@end

@implementation CPLAddSecondViewController


//start openears stuff
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    
    if ([hypothesis  isEqual: @"SAVE"])
    {
        [self performSegueWithIdentifier: @"unwindAddToSecondList" sender: self];
    }
    
}
//end openears stuff

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.itemName.text.length > 0) {
       	self.checkListItem = [[CheckListItem alloc] init];
        
        self.checkListItem.itemName = self.itemName.text;
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
    //end of openears stuff
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
