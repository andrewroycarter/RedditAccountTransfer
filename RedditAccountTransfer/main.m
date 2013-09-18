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

void setConsoleEchoEnabled(BOOL enabled);
RATAccount * getRedditAccount();

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        puts("Transfer FROM Reddit Account");
        RATAccount *fromAccount = getRedditAccount();
        
        NSError *error;
        if (![fromAccount authenticate:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(0);
        }
        
        [fromAccount getSavedPosts];
        
        puts("Transfer TO Reddit Account");
        RATAccount *toAccount = getRedditAccount();
        if (![toAccount authenticate:&error])
        {
            NSLog(@"ERROR: %@", [error localizedDescription]);
            exit(0);
        }
    }
    return 0;
}

RATAccount * getRedditAccount()
{
    printf("username: ");
    char fromUserName[128];
    fgets(fromUserName, sizeof(fromUserName), stdin);
    strtok(fromUserName, "\n");
    
    printf("password: ");
    char fromPassword[128];
//    setConsoleEchoEnabled(NO);
    fgets(fromPassword, sizeof(fromPassword), stdin);
    strtok(fromPassword, "\n");
//    setConsoleEchoEnabled(YES);
    
    RATAccount *account = [RATAccount new];
    [account setUsername:[[NSString alloc] initWithCString:fromUserName encoding:NSUTF8StringEncoding]];
    [account setPassword:[[NSString alloc] initWithCString:fromPassword encoding:NSUTF8StringEncoding]];
    
    return account;
}

void setConsoleEchoEnabled(BOOL enabled)
{
    struct termios oldFlags, newFlags;
    tcgetattr(fileno(stdin), &oldFlags);
    newFlags = oldFlags;
    
    if (enabled)
    {
        newFlags.c_lflag &= ECHO;
        newFlags.c_lflag |= ~ECHONL;
    }
    else
    {
        newFlags.c_lflag &= ~ECHO;
        newFlags.c_lflag |= ECHONL;
    }
    
    tcsetattr(fileno(stdin), TCSANOW, &newFlags);
}