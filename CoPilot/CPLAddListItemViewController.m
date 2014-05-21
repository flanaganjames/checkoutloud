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

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.itemName.text.length > 0)
    {
       	self.checkListItem = [[CheckListItem alloc] init];
        
        NSString *buildName = [[NSString alloc] init];
        buildName = [self.itemName.text uppercaseString];
        
        //if any non-zero delay then build the name
        if (![self.delaySeconds.text isEqual: @"0"] | ![self.delayMinutes.text isEqual: @"0"] | ![self.delayHours.text isEqual: @"0"])
        {
            buildName = [NSString stringWithFormat:@"%@ | td-%@h%@m%@s%@rpt", buildName, self.delayHours.text, self.delayMinutes.text, self.delaySeconds.text, self.repeatTimes.text];
        }
        
        
        self.checkListItem.itemName = buildName;
        self.checkListItem.itemPriority = [self.itemPriority.text longLongValue];
        
    }
    
    
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

    self.itemPriority.text = [NSString stringWithFormat:@"%d", self.defaultPriority];
    self.itemPriority.keyboardType = UIKeyboardTypeDecimalPad;
    self.delaySeconds.keyboardType = UIKeyboardTypeDecimalPad;
    self.delayHours.keyboardType = UIKeyboardTypeDecimalPad;
    self.delayMinutes.keyboardType = UIKeyboardTypeDecimalPad;
    self.repeatTimes.keyboardType = UIKeyboardTypeDecimalPad;

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
    if ([_delaySeconds isFirstResponder] && [touch view] != _delaySeconds) {
        [_delaySeconds resignFirstResponder];
    }
    if ([_delayMinutes isFirstResponder] && [touch view] != _delayMinutes) {
        [_delayMinutes resignFirstResponder];
    }
    if ([_delayHours isFirstResponder] && [touch view] != _delayHours) {
        [_delayHours resignFirstResponder];
    }
    if ([_repeatTimes isFirstResponder] && [touch view] != _repeatTimes) {
        [_repeatTimes resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}
@end
