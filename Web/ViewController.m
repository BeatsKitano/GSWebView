 
#import "ViewController.h"
#import "GSWebView.h"
#import <WebKit/WebKit.h>
#import <mach/mach.h>
#import "GSParentViewController.h"
#import <objc/runtime.h>


@interface ViewController ()<GSWebViewDelegate,GSWebViewJavaScript>
  
@property (nonatomic, strong) GSWebView * webView;

@end

@implementation ViewController

#define ADDRESS @"https://xe.easylinking.net:443/elinkWaiter/consultation/consultationAppIndex.do?userId=131812"
  
- (void)dealloc
{
    NSLog(@"释放成功");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:ADDRESS]];
    _webView = [[GSWebView alloc] initWithFrame:self.view.bounds JSPerformer:self];
    _webView.script = self;
    _webView.delegate = self;
    [self.view addSubview:_webView];
    [_webView loadRequest:req];
    
}

- (NSArray <NSString *>*)gswebViewRegisterObjCMethodNameForJavaScriptInteraction
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
    
    {
        /**
         *  用户ID通过注入JS代码完成
         */
        NSString *jsGetCurrentUserId = [NSString stringWithFormat:@"getCurrentUserId('%@')", @"131812"];
        [self.webView excuteJavaScript:jsGetCurrentUserId completionHandler:^(id  _Nonnull params, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"注入JS方法getCurrentUserId出错：%@",[error localizedDescription]);
            }else{
                NSLog(@"注入JS方法getCurrentUserId成功");
            }
        }];
        
    }
    
    {
        ////告诉服务端是否使用最新的WebView
        NSString * shouldUseLatestWebView = [NSString stringWithFormat:@"shouldUseLatestWebView('%@')", @"1"];;
   
        [self.webView excuteJavaScript:shouldUseLatestWebView completionHandler:^(id  _Nonnull params, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"注入JS方法shouldUseLatestWebView出错：%@",[error localizedDescription]);
            }else{
                NSLog(@"注入JS方法shouldUseLatestWebView成功");
            }
        }];
    }

}

- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"加载失败:%@",error);
}

- (void)getConsultationInfo:(NSDictionary *)param
{
    NSLog(@"JS传来参数:%@",param[@"id"]);
    
    NSURL * url = [NSURL URLWithString: [NSString stringWithFormat:@"https://xe.easylinking.net:10004/elinkWaiter/consultation/getConsultationInfo.do?consultationId=%@&userId=131812",param[@"id"]]];
    NSURLRequest * req = [NSURLRequest requestWithURL:url]; 
    [_webView loadRequest:req];
}
 
@end
