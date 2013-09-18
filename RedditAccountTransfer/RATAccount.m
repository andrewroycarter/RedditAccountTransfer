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

@end

@implementation RATAccount

- (void)getSavedPosts
{
    NSString *urlString = [NSString stringWithFormat:@"https://ssl.reddit.com/user/%@/saved.json", [self username]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request addValue:[self modhash] forHTTPHeaderField:@"X-Modhash"];
    [request addValue:[NSString stringWithFormat:@"reddit_session=%@", [self cookie]] forHTTPHeaderField:@"Cookie"];
    [request setHTTPMethod:@"GET"];
    
    NSHTTPURLResponse *response;
    NSError *responseError;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
    NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
}

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

- (BOOL)handleAuthenticateJSON:(NSData *)jsonData error:(NSError **)error
{
    BOOL didAuthenticate = NO;
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
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
        if ([loginErrors count])
        {
            NSArray *errorStrings = loginErrors[0];
            NSString *errorString = [errorStrings componentsJoinedByString:@", "];
            if (error != NULL)
            {
                *error = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer" code:0 userInfo:@{NSLocalizedDescriptionKey : errorString}];
            }
        }
        else
        {
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

- (BOOL)handleAuthenticateResponse:(NSHTTPURLResponse *)response responseError:(NSError *)responseError data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    BOOL didAuthenticate = NO;
    if (responseError)
    {
        if (error != NULL)
        {
            *error = responseError;
        }
    }
    else
    {
        didAuthenticate = [self handleAuthenticateJSON:data error:error];
    }
    
    [self clearAllRedditCookies];
    
    return didAuthenticate;
}

- (BOOL)authenticate:(NSError *__autoreleasing *)error
{
    BOOL didAuthenticate = NO;
    
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