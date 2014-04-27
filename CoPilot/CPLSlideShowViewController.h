//
//  CPLSlideShowViewController.h
//  CheckOutLoud
//
//  Created by James Flanagan on 4/27/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPLSlideShowViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *listName;

@property (weak, nonatomic) IBOutlet UITextField *listItemNumber;
@property (weak, nonatomic) IBOutlet UITextField *listItemName;
@property (weak, nonatomic) IBOutlet UIView *clickView;

@end
