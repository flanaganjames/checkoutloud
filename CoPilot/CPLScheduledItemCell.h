//
//  CPLScheduledItemCell.h
//  CheckOutLoud
//
//  Created by James Flanagan on 5/24/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPLScheduledItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *itemName;
@property (weak, nonatomic) IBOutlet UITextField *timeDue;

@end
