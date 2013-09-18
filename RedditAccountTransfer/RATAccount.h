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
@property (nonatomic, readonly) NSArray *savedPosts;

- (BOOL)authenticate:(NSError **)error;
- (BOOL)getSavedPosts:(NSError **)error;

@end
