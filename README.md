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
* iOS8之前，UIWebView与JavaScriptCore框架基本完成了客户端网页操作。简单的API，仅仅有一个协议支撑回调，使用简单，我们都熟悉此道。
* iOS8之后，WKWebView的出现，打乱了这一切，整个WKWebView的设计，基本与UIWebView的设计无关，似乎已经脱胎换骨。
* 在不同iOS版本中做判断进行开发，将导致代码量增多，如果能将WKWebView设计成与UIWebView一样的使用习惯，学习成本会大大降低。使用者无需考虑系统版本,且依旧如UIWebView去使用，这样的设计极有必要。
GSWebView整合了两代WebView，使用习惯力求完美接近UIWebview，甚至可以说，在JS交互上，做到了更佳简单。

###### 使用介绍

指定初始化构造方法
```objective-c
- (instancetype)initWithFrame:(CGRect)frame delegate:(nonnull id<GSWebViewDelegate>)delegate JSPerformer:(nonnull id)performer; 
```

同UIWebView属性
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
- (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error; 

//此协议方法为JS交互关键
- (NSArray<NSString *>*)gswebViewRegisterObjectiveCMethodsForJavaScriptInteraction;
```

JS交互重点
```objective-c
/**
  JS调用OC方法
  网页中的Script标签中有此JS方法名称，但未具体实现，将参数传给Objective-C,OC将获取到的参数做下一步处理
  必须在OC中具体实现该方法，方法参数可用id(或明确知晓JS传来的参数类型).
*/
- (NSArray<NSString *>*)gswebViewRegisterObjectiveCMethodsForJavaScriptInteraction;
```
当JS调用一个'- (void)getCurrentUserName:(NSString *)name'的OC方法时，参数name由JS传来，那么在实现该OC方法时，只需要正确知道参数类型或基本结构，你也可以写为id类型做普适，在方法内部做转换。
* * *
#### 3.JavaScript源码必须做出的改动！
* WKWebView的JS交互，最不惹人注目但最为关键的地方在于此。
* 在UIWebView的时代，想要JS交互，JS代码不需要做出改动，但是在WKWebView时代，JS需要根据客户端版本号调用不同的方法与与客户端进行交互。
官方文档里这句话'window.webkit.messageHandlers.<name>.postMessage(<messageBody>)'进行数据传递。
> Adding a scriptMessageHandler adds a function window.webkit.messageHandlers.\<name\>.postMessage(\<messageBody\>) for all frames.
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
#### 4.GSWebView采用装饰模式的实现整合的思路
* GSWebView内部一个UIView指针，当调用指定构造方法初始化后，内部根据不同的系统版本，将UIView指针指向WKWebView或者UIWebView。 
* 关于回调，除去UI方面的进度回调通过GSWebViewDelegate协议，在GSWebView中注册需要的JS调用的OC方法，都通过一个指向函数的指针实现回调，且回调线程为主线程。
* OC调用JS的回调则在一个block中完成，且回调线程为主线程。
* iOS8系统以下内存泄漏优化。UIWebView的内存泄漏问题至今没有很好的解决方案。

<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/"><img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/3.0/cn/88x31.png" /></a><br />本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/">知识共享署名-非商业性使用-禁止演绎 3.0 中国大陆许可协议</a>进行许可。
* * *
