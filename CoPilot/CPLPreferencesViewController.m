//
//  CPLPreferencesViewController.m
//  CheckOutLoud
//
//  Created by James Flanagan on 5/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLPreferencesViewController.h"

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
    self.enabledragSwitch.on = NO;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
