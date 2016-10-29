<small>
1、在阅读过无数关于WebView的文章后，才有此文的出现。某种意义上，此文的初衷并非技术分享，而是对抄袭的不满。希望阅读此文的你是干干净净的。</br>
2、选择WebView作为第一篇技术文章的原因，是因为网络上众多对于第二代webview引擎的介绍不尽人意，且关于JS交互极为模糊，做事不该是做完整吗？倘若你想琢磨，可在源码中一窥究竟。</br>
3、如果你有更加高明的思路，请Email：xorshine@icloud.com，或者在github上说明。</br>
4、[GSWebView下载地址](https://github.com/xorshine/GSWebView.git)      [GSWebView文档](https://github.com/xorshine/GSWebView)</br>
5、阿弥陀佛......
</small>
***
### 1.为何要从UIWebView更新到WKWebView？
你真的以为平白无故的废弃UIWebView？WKWebView真有那么好？
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

***
#### 2.鱼龙混杂的年代，还能像如UIWebView一样使用GSWebView吗？当然可以
* 当无数的类堆积的时候，到底是OOP还是POP，当你看到WKWebView时，GSWebView才会成为你的真爱，WKWebView的设计......哎，但性能好才是真的好！
* GSWebView并非只是集成了UIWebView和WKWebView,它被设计成与UIWebView几乎相似，意在降低开发者的使用难度。
* 引入WebKit与JavaScriptCore库，就可开始使用GSWebView。

##### 使用介绍：同样都是WebView，同样的款式，GSWebView如何打造不一样的内涵与代码体验？
 
熟悉的属性、方法
```objective-c
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward; 

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
//......and so on
```

形神皆似的协议方法
```objective-c
#prama mark - GSWebViewDelegate
- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error;  
```

#### 3.GSWebView的JavaScript交互
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
#### 4.注意事项
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

#### 5.不要吝惜你的建议
像泡利一样批评GSWebView吧！谢谢。
 
![](https://i.creativecommons.org/l/by-nc-nd/3.0/cn/88x31.png)
本作品采用采用[知识共享署名-非商业性使用-禁止演绎 3.0 中国大陆许可协议进行许可](http://creativecommons.org/licenses/by-nc-nd/3.0/cn/)
* * *
