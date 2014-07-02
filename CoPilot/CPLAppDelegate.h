//
//  CPLAppDelegate.h
//  CoPilot
//
//  Created by James Flanagan on 3/8/14.
//  Copyright (c) 2014 James Flanagan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPLTableViewController.h"

@interface CPLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property CPLTableViewController *myController;
@end
