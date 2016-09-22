
//    Copyright © 2011-2016 向小辉. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

#import "GSWebView.h"
#import <JavaScriptCore/JavaScriptCore.h> 
#import <objc/runtime.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#import <WebKit/WebKit.h>
#endif

@interface GSWebViewConfiguration : WKWebViewConfiguration @end

@implementation GSWebViewConfiguration

- (instancetype)init
{
    if (self = [super init]) {
        self.userContentController = [[WKUserContentController alloc] init];
        self.allowsInlineMediaPlayback = YES;
        self.preferences.minimumFontSize = 10;
        self.processPool = [[WKProcessPool alloc]init];
        self.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    }
    return self;
}

@end

/***********************************************************************************************************************************************/

@interface GSWebView () @end

@implementation GSWebView
{
    NSPointerArray * _pointers;
    UIView * _webView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    return [self initWithFrame:frame delegate:nil JSPerformer:nil];
#pragma clang diagnostic pop 
}

static long const GSJSValueKey    = 1100;
static long const GSJSContextKey  = 1000;

- (JSContext *)jsContext
{
    return objc_getAssociatedObject(self, &GSJSContextKey);
}

- (JSValue *)jsValue
{
    return objc_getAssociatedObject(self, &GSJSValueKey);
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<GSWebViewDelegate>)delegate JSPerformer:(id)performer
{
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
        _pointers = [NSPointerArray weakObjectsPointerArray];
        [_pointers addPointer:(__bridge void * _Nullable)(performer)]; 
        if ([UIDevice currentDevice].systemVersion.doubleValue >= 8.0) {
            [self configureWKWebViewWithFrame:frame];
        }else{
            [self configureUIWebViewWithFrame:frame];
        }
    }
    return self;
}

- (void)loadRequest:(NSURLRequest *)request
{
    _request = request;
    if ([_webView isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)_webView loadRequest:request];
    }else{
        [(UIWebView *)_webView loadRequest:request];
    }
}

- (id)performer
{
    return [_pointers pointerAtIndex:0];
}

//执行JS并且有回调
- (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler
{
    if ([_webView isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)_webView evaluateJavaScript:javaScriptString completionHandler:^(id param, NSError * error){
            if (completionHandler) {
                completionHandler(param,error);
            }
        }];
    }else{ 
       JSValue * value = [self.jsContext evaluateScript:javaScriptString];
        if (value && completionHandler) {
            completionHandler([value toObject],NULL);
        }
    }
}

- (BOOL)isLoading
{
    return (BOOL)[self excuteFuncWithName:@"isLoading"];
}

- (void)reload
{
    [self excuteFuncWithName:@"reload"];
}

- (void)stopLoading
{
    [self excuteFuncWithName:@"stopLoading"];
}

- (void)goBack
{
    [self excuteFuncWithName:@"goBack"];
}

- (void)goForward
{
    [self excuteFuncWithName:@"goForward"];
}

+ (void)removeAllGSWebViewCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

/***********************************************************************************************************************************************/

#pragma mark - __IPHONE_7_0 --> UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self.delegate respondsToSelector:@selector(gswebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate gswebView:(GSWebView *)_webView shouldStartLoadWithRequest:request navigationType:(GSWebViewNavigationType)navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([self.delegate respondsToSelector:@selector(gswebViewDidStartLoad:)]) {
        [self.delegate gswebViewDidStartLoad:(GSWebView *)_webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    JSContext * JSCtx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    JSValue * JSVlu = [JSCtx globalObject];
    objc_setAssociatedObject(self, &GSJSValueKey, JSVlu, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,&GSJSContextKey, JSCtx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    _title = [(UIWebView *)_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
     
    if([self.delegate respondsToSelector:@selector(gswebViewRegisterObjCMethodNameForJavaScriptInteraction)]){
        [[self.delegate gswebViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            __weak typeof(self) weakSelf = self;
            self.jsContext[name] = ^(id body){
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf excuteJavaScriptFunctionWithName:name parameter:body];
                });
            };
        }];
    }
    if ([self.delegate respondsToSelector:@selector(gswebViewDidFinishLoad:)]) {
        [self.delegate gswebViewDidFinishLoad:(GSWebView *)_webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(gswebView:didFailLoadWithError:)]) {
        [self.delegate gswebView:(GSWebView *)_webView didFailLoadWithError:error];
    }
}

- (double)estimatedProgress
{
    return ((WKWebView *)_webView).estimatedProgress;
}

/***********************************************************************************************************************************************/

#pragma mark - __IPHONE_8_0 --> WKWebView

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIViewController * currentVC = [self currentViewController];
    if (currentVC) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.customAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler();
        }]];
        [currentVC presentViewController:alert animated:YES completion:NULL];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.customConfirmTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    BOOL decision = YES;
    if ([self.delegate respondsToSelector:@selector(gswebView:shouldStartLoadWithRequest:navigationType:)]) {
        decision = [self.delegate gswebView:self shouldStartLoadWithRequest:navigationAction.request navigationType:(GSWebViewNavigationType)navigationAction.navigationType];
    }
    if (!decision) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if ([self.delegate respondsToSelector:@selector(gswebViewDidStartLoad:)]) {
        [self.delegate gswebViewDidStartLoad:self];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(gswebView:didFailLoadWithError:)]) {
        [self.delegate gswebView:(GSWebView *)_webView didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    _title = webView.title; 
    if (self.delegate && [self.delegate respondsToSelector:@selector(gswebViewRegisterObjCMethodNameForJavaScriptInteraction)]) {
        [[self.delegate gswebViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            [webView.configuration.userContentController removeScriptMessageHandlerForName:name];
            [webView.configuration.userContentController addScriptMessageHandler:(id<WKScriptMessageHandler>)self name:name];
        }];
    }
    if ([self.delegate respondsToSelector:@selector(gswebViewDidFinishLoad:)]){
        [self.delegate gswebViewDidFinishLoad:(GSWebView *)_webView];
    }
}

/**
 *  JS调用OC
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self excuteJavaScriptFunctionWithName:message.name parameter:message.body];
}

/***********************************************************************************************************************************************/

- (void)configureWKWebViewWithFrame:(CGRect)frame
{
    WKWebView * web = [[WKWebView alloc] initWithFrame:frame configuration:[[GSWebViewConfiguration alloc] init]];
    Protocol * GSWKUIDelegate = objc_allocateProtocol("WKUIDelegate");
    [self registerProtocol:GSWKUIDelegate];
    Protocol * GSWKNavigationDelegate = objc_allocateProtocol("WKNavigationDelegate");
    [self registerProtocol:GSWKNavigationDelegate];
    Protocol * GSWKScriptMessageHandler = objc_allocateProtocol("WKScriptMessageHandler");
    [self registerProtocol:GSWKScriptMessageHandler];
    
    web.UIDelegate = (id<WKUIDelegate>)self;
    web.navigationDelegate = (id<WKNavigationDelegate>)self;
    web.allowsBackForwardNavigationGestures = YES;
    _scrollView = web.scrollView;
    _webView = web;
    [self addSubview:_webView];
}

- (void)configureUIWebViewWithFrame:(CGRect)frame
{
    UIWebView * web = [[UIWebView alloc] initWithFrame:frame];
    Protocol * GSUIWebViewDelegate = objc_allocateProtocol("UIWebViewDelegate");
    [self registerProtocol:GSUIWebViewDelegate];
    web.delegate = (id<UIWebViewDelegate>)self;
    _scrollView = web.scrollView;
    _webView = web;
    [self addSubview:_webView];
}

- (void)registerProtocol:(Protocol *)protocol
{
    if (protocol) {
        objc_registerProtocol(protocol);
        class_addProtocol([GSWebView class], protocol)?:NSLog(@"动态绑定协议失败");
    }
}
  
- (UIViewController *)currentViewController{
    UIViewController *vc = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * win in windows) {
            if (win.windowLevel == UIWindowLevelNormal) {
                window = win;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] firstObject];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
        vc = nextResponder;
    else
        vc = window.rootViewController;
    return vc;
}

- (void)excuteJavaScriptFunctionWithName:(NSString *)name parameter:(id)param
{
    if (self.performer) {
        SEL selector;
        if ([param isKindOfClass:[NSString class]] && [param isEqualToString:@""])
            selector = NSSelectorFromString(name);
        else
            selector = NSSelectorFromString([name stringByAppendingString:@":"]);
  
        if ([self.performer respondsToSelector:selector]){
            IMP imp = [self.performer methodForSelector:selector];
            if (param){
                typedef void (*func)(id, SEL, id);
                func f = (void *)imp;
                f(self.performer, selector,param);
            }
            else{
                typedef void (*func)(id, SEL);
                func f = (void *)imp;
                f(self.performer, selector);
            }
        }
    }
}
 
- (id)excuteFuncWithName:(NSString *)name
{
    SEL selector = NSSelectorFromString(name);
    if ([_webView respondsToSelector:selector]) {
        IMP imp = [_webView methodForSelector:selector];
        id (*func)(id, SEL) = (void *)imp;
        return (id)func(_webView, selector);
    }
    return nil;
}

@end
