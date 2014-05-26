//
//  CPLPreferencesViewController.m
//  CheckOutLoud
//
//  Created by James Flanagan on 5/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLPreferencesViewController.h"
#import "CPLViewScheduledItemsTableViewController.h"

@interface CPLPreferencesViewController ()

@end

@implementation CPLPreferencesViewController

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
    
    if (self.skipCheckedItems)
    {
        self.skipCheckedSwitch.on = YES;
    }
    else
    {
        self.skipCheckedSwitch.on = NO;
    }
    
    self.resetCheckedNow.on = NO;
    self.savecurrentorderSwitch.on = NO;
    self.cancelScheduledSwitch.on = NO;
    self.cancelScheduledItems = NO;
    self.saveNow = NO;
    if (self.allowSpeak)
    {
        self.speakSwitch.on = YES;
    }
    else
    {
        self.speakSwitch.on = NO;
    }
    
    if (self.allowListen)
    {
        self.listenSwitch.on = YES;
    }
    else
    {
        self.listenSwitch.on = NO;
    }
    if (self.allowDragReorder)
    {
        self.enabledragSwitch.on = YES;
    }
    else
    {
        self.enabledragSwitch.on = NO;
    }
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showScheduledItems"])
    {
        CPLViewScheduledItemsTableViewController *scheduledItemsController =
        [segue destinationViewController];
        
        scheduledItemsController.timeDelayItems = self.timeDelayItems;
    }
    else
    {
        if (self.skipCheckedSwitch.on)
        {self.skipCheckedItems = YES;}
        else
        {self.skipCheckedItems = NO;}
        
        if (self.resetCheckedNow.on)
        {self.resetNow = YES;}
        else
        {self.resetNow = NO;}
        
        if (self.savecurrentorderSwitch.on)
        {self.saveNow = YES;}
        else
        {self.saveNow = NO;}
        
        if (self.speakSwitch.on)
        {
            self.allowSpeak = YES;
        }
        else
        {
            self.allowSpeak = NO;
        }
        
        if (self.listenSwitch.on)
        {
            self.allowListen = YES;
        }
        else
        {
            self.allowListen = NO;
        }
        if (self.cancelScheduledSwitch.on)
        {
            self.cancelScheduledItems = YES;
        }
        if (self.enabledragSwitch.on)
        {
            self.allowDragReorder = YES;
        }
        else
        {
            self.allowDragReorder = NO;
        }
        if (self.savecurrentorderSwitch.on)
        {
            self.saveNow = YES;
        }

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindViewScheduledItems:(UIStoryboardSegue *)segue  sender:(id)sender
{
    
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
