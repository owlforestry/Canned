//
//  OFCannedURLProtocol.m
//  Canned
//
//  Created by Mikko Kokkonen on 2/22/12.
//  Copyright (c) 2012 Owl Forestry. All rights reserved.
//

#import "OFCanned.h"

@interface OFCanned () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, readwrite, strong) NSURLRequest *request;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;

@property (nonatomic, readwrite, strong) NSString *can;
@property (nonatomic, readwrite) OFCanMatcher matcher;

- (void)appendData:(NSData *)newData;
- (NSString *)matcherFromRequest:(NSURLRequest *)request;

@end

@implementation OFCanned

@synthesize request = _request;
@synthesize connection = _connection;
@synthesize data = _data;
@synthesize response = _response;

@synthesize can = _can;
@synthesize matcher = _matcher;

#pragma mark - OFCanned Methods
- (id)init
{
    if (self = [super init])
    {
        self.can = @"_default";
        self.matcher = kMatchByDefault;
    }
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    __strong static id _sharedObject = nil;
    
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

+ (void)setCan:(NSString *)can
{
    [[self sharedInstance] setCan:can];
}

+ (void)catchAndCan
{
    [NSURLProtocol registerClass:[self class]];
}

#pragma mark - NSURLProtocol Methods
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // We support HTTP only at the moment
    if ([[[request URL] scheme] isEqualToString:@"http"] &&
        [request valueForHTTPHeaderField:@"X-Canned"] == nil) {
        NSLog(@"Requesting canned response: %@", request);
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
    [lRequest setValue:@"0" forHTTPHeaderField:@"X-Canned"];
    
    self = [super initWithRequest:lRequest cachedResponse:cachedResponse client:client];
    if (self) {
        self.request = lRequest;
        self.can = [[[self class] sharedInstance] can];
        self.matcher = [[[self class] sharedInstance] matcher];
    }
    
    return self;
}

- (void)startLoading
{
    NSLog(@"Fetching data from %@", self.can);
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
    self.connection = connection;
}

- (void)stopLoading
{
    [[self connection] cancel];
}

// NSURLConnection delegates (generally we pass these on to our client)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    //    NSString *cachePath = [self cachePathForRequest:[self request]];
    //    RNCachedData *cache = [RNCachedData new];
    //    [cache setResponse:[self response]];
    //    [cache setData:[self data]];
    //    [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
    
//    NSLog(@"Got data: %@", [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]);
    NSString *matcher = [self matcherFromRequest:self.request];
//    NSDictionary *_canStore = [NSDictionary dictionaryWithObjectsAndKeys:
//                          matcher, @"matcher", self.data, @"data", nil];
    NSDictionary *_canStore = [NSDictionary dictionaryWithObjectsAndKeys:
                               self.request.HTTPMethod, @"method",
                                [self data], @"data",
                               nil];
    NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *canPath = [[[_paths objectAtIndex:0] stringByAppendingPathComponent:self.can] stringByAppendingPathExtension:@"plist"];
    NSDictionary *__can = [NSDictionary dictionaryWithContentsOfFile:canPath];
    [__can setValue:_canStore forKey:matcher];
    [__can writeToFile:canPath atomically:NO];
    NSLog(@"Wrote can to %@", _canStore);

    [self setConnection:nil];
    [self setData:nil];
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

- (NSString *)matcherFromRequest:(NSURLRequest *)request
{
    switch (self.matcher) {
        case kMatchByDefault:
            return [NSString stringWithFormat:@"%@_%@", request.HTTPMethod, request.URL.description];
            break;
            
        default:
            return [NSString stringWithFormat:@"%u", request.hash];
            break;
    }
}
@end
