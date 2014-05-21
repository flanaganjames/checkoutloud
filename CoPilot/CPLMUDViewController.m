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
    
    
    _itemPriority.text = [NSString stringWithFormat: @"%ld", self.checkListItem.itemPriority];
    self.itemPriority.keyboardType = UIKeyboardTypeDecimalPad;
    self.deleteSwitch.on = NO;
    self.setDelete = NO;
    self.delaySeconds.keyboardType = UIKeyboardTypeDecimalPad;
    self.delayHours.keyboardType = UIKeyboardTypeDecimalPad;
    self.delayMinutes.keyboardType = UIKeyboardTypeDecimalPad;
    self.repeatTimes.keyboardType = UIKeyboardTypeDecimalPad;
    

    if ( self.timeDelayItem)
    {
        self.delaySeconds.text = [NSString stringWithFormat:@"%d", self.timeDelayItem.delaySeconds];
        self.delayMinutes.text = [NSString stringWithFormat:@"%d",  self.timeDelayItem.delayMinutes];
        self.delayHours.text = [NSString stringWithFormat:@"%d",  self.timeDelayItem.delayHours];
        self.repeatTimes.text = [NSString stringWithFormat:@"%d",  self.timeDelayItem.repeatNumber];
        _itemName.text =  self.timeDelayItem.itemName;
    }
    else
    {
        self.delaySeconds.text = @"0";
        self.delayMinutes.text = @"0";
        self.delayHours.text = @"0";
        self.repeatTimes.text = @"1";
        _itemName.text = self.checkListItem.itemName;
        
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.itemName.text.length > 0)
    {
        if (self.itemPriority.text.length > 0) {
            self.checkListItem.itemPriority = [self.itemPriority.text longLongValue];}
        
        NSString *buildName = [[NSString alloc] init];
        buildName = [self.itemName.text uppercaseString];
        
        //if any non-zero delay then build the name
        if (![self.delaySeconds.text isEqual: @"0"] | ![self.delayMinutes.text isEqual: @"0"] | ![self.delayHours.text isEqual: @"0"])
        {
            buildName = [NSString stringWithFormat:@"%@ | td-%@h%@m%@s%@rpt", buildName, self.delayHours.text, self.delayMinutes.text, self.delaySeconds.text, self.repeatTimes.text];
        }
        
        self.checkListItem.itemName = buildName;
        
        if (self.deleteSwitch.on)
        {self.setDelete = YES;};
    }
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
