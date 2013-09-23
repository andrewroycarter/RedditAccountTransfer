//
//  RATAccount.h
//  RedditAccountTransfer
//
//  Created by Andrew Carter on 9/17/13.
//  Copyright (c) 2013 Pinch Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RATAccount : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, readonly, getter = isAuthenticated) BOOL authenticated;
@property (nonatomic, readonly) NSString *cookie;
@property (nonatomic, readonly) NSString *modhash;

// Array of saved posts populated by - getSavedPosts:
@property (nonatomic, readonly) NSArray *savedPosts;

// will prompt for username and password after init
- (id)initWithCredentialsPrompt;

// will attempt to auth with reddit with username and password
- (BOOL)authenticate:(NSError **)error;

// will attempt to get saved posts, and populates them into savedPosts
- (BOOL)getSavedPosts:(NSError **)error;

@end
