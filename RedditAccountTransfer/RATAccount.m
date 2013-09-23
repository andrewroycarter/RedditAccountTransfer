//
//  RATAccount.m
//  RedditAccountTransfer
//
//  Created by Andrew Carter on 9/17/13.
//  Copyright (c) 2013 Pinch Studios. All rights reserved.
//

#import "RATAccount.h"

@interface RATAccount ()

@property (nonatomic, readwrite) BOOL authenticated;
@property (nonatomic, readwrite) NSString *cookie;
@property (nonatomic, readwrite) NSString *modhash;
@property (nonatomic, readwrite) NSArray *savedPosts;

@end

@implementation RATAccount

- (id)initWithCredentialsPrompt
{
    self = [super init];
    if (self)
    {
        // Need to find a way to prompt for passwords without echoing text that works well
        printf("username: ");
        char fromUserName[128];
        fgets(fromUserName, sizeof(fromUserName), stdin);
        strtok(fromUserName, "\n");
        
        printf("password: ");
        char fromPassword[128];
        fgets(fromPassword, sizeof(fromPassword), stdin);
        strtok(fromPassword, "\n");
        
        [self setUsername:[[NSString alloc] initWithCString:fromUserName encoding:NSUTF8StringEncoding]];
        [self setPassword:[[NSString alloc] initWithCString:fromPassword encoding:NSUTF8StringEncoding]];
    }
    return self;
}

- (BOOL)getSavedPosts:(NSError *__autoreleasing *)error
{
    // If we're not authenticated return NO with an error
    if (![self isAuthenticated])
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey : @"Must be authenticated to get saved posts"}];
        }
        return NO;
    }
    
    // setup variables to contain posts and state
    NSString *after = nil;
    NSMutableArray *allPosts = [NSMutableArray new];
    NSError *getSavedPostsError;
    
    
    do // while after != nil && getSavedPostsError == nil
    {
        // create urlString for the current set of posts
        NSString *urlString = [NSString stringWithFormat:@"https://ssl.reddit.com/user/%@/saved.json?limit=100", [self username]];
        if (after)
        {
            urlString = [[NSString alloc] initWithFormat:@"%@&after=%@", urlString, after];
        }
        
        // build request and add auth headers
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request addValue:[self modhash] forHTTPHeaderField:@"X-Modhash"];
        [request addValue:[NSString stringWithFormat:@"reddit_session=%@", [self cookie]] forHTTPHeaderField:@"Cookie"];
        [request setHTTPMethod:@"GET"];
        
        // Make requests
        NSHTTPURLResponse *response;
        NSError *responseError;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
        
        // If the request failed, populate the error
        if (responseError)
        {
            getSavedPostsError = responseError;
        }
        else
        {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
            
            // If the json wasn't good, populate the error
            if (jsonError)
            {
                getSavedPostsError = jsonError;
            }
            else
            {
                // append the returned saved posts to allPosts, and set the next after string for building the
                // next urlString
                NSArray *posts = json[@"data"][@"children"];
                [allPosts addObjectsFromArray:posts];
                after = [json[@"data"][@"after"] isKindOfClass:[NSString class]] ? json[@"data"][@"after"] : nil;
            }
        }
        
        // Need to be nice to reddit's API
        sleep(2);
        
    } while (after != nil && getSavedPostsError == nil);
    
    [self setSavedPosts:allPosts];
    
    // If there was an error, we need to return it
    if (getSavedPostsError && error != NULL)
    {
        *error = getSavedPostsError;
    }
    
    // Everything was successfull if there was no error
    return getSavedPostsError == nil;
}


// Removes any cookie having to do with Reddit. NSURLRequest and friends will auto use the cookies that we
// get from authenicating, but because we're dealing with two seperate users here that doesn't work for us.
// We'll set the cookies manually in our requests
- (void)clearAllRedditCookies
{
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        if ([[[cookie valueForKey:NSHTTPCookieDomain] uppercaseString] rangeOfString:@"REDDIT"].location != NSNotFound)
        {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

// Handles JSON returned from a log in request
- (BOOL)handleAuthenticateJSON:(NSData *)jsonData error:(NSError **)error
{
    BOOL didAuthenticate = NO;
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    
    // If the json wasn't good, return an error
    if (jsonError)
    {
        if (error != NULL)
        {
            *error = jsonError;
        }
    }
    else
    {
        NSArray *loginErrors = json[@"json"][@"errors"];
        
        // If we have login errors, return them to the user
        if ([loginErrors count])
        {
            NSArray *errorStrings = loginErrors[0];
            NSString *errorString = [errorStrings componentsJoinedByString:@", "];
            if (error != NULL)
            {
                *error = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer"
                                                    code:1
                                                userInfo:@{NSLocalizedDescriptionKey : errorString}];
            }
        }
        else
        {
            // Grab the modhash and cookie (we logged in successfully!)
            NSString *modhash = json[@"json"][@"data"][@"modhash"];
            NSString *cookie = json[@"json"][@"data"][@"cookie"];
            [self setAuthenticated:YES];
            [self setModhash:modhash];
            [self setCookie:cookie];
            didAuthenticate = YES;
        }
    }
    
    return didAuthenticate;
}

// Handle the response from a login call
- (BOOL)handleAuthenticateResponse:(NSHTTPURLResponse *)response responseError:(NSError *)responseError data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    BOOL didAuthenticate = NO;
    
    // If there was a network error, we did not authenticate
    if (responseError)
    {
        if (error != NULL)
        {
            *error = responseError;
        }
    }
    else
    {
        // parse the json data and see if we were successfull
        didAuthenticate = [self handleAuthenticateJSON:data error:error];
    }
    
    // clear cookies so that NSURLRequest and friends won't "auto" auth us
    [self clearAllRedditCookies];
    
    return didAuthenticate;
}

- (BOOL)authenticate:(NSError *__autoreleasing *)error
{
    BOOL didAuthenticate = NO;
 
    if (![self username] || ![self password])
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey : @"username and password must be set to authenticate"}];
        }
        return didAuthenticate;
    }
    
    NSString *urlString = @"https://ssl.reddit.com/api/login";
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *POSTString = [[NSString alloc] initWithFormat:@"api_type=json&rem=false&passwd=%@&user=%@", [self password], [self username]];
    NSData *HTTPBody = [POSTString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:HTTPBody];
    
    NSHTTPURLResponse *response;
    NSError *responseError;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
    
    didAuthenticate = [self handleAuthenticateResponse:response responseError:responseError data:responseData error:error];
    
    return didAuthenticate;
}

@end
