//
//  CPLSUDViewController.m
//  CoPilot
//
//  Created by James Flanagan on 3/16/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLSUDViewController.h"
#import "CheckListItem.h"

@interface CPLSUDViewController ()

@end

@implementation CPLSUDViewController

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
    
    _itemName.text = self.checkListItem.itemName;
    _itemPriority.text = [NSString stringWithFormat: @"%ld", self.checkListItem.itemPriority];
    self.deleteSwitch.on = NO;
    self.setDelete = NO;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.itemName.text.length > 0) {
        self.checkListItem.itemName = self.itemName.text;}
    
    if (self.itemPriority.text.length > 0) {
        self.checkListItem.itemPriority = [self.itemPriority.text longLongValue];}
    
    if (self.deleteSwitch.on)
    {self.setDelete = YES;};
}

@end
