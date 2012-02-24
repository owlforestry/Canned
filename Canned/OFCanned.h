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
    kOFMatchingWithURIAndMethod,
    kOFMatchingWithBody,
} OFRequestMatching;

/** @section Management */
/** Starts canned responses for HTTP traffic.
 After calling this method, by default all HTTP request will be canned.
 If the request has not been canned before, it will be performed for real
 and the response is canned.
 If the canned response can be found, it will be returned immediatly without
 ever connecting to real server.
 */
+ (void)start;

/** Removes canned protocol from the URLProtocol stack.
 Calling this method will stop canning responses and returns normal
 functionality where all the request will be directed to the live servers.
 */
+ (void)stop;

/** @section Options */

/** Sets the directory/path where canned responses will be cached.
 */
+ (void)setCanStoreLocation:(NSString *)location;

/** Initialize cans from given plist file.
 When callig this method it will read all cans that has been defined in the
 given plist file and initialize cans. This is useful when it is wanted to
 bootstrap canned responses for the device testing or to the new testing
 computer.
 */
+ (void)initializeCansFromPath:(NSString *)path;

#pragma mark - Can Management
/** @section Can Management */

/** Set currently active can to be used for canning responses.
 */
+ (void)useCan:(NSString *)canName;

/** Sets currently active can and matcher to use for finding previously
 canned requests.
 */
+ (void)useCan:(NSString *)canName withMatching:(OFRequestMatching)matching;

/** Sets currently active can and matcher to use. Also initializes
 can from given file if can has not been used before.
 */
+ (void)useCan:(NSString *)canName withMatching:(OFRequestMatching)matching withContentsOfFile:(NSString *)file;

@end
