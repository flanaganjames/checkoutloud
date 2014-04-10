//
//  CPLTableViewCell.m
//  CheckOutLoud
//
//  Created by James Flanagan on 4/9/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import "CPLTableViewCell.h"

@implementation CPLTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
