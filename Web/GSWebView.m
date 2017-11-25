
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
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
#import <WebKit/WebKit.h>
#endif

#define IgnorePerformSelectorLeakWarning(code) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wnonnull\"") \
code \
_Pragma("clang diagnostic pop")

#define IgnoreSelectorWarning(code) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"--Wundeclared-selector\"") \
code \
_Pragma("clang diagnostic pop")


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

@interface GSWebView ()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler,UIWebViewDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic) BOOL canGoBack;
@property (nonatomic) BOOL canGoForward;

@property (strong, nonatomic) UIView * webView;

@end

@interface GSWebView (GSPrivateMethod)

- (void)excuteJavaScriptWithMethodName:(NSString *)name parameter:(id)param;
- (void)excuteFuncWithName:(NSString *)name;

@end

@implementation GSWebView
{
    NSPointerArray * _pointers;
    
    NSURLConnection *_urlConnection;
    BOOL _authenticated;
}

- (void)dealloc
{
    if ([_webView isKindOfClass:[UIWebView class]]) {
        ((UIWebView *)_webView).delegate = nil;
        [((UIWebView *)_webView) loadHTMLString:@"" baseURL:nil];
        [((UIWebView *)_webView) stopLoading];
        [_webView removeFromSuperview];
	}else{
		if (self.delegate && [self.script respondsToSelector:@selector(gswebViewRegisterObjCMethodNameForJavaScriptInteraction)]) {
			__weak typeof(self) weakSelf = self;
			[[self.script gswebViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:
			 ^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
				 __strong typeof(weakSelf) strongSelf = weakSelf;
				 WKWebView * wk = (WKWebView *)strongSelf.webView;
				 [(wk.configuration).userContentController removeScriptMessageHandlerForName:name];
			 }];
		}
	}
}

- (instancetype)initWithFrame:(CGRect)frame
{
    IgnorePerformSelectorLeakWarning(return [self initWithFrame:frame JSPerformer:nil];)
}

static long const kGSJSValueKey    = 1100;
static long const kGSJSContextKey  = 1000;

- (JSContext *)jsContext
{
    return objc_getAssociatedObject(self, &kGSJSContextKey);
}

- (JSValue *)jsValue
{
    return objc_getAssociatedObject(self, &kGSJSValueKey);
}

- (instancetype)initWithFrame:(CGRect)frame JSPerformer:(nonnull id)performer
{
    if (self = [super initWithFrame:frame]) {
        _pointers = [NSPointerArray weakObjectsPointerArray];
        [_pointers addPointer:(__bridge void * _Nullable)(performer)];
        if ([UIDevice currentDevice].systemVersion.doubleValue >= 9.0){
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
    if ([_webView isKindOfClass:[WKWebView class]])
        [(WKWebView *)_webView loadRequest:request];
    [(UIWebView *)_webView loadRequest:request];
}

- (void)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    if ([_webView isKindOfClass:[WKWebView class]])
        [(WKWebView *)_webView loadHTMLString:string baseURL:baseURL];
    [(UIWebView *)_webView loadHTMLString:string baseURL:baseURL];
}

- (id)performer
{
    return [_pointers pointerAtIndex:0];
}

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

- (void)setDataDetectorTypes:(GSDataDetectorTypes)dataDetectorTypes
{
    if ([_webView isKindOfClass:[UIWebView class]]){
        ((UIWebView *)_webView).dataDetectorTypes = (UIDataDetectorTypes)dataDetectorTypes;
    }else{
        if ([((WKWebView *)_webView).configuration respondsToSelector:@selector(setDataDetectorTypes:)]) {
            [((WKWebView *)_webView).configuration setDataDetectorTypes:(WKDataDetectorTypes)dataDetectorTypes];
        } 
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0)
    {
        _authenticated = YES;
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    else
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _authenticated = YES;
    [(UIWebView *)_webView loadRequest:_request];
    [_urlConnection cancel];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}


/***********************************************************************************************************************/

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (!_authenticated) {
        _authenticated = NO;
        _urlConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
        [_urlConnection start];
    }
    
    if ([self.delegate respondsToSelector:@selector(gswebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate gswebView:self shouldStartLoadWithRequest:request navigationType:(GSWebViewNavigationType)navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([self.delegate respondsToSelector:@selector(gswebViewDidStartLoad:)]) {
        [self.delegate gswebViewDidStartLoad:self];
    }
}

static NSString * const kJavaScriptContext = @"documentView.webView.mainFrame.javaScriptContext";
static NSString * const kDocumentTitle = @"document.title";

- (void)generateTitle
{
    _title = [(UIWebView *)_webView stringByEvaluatingJavaScriptFromString:kDocumentTitle];
}

- (void)bindingCtxAndValue
{
    JSContext * JSCtx = [(UIWebView *)_webView valueForKeyPath:kJavaScriptContext];
    JSValue * JSVlu = [JSCtx globalObject];
    objc_setAssociatedObject(self, &kGSJSValueKey, JSVlu, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,&kGSJSContextKey, JSCtx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    [self generateTitle];
    [self bindingCtxAndValue];
    
    if([self.script respondsToSelector:@selector(gswebViewRegisterObjCMethodNameForJavaScriptInteraction)]){
        __weak typeof(self) weakSelf = self;
        [[self.script gswebViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:
         ^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
             __strong typeof(weakSelf) strongSelf = weakSelf;
             strongSelf.jsContext[name] = ^(id body){
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [strongSelf excuteJavaScriptWithMethodName:name parameter:body];
                 });
             };
         }];
    }
    if ([self.delegate respondsToSelector:@selector(gswebViewDidFinishLoad:)]) {
        [self.delegate gswebViewDidFinishLoad:self];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(gswebView:didFailLoadWithError:)]) {
        [self.delegate gswebView:self didFailLoadWithError:error];
    }
}

- (double)estimatedProgress
{
    return ((WKWebView *)_webView).estimatedProgress;
}

#pragma mark - WKWebView

//该方法在iOS 8系统下不能调用
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0)
        {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIViewController * currentVC = [self getTopViewController];
    if (currentVC) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.pageAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler();
        }]];
        [currentVC presentViewController:alert animated:YES completion:NULL];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.pageConfirmTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{  
    BOOL isNavigator = YES;
    if ([self.delegate respondsToSelector:@selector(gswebView:shouldStartLoadWithRequest:navigationType:)])
    {
        isNavigator = [self.delegate gswebView:self shouldStartLoadWithRequest:navigationAction.request navigationType:(GSWebViewNavigationType)(navigationAction.navigationType < 0? navigationAction.navigationType : 5)];
    }
    
    if (!isNavigator) {
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
        [self.delegate gswebView:self didFailLoadWithError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    _title = webView.title;
    if (self.delegate && [self.script respondsToSelector:@selector(gswebViewRegisterObjCMethodNameForJavaScriptInteraction)]) {
        __weak typeof(self) weakSelf = self;
        [[self.script gswebViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:
         ^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) { 
             __strong typeof(weakSelf) strongSelf = weakSelf;
             [webView.configuration.userContentController removeScriptMessageHandlerForName:name];
             [webView.configuration.userContentController addScriptMessageHandler:strongSelf name:name];
         }];
    }
    if ([self.delegate respondsToSelector:@selector(gswebViewDidFinishLoad:)]){
        [self.delegate gswebViewDidFinishLoad:self];
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self excuteJavaScriptWithMethodName:message.name parameter:message.body];
}

#pragma mark -

- (void)configureWKWebViewWithFrame:(CGRect)frame
{
    WKWebView * web = [[WKWebView alloc] initWithFrame:frame configuration:[[GSWebViewConfiguration alloc] init]];
    web.UIDelegate = self;
    web.navigationDelegate = self;
    web.allowsBackForwardNavigationGestures = YES;
    _scrollView = web.scrollView;
    _webView = web;
    [self addSubview:_webView];
}

- (void)configureUIWebViewWithFrame:(CGRect)frame
{
    UIWebView * web = [[UIWebView alloc] initWithFrame:frame];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wundeclared-selector"
    [NSClassFromString(@"WebCache") performSelector:@selector(setDisabled:) withObject:[NSNumber numberWithBool:YES] afterDelay:0];
#pragma clang diagnostic pop
    web.delegate = self;
    _scrollView = web.scrollView;
    _webView = web;
    [self addSubview:_webView];
}

- (UIViewController *)getTopViewController
{
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
    UIViewController * top = nil;
    if ([nextResponder isKindOfClass:[UIViewController class]])
        top = nextResponder;
    else
        top = window.rootViewController;
    return top;
}

@end

#pragma mark - Navigation

@implementation GSWebView (Navigation)

- (BOOL)isLoading
{
    if ([_webView isKindOfClass:[UIWebView class]])
        return [((UIWebView *)_webView) isLoading];
    return [((WKWebView *)_webView) isLoading];
}

- (BOOL)canGoBack
{
    if ([_webView isKindOfClass:[UIWebView class]])
        return [((UIWebView *)_webView) canGoBack];
    return [((WKWebView *)_webView) canGoBack];
}

- (BOOL)canGoForward
{
    if ([_webView isKindOfClass:[UIWebView class]])
        return [((UIWebView *)_webView) canGoForward];
    return [((WKWebView *)_webView) canGoForward];
}


#define ExcuteMethodWith(name) \
[self excuteFuncWithName:name]

- (void)reload
{
    ExcuteMethodWith(@"reload");
}

- (void)stopLoading
{
    ExcuteMethodWith(@"stopLoading");
}

- (void)goBack
{
    ExcuteMethodWith(@"goBack");
}

- (void)goForward
{
    ExcuteMethodWith(@"goForward");
}

@end
 
#pragma mark - GSPrivateMethod

@implementation GSWebView (GSPrivateMethod)

typedef void (*GSFunctionPointWithParam)(id, SEL, id);
typedef void (*GSFunctionPointNoParam)(id, SEL);

- (void)excuteJavaScriptWithMethodName:(NSString *)name parameter:(id)param
{
    if (!self.performer) return;
    
    SEL selector;
    if ([param isKindOfClass:[NSString class]] && [param isEqualToString:@""])
        selector = NSSelectorFromString(name);
    else
        selector = NSSelectorFromString([name stringByAppendingString:@":"]);
    
    if ([self.performer respondsToSelector:selector])
    {
        IMP imp = [self.performer methodForSelector:selector];
        if (param)
        {
            GSFunctionPointWithParam f = (void *)imp;
            f(self.performer, selector,param);
        }
        else
        {
            GSFunctionPointNoParam f = (void *)imp;
            f(self.performer, selector);
        }
    }
}

- (void)excuteFuncWithName:(NSString *)name
{
    SEL selector = NSSelectorFromString(name);
    if ([_webView respondsToSelector:selector]) {
        dispatch_block_t block = ^(void){
            IMP imp = [_webView methodForSelector:selector];
            GSFunctionPointNoParam pfunc = (void *)imp;
            pfunc(_webView, selector);
        };
        if ([[NSThread currentThread] isMainThread]) {
            block();
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                block();
            });
        }
    }
}

@end
