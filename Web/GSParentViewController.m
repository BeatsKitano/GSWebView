//
//  GSParentViewController.m
//  Web
//
//  Created by xiaohui on 2016/9/21.
//  Copyright © 2016年 xiaohui. All rights reserved.
//

#import "GSParentViewController.h"
#import "ViewController.h"

@interface GSParentViewController ()

@end

@implementation GSParentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    ViewController * vc = [[ViewController alloc] init];
     
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)test
{
    NSLog(@"GSParentViewController 内部方法成功调用");
}

@end
