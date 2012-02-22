//
//  OFCannedURLProtocol.h
//  Canned
//
//  Created by Mikko Kokkonen on 2/22/12.
//  Copyright (c) 2012 Owl Forestry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OFCanned : NSURLProtocol

typedef enum {
    kMatchByDefault,
    kMatchByURIAndMethod,
} OFCanMatcher;

/** Set currently active Can.
 */
+ (void)setCan:(NSString *)can;

/**
 Starts capturing requests and if request can not be founded it is canned 
 for the future purposes.
 If the can can be found it is returned instead of the axtual request.
 */
+ (void)catchAndCan;

+ (void)catchWithMatcher:(OFCanMatcher)matcher;

- (id)init;
+ (id)sharedInstance;

@end
