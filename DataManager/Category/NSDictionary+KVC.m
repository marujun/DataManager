//
//  NSDictionary+KVC.m
//  USEvent
//
//  Created by marujun on 15/11/25.
//  Copyright © 2015年 MaRuJun. All rights reserved.
//

#import "NSDictionary+KVC.h"

@implementation NSDictionary (KVC)

- (NSString *)keyPathForPredicate:(NSString *)predicate
{
    NSString *result = @"";
    id original = self ;
    NSArray *divisionArray = [predicate componentsSeparatedByString:@"="];
    
    if (divisionArray.count != 2) {
        return nil;
    }else{
        NSString *value = [[divisionArray[1] stringValue]  stringByReplacingOccurrencesOfString:@" " withString:@""];

        NSString *keyPath = [divisionArray[0] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *divisionArray = [keyPath componentsSeparatedByString:@"."];

        NSString *tempKey = divisionArray[0];
        
        NSRange range = [keyPath rangeOfString:tempKey];
        NSString *spareStr = [keyPath substringFromIndex:range.length];
        if ([spareStr hasPrefix:@"."]) {
            spareStr = [spareStr substringFromIndex:1];
        }
        
        if ([original isKindOfClass:[NSDictionary class]]) {
            
            if ([tempKey hasSuffix:@"]"]&&[tempKey rangeOfString:@"["].length)
            {
                NSString *tempSufStr = [[tempKey componentsSeparatedByString:@"["] firstObject];
                result = [NSString stringWithFormat:@"%@%@",result,tempSufStr];
                NSRange range = [tempKey rangeOfString:tempSufStr];
                tempKey = [tempKey substringFromIndex:range.length];
                original = original[tempSufStr];
                
                if ([tempKey hasSuffix:@"]"]&&[tempKey hasPrefix:@"["]) {
                    
                    NSMutableArray *arrayKey = [[tempKey componentsSeparatedByString:@"["] mutableCopy];
                    [arrayKey removeObjectAtIndex:0];
                    
                    for (int i = 0; i<arrayKey.count-1; i++) {
                        NSString *bracketStr = arrayKey[i];
                        
                        if (![bracketStr hasSuffix:@"]"]) {
                            result = nil;
                        }
                        
                        if ([[bracketStr substringFromIndex:0] isEqualToString:@"]"]) {
                             return nil;
                        }else {
                            
                            NSRange tempRange = [bracketStr rangeOfString:@"]"];
                            NSString *tempSpareStr = [bracketStr substringToIndex:tempRange.location];

                            int tempI = [tempSpareStr intValue];
                            
                            if ([tempSpareStr intValue] >= 0) {
                                if ([original isKindOfClass:[NSArray class]]&&((NSArray *)original).count>tempI) {
                                    original = original[tempI];
                                    result = [NSString stringWithFormat:@"%@[%@",result,bracketStr];
                                }else{
                                    return nil;
                                }

                            }else{
                                return nil;
                            }
                        }
                    }
                    
                    if (![arrayKey[arrayKey.count-1] hasSuffix:@"]"]) {
                        return nil;
                    }
                    
                    if (![original isKindOfClass:[NSArray class]]) {
                        return nil;
                    }
                    
                    
                    if ([[arrayKey[arrayKey.count-1] substringFromIndex:0] isEqualToString:@"]"]) {
                        if (!((NSArray *)original).count) {
                            return nil;
                        }
                        int i = 0;
                        for (id item in (NSArray *)original) {
                            if ([item isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *dict = (NSDictionary *)item;
                                for (NSString *str in dict.allKeys) {
                                    if ([dict[str] isEqualToString:value]) {
                                        result = [NSString stringWithFormat:@"%@[%i%@",result , i,arrayKey[arrayKey.count-1]];
                                        return result;
                                    }
                                }
                            }
                            i++;
                        }
                        return nil;
                    }
                    
                    result = [NSString stringWithFormat:@"%@[%@",result , arrayKey[arrayKey.count-1]];

                    NSRange tempRange = [arrayKey[arrayKey.count-1] rangeOfString:@"]"];
                    NSString *tempSpareStr = [arrayKey[arrayKey.count-1] substringToIndex:tempRange.location];
                    
                    if ([tempSpareStr intValue] < 0) {
                        return nil;
                    }
                    
                    int k = [tempSpareStr intValue];
                    
                    
                    if (((NSArray *)original).count<=k) {
                        return nil;
                    }
                    if ([original[k] isKindOfClass:[NSString class]]) {
                        return nil;
                    }else{
                        id dd = original[k];
                        
                        if (!spareStr.length) {
                            return nil;
                        }else{
                            if ([dd isKindOfClass:[NSDictionary class]]) {
                                NSString *tempRes = [dd keyPathForPredicate:[NSString stringWithFormat:@"%@=%@",spareStr,value]];
                                
                                if (!tempRes) {
                                    return nil;
                                }else{
                                    return [NSString stringWithFormat:@"%@.%@",result,tempRes];
                                }
                            }else {
                                return nil;
                            }
                        }
                    }
                    
                }else{
                    return nil;
                }
                
            }
            else {
                if ([original[tempKey] isKindOfClass:[NSString class]]) {
                    return nil;
                }
                else
                {
                    id dd = original[tempKey];
                    
                    if (!spareStr.length) {
                        return nil;
                    }else{
                        if ([dd isKindOfClass:[NSDictionary class]]) {
                            
                            NSString *tempRes = [dd keyPathForPredicate:[NSString stringWithFormat:@"%@=%@",spareStr,value]];
                            if (!tempRes) {
                                return nil;
                            }else{
                                return [NSString stringWithFormat:@"%@.%@",result,tempRes];
                            }

                        }else{
                            return nil;
                        }
                    }
                }
            }
        }
        else{
            return nil;
        }
    }
}

- (instancetype)dictionaryByReplaceingValue:(id)value forKeyPath:(NSString *)keyPath
{
    id original = self ;
    NSArray *divisionArray = [keyPath componentsSeparatedByString:@"."];
    NSString *tempKey = divisionArray[0];
    
    NSRange range = [keyPath rangeOfString:tempKey];
    NSString *spareStr = [keyPath substringFromIndex:range.length];
    if ([spareStr hasPrefix:@"."]) {
        spareStr = [spareStr substringFromIndex:1];
    }
    
    id tempOriginal1 = [original mutableCopy];

    if ([original isKindOfClass:[NSDictionary class]]) {
        
        if ([tempKey hasSuffix:@"]"]&&[tempKey rangeOfString:@"["].length)
        {
            NSString *tempSufStr = [[tempKey componentsSeparatedByString:@"["] firstObject];
            NSRange range = [tempKey rangeOfString:tempSufStr];
            tempKey = [tempKey substringFromIndex:range.length];
            
            id original1 = [tempOriginal1[tempSufStr] mutableCopy];
            tempOriginal1[tempSufStr] = original1;
            
            if ([tempKey hasSuffix:@"]"]&&[tempKey hasPrefix:@"["]) {
                
                NSMutableArray *arrayKey = [[tempKey componentsSeparatedByString:@"["] mutableCopy];
                [arrayKey removeObjectAtIndex:0];
                id original2 = original1;
                for (int i = 0; i<arrayKey.count-1; i++) {
                    NSString *bracketStr = arrayKey[i];
                    
                    if ([bracketStr hasSuffix:@"]"]) {
                        NSRange tempRange = [bracketStr rangeOfString:@"]"];
                        NSString *tempSpareStr = [bracketStr substringToIndex:tempRange.location];

                        if ([tempSpareStr intValue]>=0)
                        {
                            int tempI = [tempSpareStr intValue];
                            
                            if ([original1 isKindOfClass:[NSArray class]]&&((NSArray *)original1).count>tempI) {
                                original2 = [original1[tempI] mutableCopy];
                                original1[tempI] = original2;
                            }
                        }
                    }
                }
                
                if ([arrayKey[arrayKey.count-1] hasSuffix:@"]"]) {
                    NSRange tempRange = [arrayKey[arrayKey.count-1] rangeOfString:@"]"];
                    NSString *tempSpareStr = [arrayKey[arrayKey.count-1] substringToIndex:tempRange.location];

                    if ([tempSpareStr intValue] >= 0)
                    {
                        int k = [tempSpareStr intValue];
                        
                        if ([original2 isKindOfClass:[NSArray class]]&&((NSArray *)original2).count>k){
                            id dd = [original2[k] mutableCopy];
                            original2[k] = dd;
                            
                            if (!spareStr.length) {
                                if (!value) {
                                    original2[k] = value;
                                }
                                
                            }else{
                                if ([dd isKindOfClass:[NSDictionary class]]) {
                                    original2[k] = [dd dictionaryByReplaceingValue:value forKeyPath:spareStr];
                                }
                            }
                        }
                    }
                }
            }
        }
        else {
            id dd = tempOriginal1[tempKey];

            if ([dd conformsToProtocol:@protocol(NSMutableCopying)]) {
                dd = [dd mutableCopy];
            }
            tempOriginal1[tempKey] = dd;
            
            if (!spareStr.length) {
                [tempOriginal1 setValue:value forKey:tempKey];
            }else{
                if ([dd isKindOfClass:[NSDictionary class]]) {
                    [tempOriginal1 setValue:[dd dictionaryByReplaceingValue:value forKeyPath:spareStr] forKey:tempKey];
                }
            }
        }
        return tempOriginal1;
    }
    
    else{
        return tempOriginal1;
    }
    
}

- (instancetype)dictionaryByDeletingValueInKeyPath:(NSString *)keyPath
{
    id original = self ;
    
    NSArray *divisionArray = [keyPath componentsSeparatedByString:@"."];
    NSString *tempKey = divisionArray[0];
    
    NSRange range = [keyPath rangeOfString:tempKey];
    NSString *spareStr = [keyPath substringFromIndex:range.length];
    if ([spareStr hasPrefix:@"."]) {
        spareStr = [spareStr substringFromIndex:1];
    }
    
    id tempOriginal1 = [original mutableCopy];

    if ([original isKindOfClass:[NSDictionary class]]) {
        
        if ([tempKey hasSuffix:@"]"]&&[tempKey rangeOfString:@"["].length)
        {
            NSString *tempSufStr = [[tempKey componentsSeparatedByString:@"["] firstObject];
            NSRange range = [tempKey rangeOfString:tempSufStr];
            tempKey = [tempKey substringFromIndex:range.length];
            
            id original1 = [tempOriginal1[tempSufStr] mutableCopy];
            tempOriginal1[tempSufStr] = original1;
            
            if ([tempKey hasSuffix:@"]"]&&[tempKey hasPrefix:@"["]) {
                
                NSMutableArray *arrayKey = [[tempKey componentsSeparatedByString:@"["] mutableCopy];
                [arrayKey removeObjectAtIndex:0];
                id original2 = original1;
                for (int i = 0; i<arrayKey.count-1; i++) {
                    NSString *bracketStr = arrayKey[i];
                    
                    if ([bracketStr hasSuffix:@"]"]) {
                        NSRange tempRange = [bracketStr rangeOfString:@"]"];
                        NSString *tempSpareStr = [bracketStr substringToIndex:tempRange.location];

                        if ([tempSpareStr intValue] >= 0)
                        {
                            int tempI = [tempSpareStr intValue];
                            
                            if ([original1 isKindOfClass:[NSArray class]]&&((NSArray *)original1).count>tempI) {
                                original2 = [original1[tempI] mutableCopy];
                                original1[tempI] = original2;
                            }
                        }
                    }
                }
                
                if ([arrayKey[arrayKey.count-1] hasSuffix:@"]"]) {
                    
                    NSRange tempRange = [arrayKey[arrayKey.count-1] rangeOfString:@"]"];
                    NSString *tempSpareStr = [arrayKey[arrayKey.count-1] substringToIndex:tempRange.location];
                    if ([tempSpareStr intValue] >= 0)
                    {
                        int k = [tempSpareStr intValue];
                        
                        if ([original2 isKindOfClass:[NSArray class]]&&((NSArray *)original2).count>k) {
                            id dd = original2[k];
                            
                            if (!spareStr.length) {
                                [original2 removeObjectAtIndex:k];
                                
                            }else{
                                if ([dd isKindOfClass:[NSDictionary class]]) {
                                    original2[k] = [dd dictionaryByDeletingValueInKeyPath:spareStr];
                                }
                            }
                        }
                    }
                }
             }
            
        }
        else {
            
            id dd = tempOriginal1[tempKey];
            
            if ([dd conformsToProtocol:@protocol(NSMutableCopying)]) {
                dd = [dd mutableCopy];
            }
            tempOriginal1[tempKey] = dd;

            if (!spareStr.length) {
                
                if ([dd isKindOfClass:[NSArray class]]) {
                    [tempOriginal1 removeObjectForKey:tempKey];
                    
                }else if ([dd isKindOfClass:[NSDictionary class]]) {
                    [tempOriginal1 removeObjectForKey:tempKey];
                    
                }
                
            }else{
                if ([dd isKindOfClass:[NSDictionary class]]) {
                    tempOriginal1[tempKey] = [dd dictionaryByDeletingValueInKeyPath:spareStr];
                }
            }
        }
        
        return tempOriginal1;
    }
    
    else{
        
        return tempOriginal1;
    }
}


- (instancetype)us_valueForKeyPath:(NSString *)keyPath
{
    id original = [self mutableCopy];
    NSArray *divisionArray = [keyPath componentsSeparatedByString:@"."];
    NSString *tempKey = divisionArray[0];
    
    NSRange range = [keyPath rangeOfString:tempKey];
    NSString *spareStr = [keyPath substringFromIndex:range.length];
    if ([spareStr hasPrefix:@"."]) {
        spareStr = [spareStr substringFromIndex:1];
    }
    
    if ([original isKindOfClass:[NSDictionary class]]) {
        
        if ([tempKey hasSuffix:@"]"]&&[tempKey rangeOfString:@"["].length)
        {
            NSString *tempSufStr = [[tempKey componentsSeparatedByString:@"["] firstObject];
            NSRange range = [tempKey rangeOfString:tempSufStr];
            tempKey = [tempKey substringFromIndex:range.length];
            original = original[tempSufStr];
            
            if ([tempKey hasSuffix:@"]"]&&[tempKey hasPrefix:@"["]) {
                
                NSMutableArray *arrayKey = [[tempKey componentsSeparatedByString:@"["] mutableCopy];
                [arrayKey removeObjectAtIndex:0];
                
                for (int i = 0; i<arrayKey.count-1; i++) {
                    NSString *bracketStr = arrayKey[i];
                    if (![bracketStr hasSuffix:@"]"]) {
                        return nil;
                    }
                    
                    NSRange tempRange = [bracketStr rangeOfString:@"]"];
                    NSString *tempSpareStr = [bracketStr substringToIndex:tempRange.location];

                    
                    if ([tempSpareStr intValue] < 0)
                    {
                        return nil;
                    }

                    int tempI = [tempSpareStr intValue];
                    
                    if ([original isKindOfClass:[NSArray class]]&&((NSArray *)original).count>tempI) {
                        original = original[tempI];
                    }else{
                        return nil;
                    }
                 }
                
                if (![arrayKey[arrayKey.count-1] hasSuffix:@"]"]) {
                    return nil;
                }
                
                NSRange tempRange = [arrayKey[arrayKey.count-1] rangeOfString:@"]"];
                NSString *tempSpareStr = [arrayKey[arrayKey.count-1] substringToIndex:tempRange.location];

                if ([tempSpareStr intValue] < 0)
                {
                    return nil;
                }
                
                int k = [tempSpareStr intValue];
                
                if (![original isKindOfClass:[NSArray class]]) {
                    return nil;
                }

                if (((NSArray *)original).count<=k) {
                    return nil;
                }
                id dd = original[k];
                
                if (!spareStr.length) {
                    return dd;
                }else{
                    if ([dd isKindOfClass:[NSDictionary class]]) {
                        id bb = [dd us_valueForKeyPath:spareStr];
                         return bb;
                    }else {
                        return nil;
                    }
                 }
                
            }else{
                return nil;
            }
        }
        else {
            id dd = original[tempKey];
            
            if (!spareStr.length) {
                return dd;
            }else{
                if ([dd isKindOfClass:[NSDictionary class]]) {
                    id bb = [dd us_valueForKeyPath:spareStr];
                    return bb;
                }else{
                    return nil;
                }
            }
        }
    }
    else if ([original isKindOfClass:[NSArray class]]) {
        return nil;
        
    }else{
        return nil;
    }
}

@end
