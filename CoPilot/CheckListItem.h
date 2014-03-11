//
//  CheckListItem.h
//  CoPilot
//
//  Created by James Flanagan on 3/9/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CheckListItem : NSObject
@property NSString *itemName;
@property long itemPriority;
@property NSString *itemParent;
@property long itemKey;
@property BOOL completed;
@end
