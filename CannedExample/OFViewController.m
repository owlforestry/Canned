//
//  OFViewController.m
//  Canned
//
//  Created by Mikko Kokkonen on 2/22/12.
//  Copyright (c) 2012 Owl Forestry. All rights reserved.
//

#import "OFViewController.h"
#import "OFCanned.h"

@interface OFViewController ()

@end

@implementation OFViewController
@synthesize dataLabel;
@synthesize timeLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setDataLabel:nil];
    [self setTimeLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)fetchData:(id)sender {
    // Fetch example domains
    [OFCanned useCan:@"iana" withMatching:kOFMatchingWithURIAndMethod];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSLog(@"Headers: %@", ((NSHTTPURLResponse *)response).allHeaderFields);
        NSLog(@"Data: %@", [NSString stringWithUTF8String:data.bytes]);
        
        self.dataLabel.text = @"Got reply from iana.";
    }];
}
@end
