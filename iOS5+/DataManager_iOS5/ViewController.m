//
//  ViewController.m
//  DataManager_iOS5
//
//  Created by 马汝军 on 14-3-22.
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
    
//    //重置数据库
    [[NLCoreData shared] resetDatabase];

//    /* 像User表插入一条数据 */
    NSDictionary *userDic = @{@"name":@"jizhi",@"age":@(23)};
    User *user = [User insertObjectWithDictionary:userDic];
    
    Bank *bank1 = [Bank objectWithDictionary:@{@"account":@"444444"}];
    Bank *bank2 = [Bank objectWithDictionary:@{@"account":@"555555"}];
    [user.managedObjectContext insertObject:bank1];
    [user.managedObjectContext insertObject:bank2];
    bank1.user = user;
    bank2.user = user;
    
//    [user remove];
    /* 查询User表中的所有记录 */
    NSLog(@"array ----> %@",[User fetchAllObjects]);
    
//    [self downloadImage];
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
