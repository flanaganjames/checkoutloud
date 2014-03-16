//
//  CPLMUDViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/15/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLMUDViewController.h"
#import "CheckListItem.h"

@interface CPLMUDViewController ()

@end

@implementation CPLMUDViewController

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
    
    _itemName.text = self.checkListItem.itemName;
    _itemPriority.text = [NSString stringWithFormat: @"%ld", self.checkListItem.itemPriority];
    self.deleteSwitch.on = NO;
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