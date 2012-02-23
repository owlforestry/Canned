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

@property (nonatomic, readwrite, strong) NSMutableDictionary *can;
@property (nonatomic, readwrite, strong) NSString *canName;
@property (nonatomic, readwrite) OFCanMatcher matcher;

- (void)appendData:(NSData *)newData;
- (NSString *)matcherFromRequest:(NSURLRequest *)request;
- (void)loadCan;
- (void)saveCan;

@end

@implementation OFCanned

@synthesize request = _request;
@synthesize connection = _connection;
@synthesize data = _data;
@synthesize response = _response;

@synthesize canName = _canName;
@synthesize can = _can;
@synthesize matcher = _matcher;

#pragma mark - OFCanned Methods
+ (NSString *)cansDirectory
{
    NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *canPath = [[_paths objectAtIndex:0] stringByAppendingPathComponent:@"cans"];
    return canPath;
}

+ (NSString *)pathForCan:(NSString *)can
{
    return [[[self.class cansDirectory] stringByAppendingPathComponent:can] stringByAppendingPathExtension:@"plist"];
}

- (id)init
{
    if (self = [super init]) {
        self.can = [NSMutableDictionary dictionary];
        self.canName = @"_default";
        self.matcher = kMatchByDefault;
        
        [self loadCan];
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

+ (void)setCan:(NSString *)canName
{
    [[self sharedInstance] setCanName:canName];
}

+ (void)catchAndCan
{
    [NSURLProtocol registerClass:[self class]];
}

+ (void)catchWithMatcher:(OFCanMatcher)matcher
{
    [self catchWithMatcher:matcher toCan:[[self sharedInstance] canName]];
}

+ (void)catchWithMatcher:(OFCanMatcher)matcher toCan:(NSString *)canName
{
    OFCanned *canned = [self sharedInstance];
    canned.matcher = matcher;
    canned.canName = canName;
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
        self.canName = [[self.class sharedInstance] canName];
        self.can = [[self.class sharedInstance] can];
        self.matcher = [[self.class sharedInstance] matcher];
        [self loadCan];
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
//    NSDictionary *__can = [NSDictionary dictionaryWithContentsOfFile:canPath];
//    [__can setValue:_canStore forKey:matcher];
//    [__can writeToFile:canPath atomically:NO];
//    NSLog(@"Wrote can to %@", _canStore);
    [self.can setValue:_canStore forKey:matcher];
    [self saveCan];

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

- (void)loadCan
{
    // Load can to memory if exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.class cansDirectory] isDirectory:nil]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self.class pathForCan:self.canName] isDirectory:NO]) {
            self.can = [NSDictionary dictionaryWithContentsOfFile:[self.class pathForCan:self.canName]];
        }
    } else {
        // Prepare directory
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.class cansDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)saveCan
{
    // Load can to memory if exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.class cansDirectory] isDirectory:nil]) {
        // Prepare directory
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.class cansDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
    }
//    [self.can writeToFile:[self.class pathForCan:[self.canName] atomically:NO];
    [self.can writeToFile:[self.class pathForCan:self.canName] atomically:YES];
    NSLog(@"Store can %@ to %@", self.can, [self.class pathForCan:self.canName]);
}
@end
