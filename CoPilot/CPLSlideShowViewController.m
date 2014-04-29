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
    self.currentrow = 0;
    self.currentCheckListItem = [[CheckListItem alloc] init];
    self.currentCheckListItem = self.checkListItems[self.currentrow];
    
    _listName.text = self.listParent;
    _listItemName.text = self.currentCheckListItem.itemName;
    _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
}

- (void) nextSlide
{  if (self.currentrow < [self.checkListItems count] - 1)
    {
        self.currentrow += 1;
        self.currentCheckListItem = self.checkListItems[self.currentrow];
        _listItemName.text = self.currentCheckListItem.itemName;
        _listItemNumber.text = [NSString stringWithFormat: @"%ld", self.currentCheckListItem.itemPriority];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self nextSlide];
    [super touchesBegan:touches withEvent:event];
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
