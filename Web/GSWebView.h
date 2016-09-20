//
//  GSWebView.h
//  Web
//
//  Created by xiaohui on 2016/9/18.
//  Copyright © 2016年 xiaohui. All rights reserved.
//

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

@protocol GSWebViewDelegate;
@class WKWebView,WKFrameInfo;

NS_CLASS_AVAILABLE(10_10, 7_0)
@interface GSWebView : UIView

@property (nonatomic, weak) id<GSWebViewDelegate> delegate;

@property (nullable, nonatomic, readonly, strong) NSURLRequest *request;
@property (nullable, nonatomic, readonly, copy) NSString * title;

@property (nullable, nonatomic, copy) NSString * customAlertTitle;    //当拦截到JS中的alter方法，自定义弹出框的标题
@property (nullable, nonatomic, copy) NSString * customConfirmTitle;  //当拦截到JS中的confirm方法，自定义弹出框的标题

@property (nonatomic, assign, readonly) double estimatedProgress;
  
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;


/**
 指定构造方法
 */
- (instancetype)initWithFrame:(CGRect)frame delegate:(nonnull id<GSWebViewDelegate>)delegate JSPerformer:(nonnull id)performer;

- (void)loadRequest:(NSURLRequest *)request;
  
/**
 执行JavaScript方法

 @param function
 @param completionHandler 
 */
- (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler;

- (id)performer;

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;

@end


@protocol GSWebViewDelegate <NSObject>

@optional
- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(nullable NSError *)error;

/**
 *  需要拦截的JavaScript方法
 */
- (NSArray<NSString *>*)gswebViewNeedInterceptJavaScript;

@end

@interface GSWebView (ExcuteFunction)

- (void)excuteJavaScriptFunctionWithName:(NSString *)name parameter:(id)param;
- (id)excuteFuncWithName:(NSString *)name; 

@end

NS_ASSUME_NONNULL_END
