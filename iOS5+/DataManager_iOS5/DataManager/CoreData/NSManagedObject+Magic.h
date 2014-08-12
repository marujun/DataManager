//
//  NSManagedObject+Magic.h
//  CoreDataUtil
//
//  Created by marujun on 14-1-13.
//  Copyright (c) 2014年 jizhi. All rights reserved.
//

#import <CoreData/CoreData.h>

/*导入所有通过model生成的SubClass*/
#import "User.h"
#import "Bank.h"

@interface NSSet (TCNSManagedObjectMethods)
// 排序下
- (NSArray *)sortObjects;
@end

@interface NSManagedObject (Magic)

/*获取表中所有数据*/
+ (NSArray *)getAllObjets;
/*清空表*/
+ (void)cleanTable;

@end
