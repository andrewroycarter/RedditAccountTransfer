//
//  RATTransferer.h
//  RedditAccountTransfer
//
//  Created by Andrew Carter on 9/17/13.
//  Copyright (c) 2013 Pinch Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RATAccount;

@interface RATTransferer : NSObject

@property (nonatomic, strong) RATAccount *fromAccount;
@property (nonatomic, strong) RATAccount *toAccount;

- (BOOL)transferSavedPosts:(NSError **)error;

@end
