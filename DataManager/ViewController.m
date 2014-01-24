//
//  ViewController.m
//  DataManager
//
//  Created by 马汝军 on 14-1-23.
//  Copyright (c) 2014年 marujun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //使用方法如下：model中有2个表User、Bank；其中User表中的RelationShip：user对应多条Bank记录
    
    /* 清空User表 */
    [NSManagedObject cleanTable:NSStringFromClass([User class])];
    
    /* 像User表插入一条数据 */
    NSDictionary *userDic = @{@"name":@"jizhi",@"age":@(23),@"bank":@[@{@"account":@"111111"},@{@"account":@"222222"}]};
    User *user = (User *)[NSManagedObject addObject_sync:userDic toTable:NSStringFromClass([User class])];
    NSLog(@"user ----> %@",user);
    
    /* 修改刚刚插入的数据 */
    userDic = @{@"name":@"jizhi",@"age":@(23),@"bank":@[@{@"account":@"444444"},@{@"account":@"555555"},@{@"account":@"666666"}]};
    user = (User *)[NSManagedObject updateObject_sync:user params:userDic];
    NSLog(@"user ----> %@",user);
    
    /* 查询User表中的所有记录 */
    NSArray *array = [NSManagedObject getTable_sync:NSStringFromClass([User class]) predicate:nil];
    NSLog(@"array ----> %@",[array firstObject]);
    
    [self downloadImage];
}

- (void)downloadImage
{
    /*  使用示例 */
    NSString *url = @"http://image.tianjimedia.com/uploadImages/2013/309/43U9QN353KB7.jpg";
    
    //缓存图片
//    [UIImage imageWithURL:url process:^(int64_t readBytes, int64_t totalBytes) {
//        NSLog(@"下载进度 ： %.0f%%",100*readBytes/totalBytes);
//    } callback:^(UIImage *image) {
//        NSLog(@"图片下载完成！");
//    }];
    
    //设置UIImageView的图片，下载失败则使用默认图片
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    [imageView setImageURL:url defaultImage:[UIImage imageNamed:@"default.jpg"]];
//    imageView.contentMode = UIViewContentModeScaleAspectFit;
//    [self.view addSubview:imageView];
    
    //设置UIButton的图片，下载失败则使用默认图片
    UIButton *button = [[UIButton alloc] initWithFrame:self.view.bounds];
    [button setImageURL:url forState:UIControlStateNormal defaultImage:[UIImage imageNamed:@"default.jpg"]];
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
