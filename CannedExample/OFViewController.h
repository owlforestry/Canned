//
//  OFViewController.h
//  Canned
//
//  Created by Mikko Kokkonen on 2/22/12.
//  Copyright (c) 2012 Owl Forestry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OFViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
- (IBAction)fetchData:(id)sender;

@end
