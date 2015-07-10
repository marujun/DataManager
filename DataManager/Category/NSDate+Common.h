//
//  NSDate+Common.h
//  HLMagic
//
//  Created by marujun on 14-1-26.
//  Copyright (c) 2014年 chen ying. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Common)

//获取天数索引
- (int)dayIndexSince1970;
- (int)dayIndexSinceNow;
- (int)dayIndexSinceDate:(NSDate *)date;

//生成timestamp
- (NSString *)timestamp;
+ (NSDate *)dateWithTimeStamp:(double)timestamp;

//返回星期的字符串
- (NSString *)weekDayString;
//返回简短的星期字符串
- (NSString *)shortWeekDayString;
//返回月份的字符串
- (NSString *)monthString;

//获取字符串
- (NSString *)string;
- (NSString *)stringWithDateFormat:(NSString *)format;

//格式化日期 精确到天或小时
- (NSDate *)dateAccurateToDay;
- (NSDate *)dateAccurateToHour;

//计算年龄
- (int)age;

//判断2个日期是否在同一天
- (BOOL)isSameDayWithDate:(NSDate *)date;
- (BOOL)isToday;

//判断2个日期是否在同一年
- (BOOL)isSameYearWithDate:(NSDate *)date;

//忽略年月日
- (NSDate *)dateRemoveYMD;

- (NSDateComponents *)allDateComponent;

//加上时区偏移
- (NSDate *)changeZone;

- (NSString *)getFormatYearMonthDay;

//返回day天后的日期(若day为负数,则为|day|天前的日期)
- (NSDate *)dateAfterDay:(NSInteger)day;
//month个月后的日期
- (NSDate *)dateafterMonth:(NSInteger)month;
//获取日
- (NSUInteger)getDay;
//获取月
- (NSUInteger)getMonth;
//获取年
- (NSUInteger)getYear;
//获取小时
- (NSInteger )getHour;
//获取分钟
- (NSInteger)getMinute;
- (NSInteger)getHour:(NSDate *)date;
- (NSInteger)getMinute:(NSDate *)date;
//在当前日期前几天
- (NSUInteger)daysAgo;
//午夜时间距今几天
- (NSUInteger)daysAgoAgainstMidnight;

- (NSString *)stringDaysAgo;

- (NSString *)stringDaysAgoAgainstMidnight:(BOOL)flag;

//返回一周的第几天(周末为第一天)
- (NSUInteger)weekday;
//转为NSString类型的
+ (NSDate *)dateFromString:(NSString *)string;

+ (NSDate *)dateFromString:(NSString *)string withFormat:(NSString *)format;

+ (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format;

+ (NSString *)stringFromDate:(NSDate *)date;

+ (NSString *)stringForDisplayFromDate:(NSDate *)date prefixed:(BOOL)prefixed;

+ (NSString *)stringForDisplayFromDate:(NSDate *)date;

- (NSString *)stringWithFormat:(NSString *)format;

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;
//返回周日的的开始时间
- (NSDate *)beginningOfWeek;
//返回当前天的年月日.
- (NSDate *)beginningOfDay;
//返回该月的第一天
- (NSDate *)beginningOfMonth;
//该月的最后一天
- (NSDate *)endOfMonth;
//返回当前周的周末
- (NSDate *)endOfWeek;

+ (NSString *)dateFormatString;

+ (NSString *)timeFormatString;
+ (NSString *)timestampFormatString;
// preserving for compatibility
+ (NSString *)dbFormatString;
@end

@interface NSString (DateCommon)
//获取日期
- (NSDate *)date;
- (NSDate *)dateWithDateFormat:(NSString *)format;
@end