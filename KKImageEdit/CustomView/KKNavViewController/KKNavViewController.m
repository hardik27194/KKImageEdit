//
//  KKNavViewController.m
//
//  Created by finger on 15/3/11.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKNavViewController.h"

@interface KKNavViewController ()
{
}

@end

@implementation KKNavViewController

+(void)initialize
{
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    
    //设置文字样式
    [navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,[UIFont fontWithName:@"Helvetica Blod" size:18],NSFontAttributeName, nil]];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (UIBarButtonItem *)createBackItemWithTitle:(NSString *)title
{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    backButton.frame = CGRectMake(0, 0, 12, 20);
    if (title != nil){
        backButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        [backButton setTitle:title forState:UIControlStateNormal];
        [backButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    }
    [backButton setImage:[UIImage imageNamed:@"backItem"] forState:UIControlStateNormal];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0,5,0, 0)];
    [backButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin];
    [backButton addTarget:self action:@selector(popSelf) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    return backItem;
}

- (void)popSelf
{
    [self popViewControllerAnimated:YES];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    
    if (viewController.navigationItem.leftBarButtonItem == nil && self.viewControllers.count>1){
        NSArray *controllers = self.viewControllers;
        NSString *parentTitle = [[[controllers objectAtIndex:controllers.count - 2] navigationItem] title];
        viewController.navigationItem.leftBarButtonItem = [self createBackItemWithTitle:parentTitle];
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect rcImage = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rcImage.size);
    CGContextRef contect = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(contect, [UIColor colorWithRed:16.0/255.0 green:157.0/255.0 blue:213.0/255.0 alpha:1.0].CGColor);
    CGContextFillRect(contect, rcImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    float iosVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iosVersion<8.0 && iosVersion >= 7.0){
        [self.navigationBar setBackgroundImage:image forBarPosition:UIBarPositionTopAttached barMetrics:UIBarMetricsDefault];
    }else{
        [self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
    
    [self.navigationBar setShadowImage:[[UIImage alloc]init]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -- 屏幕旋转

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO ;
}

- (BOOL)shouldAutorotate
{
    return NO ;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait ;
}

@end
