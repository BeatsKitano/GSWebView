 
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

#import <UIKit/UIKit.h>
 
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,GSWebViewNavigationType) {
    GSWebViewNavigationTypeLinkClicked,
    GSWebViewNavigationTypeFormSubmitted,
    GSWebViewNavigationTypeBackForward,
    GSWebViewNavigationTypeReload,
    GSWebViewNavigationTypeFormResubmitted,
    GSWebViewNavigationTypeOther
};

@protocol GSWebViewDelegate,GSWebViewJavaScript;

NS_CLASS_AVAILABLE(10_10, 7_0)
@interface GSWebView : UIView

@property (nonatomic, weak) id<GSWebViewDelegate> delegate;
@property (nonatomic, weak) id<GSWebViewJavaScript> script;

@property (nullable, nonatomic, readonly, strong) NSURLRequest *request;
@property (nullable, nonatomic, readonly, copy) NSString * title;

@property (nullable, nonatomic, copy) NSString * customAlertTitle;                      //当拦截到JS中的alter方法，自定义弹出框的标题
@property (nullable, nonatomic, copy) NSString * customConfirmTitle;                    //当拦截到JS中的confirm方法，自定义弹出框的标题
@property (nonatomic, assign, readonly) double estimatedProgress NS_AVAILABLE_IOS(8_0); //8.0才支持获取进度,8.0之下版本可以根据回调模拟虚假进度

@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

- (instancetype)new __IOS_PROHIBITED;
- (instancetype)init __IOS_PROHIBITED;

/**
  指定构造方法
 */
- (instancetype)initWithFrame:(CGRect)frame JSPerformer:(nonnull id)performer;

- (void)loadRequest:(NSURLRequest *)request;
  
/**
 1、*调用网页中的JS方法,可以取得该JS方法的返回值*
 2、*执行该方法时，务必要求网页中存在该JS方法，否则引发Creash*
 3、*倘若WebView整合在同一个文件中，服务端的公共JS文件必须拦截此方法*
 */
- (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler;

- (id)performer;

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;

/**
 *  此方法的调用建议写在“application:didFinishLaunchingWithOptions:”中
 *  App启动时移除掉所有缓存
 */
+ (void)removeAllGSWebViewCache;

@end

#pragma mark - Protocol

/**
 加载状态回调
 */
@protocol GSWebViewDelegate <NSObject>
@optional

- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error;

@end


/**
 交互协议
 */
@protocol GSWebViewJavaScript <NSObject>
@optional

/**
 调用OC方法
 
     - (NSArray<NSString *>*)gswebViewRegisterObjCMethodNameForJavaScriptInteraction
     {
        return @[@"getCurrentUserId"];
     }
     
     - (void)getCurrentUserId:(NSString *)Id
     {
        NSLong@(@"JS调用到OC%@",Id);
     }
 */
- (NSArray<NSString *>*)gswebViewRegisterObjCMethodNameForJavaScriptInteraction;

@end
  
NS_ASSUME_NONNULL_END
