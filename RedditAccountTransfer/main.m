//
//  main.m
//  RedditAccountTransfer
//
//  Created by Andrew Carter on 9/17/13.
//  Copyright (c) 2013 Pinch Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <termios.h>
#import "RATAccount.h"
#import "RATTransferer.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        puts("Transfer FROM Reddit Account");
        RATAccount *fromAccount = [[RATAccount alloc] initWithCredentialsPrompt];
        
        NSError *error;
        
        puts("Authenticating...");
        if (![fromAccount authenticate:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(1);
        }
        puts("Authenticated");
        
        puts("Getting Saved Posts...");
        if (![fromAccount getSavedPosts:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(1);
        };
        puts("Got Saved Posts\n");

        puts("Transfer TO Reddit Account");
        RATAccount *toAccount = [[RATAccount alloc] initWithCredentialsPrompt];
        
        puts("Authenticating...");
        if (![toAccount authenticate:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(1);
        }
        puts("Authenticated");
        
        puts("Getting Saved Posts...");
        if (![toAccount getSavedPosts:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(1);
        }
        puts("Got Saved Posts\n");
        
        RATTransferer *transferer = [RATTransferer new];
        [transferer setToAccount:toAccount];
        [transferer setFromAccount:fromAccount];
        
        puts("Transferring Posts...");
        if (![transferer transferSavedPosts:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(1);
        }
        puts("Done");
        
    }
    return 0;
}