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
    self.setDelete = NO;
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
        self.checkListItem.itemName = [self.itemName.text uppercaseString];}
    
    if (self.itemPriority.text.length > 0) {
        self.checkListItem.itemPriority = [self.itemPriority.text longLongValue];}
    
    if (self.deleteSwitch.on)
    {self.setDelete = YES;};
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
