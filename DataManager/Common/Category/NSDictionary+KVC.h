//
//  NSDictionary+KVC.h
//  USEvent
//
//  Created by marujun on 15/11/25.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (KVC)

/** 通过keyPath获取对应的数据，例：user.hobby[1].title */
- (id)us_valueForKeyPath:(NSString *)keyPath;

/** 通过keyPath修改数据，并返回一个新的字典。例：user.hobby[1].title */
- (instancetype)dictionaryByReplaceingValue:(id)value forKeyPath:(NSString *)keyPath;

/** 通过keyPath移除子节点中某个数据，并返回一个新的字典。例：user.hobby[1] */
- (instancetype)dictionaryByDeletingValueInKeyPath:(NSString *)keyPath;

/** 通过模糊条件predicate查找准确的keyPath路径。例：predicate为 'list.members[].uid = 100215', 返回keyPath: list.members[2]*/
- (NSString *)keyPathForPredicate:(NSString *)predicate;

@end
