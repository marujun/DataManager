//
//  USDataController.h
//  USEvent
//
//  Created by marujun on 16/1/7.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^USRequestCompletionBlock)(BOOL success);

@interface USDataController : NSObject
{
    BOOL _isFirstRequest;
    NSMutableArray *_dataSource;
}

@property (nonatomic, assign) BOOL isFirstRequest;
@property (nonatomic, strong, readonly) NSMutableArray *dataSource;

- (void)requestDataWithCompletionBlock:(USRequestCompletionBlock)completionBlock;

@end
