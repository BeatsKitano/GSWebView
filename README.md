#### Podfile

To integrate GSWebView into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
target 'TargetName' do
pod 'GSWebView'
end
```

Then, run the following command:

```bash
$ pod install
```

### 1.背景

   WKWebView 是苹果在iOS 8中引入的新组件，目的是提供一个现代的支持最新Webkit功能的网页浏览控件，摆脱过去 UIWebView的老、旧、笨，特别是内存占用量巨大的问题。它使用与Safari中一样的Nitro JavaScript引擎，大大提高了页面js执行速度。

***
### 2.使用指南  
* GSWebView的使用被设计成与UIWebView几乎相似，意在降低开发者的使用难度。
* 引入WebKit与JavaScriptCore库，就可开始使用GSWebView。 
 
熟悉的属性、方法
```objective-c
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward; 

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
//......
```

形神皆似的协议方法
```objective-c
#prama mark - GSWebViewDelegate
- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error;  
```
***
### 3.GSWebView的JavaScript交互指南
* GSWebView定义了两套协议GSWebViewDelegate和GSWebViewJavaScript，GSWebViewDelegate定义了加载状态，GSWebViewJavaScript则只定义了JS交互。
* 当你把方法名就这么一传，连参数都不要，回调自然完成，真自然，丝滑般自然......

```objective-c
#prama mark - GSWebViewJavaScript
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

```
 
* 改动并非是为了增加复杂度，而是GSWebView内部的WKWebView必须通过Apple.Inc指定的方法  

> Adding a scriptMessageHandler adds a function window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all frames.

EXAMPLE：
JS调用客户端getConsultationInfo:方法,客户端获取到id实现该方法，苹果🍎要求必须这样做:
```javascript
//获取客户端iOS版本
var version = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/);  
version = parseInt(ver[1], 10);  

if(version >= 7.0 && version < 8.0){
	getConsultationInfo(id);
}else if(version>=8.0){
	window.webkit.messageHandlers.getConsultationInfo.postMessage(id)
} 
```
这不是贫僧的错，要怪就怪🍎......
* * * 
### 4.注意事项
如果之前使用了UIWebView，如今使用GSWebView，在服务端对JS源码做出改动后，必须要考虑客户端老版本的兼容情况。当改动服务端的JS代码，势必导致老版本中的UIWebView交互失效。在下有个建议：
当GSWebView加载成功，我们调用服务端预先写好的方法 function shouldUseLatestWebView(isBool);
```objective-c
NSString * shouldUseLatestWebView;
if (IS_IOS_8) {
    shouldUseLatestWebView = [NSString stringWithFormat:@"shouldUseLatestWebView('%@')", @"1"];
}else{
    shouldUseLatestWebView = [NSString stringWithFormat:@"shouldUseLatestWebView('%@')", @"0"];
} 
[self.webview excuteJavaScript:jsGetCurrentUserId completionHandler:^(id  _Nonnull params, NSError * _Nonnull error) {
     if (error) {
   	 NSLog(@"注入JS方法shouldUseLatestWebView出错：%@",[error localizedDescription]);
    }
}];
```
服务端用一个全局变量保存isBool的值，当isBool为字符串1时，说明需要使用的是第二代WebView，服务端必须使用最新的交互方式代码，如果为字符串0或者空，则依旧使用原来的代码交互：
```javascript
//一个全局的变量
var isBool = "";

function shouldUseLatestWebView(isBool){ 
	isBool = isBool;
}

if(isBool == "0" || isBool == ""){ 
	getConsultationInfo(id); 
}else if(isBool == "1"){ 
 	window.webkit.messageHandlers.getConsultationInfo.postMessage(id);
} 
```
如此一来，就可以做到老版本的兼容。 

### 5.HTTPs支持
  
  GSWebView已经在最后一个版本中支持HTTPs。
 
 * * *
![](https://i.creativecommons.org/l/by-nc-nd/3.0/cn/88x31.png)
本作品采用采用[知识共享署名-非商业性使用-禁止演绎 3.0 中国大陆许可协议进行许可](http://creativecommons.org/licenses/by-nc-nd/3.0/cn/)
* * *
