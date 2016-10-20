<small>如果你有更加高明的思路，请Email：xorshine@icloud.com，或者在github上说明。
</small>
***
### 1.为何要从UIWebView更新到WKWebView？
######  性能测试：
|           	  | UIWebView              | WKWebView                 |    备注               |
|:---------------:|:----------------------:|:-------------------------:|:--------------------:|
| iOS 版本     	  | 8.4                    | 8.4                       |        ———           |
| iPhone     	  | 6                      |   6                       |       真机测试         |
| 测试网页         |[天猫首页](http://www.tmall.com)|[天猫首页](http://www.tmall.com) |———|
| 内存占用峰值      | 132.2MB                |    8.4MB                  |———|
| 加载耗时	 	  | 3.1s                   |    2.6s                   |  mach_absolute_time(); |
| FPS	 		  | 无明显差异            |    无明显差异               |  Instruments (core animation) |
| 测试次数	 	  | 2                      |    2                      |———|

单<font size=4>内存占用</font>这一点考虑，使用WKWebView便是明智的选择。
***
#### 2.如UIWebView一样使用WKWebView，用熟悉的API开发
* GSWebView被设计成UIWebView相同的样式，意在降低开发者的使用难度。
##### 使用介绍：同样的款式如何打造不一样的内涵？
 
熟悉的属性、方法
```objective-c
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward; 

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
```

形神皆似的协议方法
```objective-c
#prama mark - GSWebViewDelegate
- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error;  
```

JS交互重点
GSWebView定义了两套协议GSWebViewDelegate和GSWebViewJavaScript，GSWebViewDelegate定义了加载状态，GSWebViewJavaScript则只定义了JS交互。
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
     //当JS调用一个'- (void)getCurrentUserName:(NSString *)name'的OC方法时，参数name由JS传来，
     //那么在实现该OC方法时，只需要正确知道参数类型或基本结构，你也可以写为id类型做普适，在方法内部做转换。
     - (void)getCurrentUserId:(NSString *)Id
     {
        NSLong@(@"JS调用到OC%@",Id);
     }
 */
- (NSArray<NSString *>*)gswebViewRegisterObjCMethodNameForJavaScriptInteraction;

@end
```
* * *
#### 3.服务端JavaScript源码必须的改动
* 改动并非是为了增加复杂度，而是GSWebView内部的WKWebView必须通过Apple.Inc指定的方法  

> Adding a scriptMessageHandler adds a function window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all frames.

举例说明：
JS中有一个getConsultationInfo(id)方法,客户端获取到id实现该方法，这是UIWebView时代
但是在GSWebView中，必须这样:
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
* * * 
#### 4.提醒与注意事项
如果之前使用了UIWebView，如今使用GSWebView，在服务端对JS源码做出改动后，必须要考虑客户端老版本的q兼容情况。在下有个建议：
```objective-c
NSString * shouldUseLatestWebView;
if (ELIS_IOS_8) {
    shouldUseLatestWebView = [NSString stringWithFormat:@"shouldUseLatestWebView('%@')", @"1"];
}else{
    shouldUseLatestWebView = [NSString stringWithFormat:@"shouldUseLatestWebView('%@')", @"0"];
} 
[self.webview excuteJavaScript:jsGetCurrentUserId completionHandler:^(id  _Nonnull params, NSError * _Nonnull error) {
     if (error) {
   	 WJLog(@"注入JS方法shouldUseLatestWebView出错：%@",[error localizedDescription]);
    }
}];
```
直接告诉服务端是否使用最新的交互方式：
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

<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/"><img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/3.0/cn/88x31.png" /></a><br />本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/">知识共享署名-非商业性使用-禁止演绎 3.0 中国大陆许可协议</a>进行许可。
* * *
