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
    BOOL didTransferSavedPosts = YES;
    NSError *saveError;

    for (NSDictionary *post in [[self fromAccount] savedPosts])
    {
        printf("Transferring Posts... (%lu/%lu)\n", (unsigned long)[[[self fromAccount] savedPosts] indexOfObject:post] + 1, (unsigned long)[[[self fromAccount] savedPosts] count]);
        NSString *urlString = @"https://ssl.reddit.com/api/save";
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request addValue:[[self toAccount] modhash] forHTTPHeaderField:@"X-Modhash"];
        [request addValue:[NSString stringWithFormat:@"reddit_session=%@", [[self toAccount] cookie]] forHTTPHeaderField:@"Cookie"];
        [request setHTTPMethod:@"POST"];
        
        NSString *POSTString = [[NSString alloc] initWithFormat:@"id=%@_%@", post[@"kind"], post[@"data"][@"id"]];
        NSData *HTTPBody = [POSTString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:HTTPBody];
        
        NSHTTPURLResponse *response;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&saveError];
        
        if (saveError || [response statusCode] != 200)
        {
            didTransferSavedPosts = NO;
            if (!saveError)
            {
                saveError = [[NSError alloc] initWithDomain:@"com.pinchstudios.redditaccounttransfer" code:0 userInfo:@{NSLocalizedDescriptionKey : @"An error occured while saving a post"}];
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
