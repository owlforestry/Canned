//
//  OFCannedURLProtocol.m
//  Canned
//
//  Created by Mikko Kokkonen on 2/22/12.
//  Copyright (c) 2012 Owl Forestry. All rights reserved.
//

#import "OFCanned.h"

// Undocumented initializer obtained by class-dump - don't use this in production code destined for the App Store
@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@interface OFCanned () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, readwrite, strong) NSURLRequest *request;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSHTTPURLResponse *response;

+ (NSMutableDictionary *)settings;

+ (NSMutableDictionary *)can;

+ (NSString *)canName;
+ (void)setCanName:(NSString *)canName;

+ (NSString *)canStoreLocation;
+ (void)setCanStoreLocation:(NSString *)location;

+ (NSString *)canStorePath;

+ (OFRequestMatching)matching;
+ (void)setMatching:(OFRequestMatching)matching;

+ (void)saveCan;
+ (void)loadCan;

+ (NSString *)matcherForRequest:(NSURLRequest *)request withMatcher:(OFRequestMatching)matcher;
- (NSString *)matcherForRequest:(NSURLRequest *)request;

- (void)appendData:(NSData *)newData;

@end

@implementation OFCanned

@synthesize request = _request;
@synthesize connection = _connection;
@synthesize data = _data;
@synthesize response = _response;

#pragma mark - Static accessors
+ (NSMutableDictionary *)settings
{
    static NSMutableDictionary *settings = nil;
    if (settings == nil) {
        NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *canStoreLocation = [[_paths objectAtIndex:0] stringByAppendingPathComponent:@"cans"];
        settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSMutableDictionary dictionary], @"can",
                    @"_default", @"canName",
                    [NSNumber numberWithInt:kOFMatchingWithURIAndMethod], @"matching",
                    canStoreLocation, @"canStoreLocation",
                    nil];
        [self.class loadCan];
    }
    
    return settings;
}

+ (NSMutableDictionary *)can
{
    return [self.class.settings objectForKey:@"can"];
}

+ (NSString *)canName
{
    return [self.class.settings objectForKey:@"canName"];
}

+ (void)setCanName:(NSString *)canName
{
    [self.class.settings setObject:canName forKey:@"canName"];
    [self.class loadCan];
}

+ (NSString *)canStoreLocation
{
    return [self.class.settings objectForKey:@"canStoreLocation"];
}

+ (void)setCanStoreLocation:(NSString *)location
{
    [self.class.settings setObject:location forKey:@"canStoreLocation"];
}

+ (OFRequestMatching)matching
{
    return [[self.class.settings objectForKey:@"matching"] intValue];
}

+ (void)setMatching:(OFRequestMatching)matching
{
    [self.class.settings setObject:[NSNumber numberWithInt:matching] forKey:@"matching"];
}

+ (NSString *)canStorePath
{
    return [[[self.class.settings objectForKey:@"canStoreLocation"] stringByAppendingPathComponent:[self.class.settings objectForKey:@"canName"]] stringByAppendingPathExtension:@"plist"];
}

+ (void)saveCan
{
//    NSLog(@"Saving can...");
//    NSLog(@"%@", self.class.can);
    if (![[NSDictionary dictionaryWithDictionary:self.class.can] writeToFile:self.class.canStorePath atomically:YES]) {
//        NSLog(@"Failed to save to %@", self.class.canStorePath);
        [[NSString stringWithString:@"File save works."] writeToFile:self.class.canStorePath atomically:YES];
    } else {
//        NSLog(@"Saved.");
    }
}

+ (void)loadCan
{
//    NSLog(@"Loading can %@...", self.class.canName);
    // Try to load existing can
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.class.canStorePath]) {
//        NSLog(@"Reading can from %@", self.class.canStorePath);
        NSMutableDictionary *can = [NSMutableDictionary dictionaryWithContentsOfFile:self.class.canStorePath];
        [self.class.settings setObject:can forKey:@"can"];
    }
}

#pragma mark - OFCanned Methods
+ (void)start
{
    NSLog(@"Registering OFCanned to URLProtocol stack...");
    [NSURLProtocol registerClass:self.class];
}

+ (void)stop
{
    NSLog(@"Deregistering OFCanned from URLProtocol stack");
    [NSURLProtocol unregisterClass:self.class];
}

+ (void)initializeCansFromPath:(NSString *)path
{
    
}

+ (void)useCan:(NSString *)canName
{
    [self useCan:canName withMatching:kOFMatchingWithURIAndMethod];
}

+ (void)useCan:(NSString *)canName withMatching:(OFRequestMatching)matching
{
    [self useCan:canName withMatching:matching withContentsOfFile:nil];
}

+ (void)useCan:(NSString *)canName withMatching:(OFRequestMatching)matching withContentsOfFile:(NSString *)file
{
    self.class.canName = canName;
    self.class.matching = matching;
    
    if (file != nil && [self.class.can.allKeys count] == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
            NSLog(@"Loading cans from file %@", file);
            NSDictionary *preloadCan = [NSDictionary dictionaryWithContentsOfFile:file];
            [preloadCan enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self.class.can setObject:obj forKey:key];
            }];
        } else {
            NSLog(@"Cannot find file %@ to get can contents!", file);
        }
    }
}

+ (NSString *)matcherForRequest:(NSURLRequest *)request withMatcher:(OFRequestMatching)matcher
{
    switch (matcher) {
        case kOFMatchingWithURIAndMethod:
        {
            return [NSString stringWithFormat:@"_%@_%@", request.HTTPMethod, request.URL.description];
            break;
        }
        case kOFMatchingWithBody:
        {
            NSString *body = @"";
            if (request.HTTPBody && ![request.HTTPBody isEqual:[NSNull null]]) {
                body = [NSString stringWithUTF8String:[request.HTTPBody bytes]];
            }
            return [NSString stringWithFormat:@"%@:%@", [self.class matcherForRequest:request withMatcher:kOFMatchingWithURIAndMethod], body];
        }
        default:
            break;
    }    
}

- (NSString *)matcherForRequest:(NSURLRequest *)request
{
    return [self.class matcherForRequest:request withMatcher:[[self.class.settings objectForKey:@"matching"] intValue]];
}

#pragma mark - NSURLProtocol Methods
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // We support HTTP only at the moment
    if ([[[request URL] scheme] isEqualToString:@"http"] &&
        [request valueForHTTPHeaderField:@"X-OFCanned"] == nil) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client
{
    NSMutableURLRequest *lRequest = [request mutableCopy];
    [lRequest setValue:@"0" forHTTPHeaderField:@"X-OFCanned"];
    
    self = [super initWithRequest:lRequest cachedResponse:cachedResponse client:client];
    if (self) {
        self.request = lRequest;
    }
    
    return self;
}

- (void)startLoading
{
    // Try to find canned response
    NSDictionary *canned = [self.class.can objectForKey:[self matcherForRequest:self.request]];
    if (canned) {
        NSDictionary *cannedResponse = [canned objectForKey:@"response"];
        NSLog(@"Using canned response");
        NSString *body = [cannedResponse objectForKey:@"body"];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[cannedResponse objectForKey:@"url"] statusCode:[[cannedResponse objectForKey:@"statusCode"] intValue] headerFields:[cannedResponse objectForKey:@"headers"] requestTime:0.0];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:bodyData];
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate
#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    [self setResponse:response];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    
    // Store response to can
//    NSLog(@"Storing canned response to can %@ to path %@", self.class.canName, self.class.canStoreLocation);
    // Can request
    NSDictionary *_cannedRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.request.HTTPMethod, @"method",
                                    self.request.URL.description, @"url",
                                    self.request.HTTPBody, @"body",
                                    self.request.allHTTPHeaderFields, @"headers",
                                    nil];
    NSDictionary *_cannedResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:self.response.statusCode], @"statusCode",
                                     self.response.allHeaderFields, @"headers",
                                     [NSString stringWithUTF8String:[self.data bytes]], @"body",
                                     nil];
    NSDictionary *_canned = [NSDictionary dictionaryWithObjectsAndKeys:
                             _cannedRequest, @"request",
                             _cannedResponse, @"response",
                             nil];
    [self.class.can setObject:_canned forKey:[self matcherForRequest:self.request]];
    [self.class saveCan];
//    NSLog(@"Canned to %@:\n%@", self.canStorePath, _canned);
}

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil)
    {
        [self setData:[[NSMutableData alloc] initWithData:newData]];
    }
    else
    {
        [[self data] appendData:newData];
    }
}

@end
