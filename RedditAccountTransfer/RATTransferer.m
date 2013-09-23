//
//  RATTransferer.m
//  RedditAccountTransfer
//
//  Created by Andrew Carter on 9/17/13.
//  Copyright (c) 2013 Pinch Studios. All rights reserved.
//

#import "RATTransferer.h"

#import "RATAccount.h"

@implementation RATTransferer

- (BOOL)transferSavedPosts:(NSError *__autoreleasing *)error
{
    // Make sure that fromAccount and toAccount are set
    NSAssert([self fromAccount], @"Must have a fromAccount");
    NSAssert([self toAccount], @"Must have a toAccount");
    
    // If we're not authenticated, return an error
    if (![[self fromAccount] isAuthenticated] || ![[self toAccount] isAuthenticated])
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey : @"All accounts must be authenticated to transfer posts"}];
        }
        return NO;
    }
    
    BOOL didTransferSavedPosts = YES;
    NSError *saveError;

    // There's no API for batch saving posts, so we do one post at a time
    for (NSDictionary *post in [[self fromAccount] savedPosts])
    {
        printf("Transferring Posts... (%lu/%lu)\n", (unsigned long)[[[self fromAccount] savedPosts] indexOfObject:post] + 1, (unsigned long)[[[self fromAccount] savedPosts] count]);
        
        // Build urlString and request,
        NSString *urlString = @"https://ssl.reddit.com/api/save";
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        
        // set params and auth tokens
        [request addValue:[[self toAccount] modhash] forHTTPHeaderField:@"X-Modhash"];
        [request addValue:[NSString stringWithFormat:@"reddit_session=%@", [[self toAccount] cookie]] forHTTPHeaderField:@"Cookie"];
        [request setHTTPMethod:@"POST"];
        
        // HTTPBody contains data of which post to save. The id is postKind_id
        NSString *POSTString = [[NSString alloc] initWithFormat:@"id=%@_%@", post[@"kind"], post[@"data"][@"id"]];
        NSData *HTTPBody = [POSTString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:HTTPBody];
        
        NSHTTPURLResponse *response;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&saveError];
        
        // If there was a network error or reddit returned a non 200 http status code, return an error
        if (saveError || [response statusCode] != 200)
        {
            didTransferSavedPosts = NO;
            if (!saveError)
            {
                saveError = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer"
                                                       code:1
                                                   userInfo:@{NSLocalizedDescriptionKey : @"An error occured while saving a post"}];
            }
            break;
        }
        
        // need to keep reddit API happy
        sleep(2);
    }
    
    if (error != NULL)
    {
        *error = saveError;
    }
    
    return didTransferSavedPosts;
}

@end
