//
//  ViewController.m
//  Web
//
//  Created by xiaohui on 2016/9/12.
//  Copyright © 2016年 xiaohui. All rights reserved.
//

#import "ViewController.h"
#import "GSWebView.h"
#import <WebKit/WebKit.h>
#import <mach/mach.h>
#import "GSParentViewController.h"


#define SuppressPerformSelectorLeakWarning(Stuff) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
 

@interface ViewController ()<GSWebViewDelegate>
  
@property (nonatomic, strong) GSWebView * webView;

@end

@implementation ViewController

#define ADDRESS @"http://t1.easylinking.net:10004/elinkWaiter/consultation/consultationAppIndex.do?userId=131812"
  
- (void)dealloc
{
    NSLog(@"释放成功");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:ADDRESS]];
    _webView = [[GSWebView alloc] initWithFrame:self.view.bounds delegate:self JSPerformer:self];
    [self.view addSubview:_webView];
    [_webView loadRequest:req];
}
 

- (NSArray <NSString *>*)gswebViewRegisterObjctiveCMethodsForJavaScriptInteraction
{
    return @[@"getConsultationInfo"];
}

- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType
{  
    return YES;
}

- (void)gswebViewDidStartLoad:(GSWebView *)webView
{
    NSLog(@"开始加载");
}

- (void)gswebViewDidFinishLoad:(GSWebView *)webView
{
    NSLog(@"加载成功");
    NSString * script = [NSString stringWithFormat:@"getCurrentUserId('131812')"];
    NSLog(@"%@",script);
    [_webView excuteJavaScript:script completionHandler:^(id  _Nonnull params, NSError * _Nonnull error) { 
    }];
}

- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"加载失败:%@",error);
}

- (void)getConsultationInfo:(NSString *)str
{
    NSLog(@"JS传来参数:%@",str);
    
    NSURL * url = [NSURL URLWithString: [NSString stringWithFormat:@"http://t1.easylinking.net:10004/elinkWaiter/consultation/getConsultationInfo.do?consultationId=%@&userId=131812",str]];
    NSURLRequest * req = [NSURLRequest requestWithURL:url]; 
    [_webView loadRequest:req];
}


@end
