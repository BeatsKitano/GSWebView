
###1.为何要从UIWebView更新到WKWebView？
***

####性能测试：

<font size=2>

|           	        | UIWebView          	 | WKWebView      |    备注     |
| :--------------------: |:----------------------:| :-------------------------:| :--------------------:|
| iOS 版本     	         | 8.4          | 8.4        |  ———   |
| iPhone     	         | 6           |   6        | 真机测试   |
| 测试网页|[天猫首页](http://www.tmall.com)|[天猫首页](http://www.tmall.com) |———|
| 内存占用峰值	 | 132.2MB     |    8.4MB |———|
| 加载耗时	 	| 3.1s     |    2.6s |  mach_absolute_time(); |
| FPS	 		| 无特别明显差异      |    无明显差异 |  Instruments (core animation) |
| 测试次数	 	| 2     |    2 |———|
  
 </font>
 
 单纯<font size=4>内存占用</font>一方面考虑，使用WKWebView是明智的选择。
***
####2.如UIWebView一样使用WKWebView，坚持熟悉的味道

<p>比起WKWebView，我们更为熟悉的是UIWebView，且UIWebView使用JavaScriptCore框架进行JS交互，我们都“熟悉”此道。而WKWebView打乱了这一切，似乎已经脱胎换骨。如果能将WKWebView打造成与UIWebView一样的使用习惯就好了，这样会降低学习使用的成本。使用者不要考虑系统版本,且依旧能够看到UIWebView那些熟悉的属性、熟悉方法，嗯，还是原来的味道。</p>
 <p> WKWebView与UIWebView同时继承自UIView，那么自定义一个WebView，这是一个通用的WebView，调用指定的构造方法初始化即可。</p>
  
   <p>指定初始化方法</p>
   
```objective-c
- (instancetype)initWithFrame:(CGRect)frame delegate:(nonnull id<GSWebViewDelegate>)delegate JSPerformer:(nonnull id)performer; 
```

 <p>熟悉的属性</p>
 
```objective-c
@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward; 

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;
```

 <p>形神皆似的协议方法</p>
  
```objective-c
 
 - (BOOL)gswebView:(GSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(GSWebViewNavigationType)navigationType;
- (void)gswebViewDidStartLoad:(GSWebView *)webView;
- (void)gswebViewDidFinishLoad:(GSWebView *)webView;
- (void)gswebView:(GSWebView *)webView didFailLoadWithError:(NSError *)error; 

 - (NSArray<NSString *>*)gswebViewNeedInterceptJavaScript;
```
 
 <p>这里是重点</p>
   
```objective-c
 
  /**
  JS调用OC方法
 
  网页中的Script标签中有此JS方法名称，但未具体实现，将参数传给Objective-C,OC将获取到的参数做下一步处理
 
  必须在OC中具体实现该方法，方法参数可用id(或明确知晓JS传来的参数类型).
 
 */
- (NSArray<NSString *>*)gswebViewNeedInterceptJavaScript;
 
```

####3.JavaScript源码必须做出的改动！
  <p> 在UIWebView的时代，想要JS交互，JS代码不需要做出改动，但是在WKWebView时代，JS需要根据客户端版本号调用不同的方法与与客户端进行交互。</p>
  
  官方文档里这句话，哎,就是要JS通过“window.webkit.messageHandlers.\<name\>.postMessage(\<messageBody\>)”进行信息传递。
  > Adding a scriptMessageHandler adds a function window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all frames.
  
  举个栗子：
  
  ```javascript
  
  JS中有一个getConsultationInfo(id)方法,客户端获取到id实现该方法，这是UIWebView时代
  
  但是在GSWebView中，必须这样:
  
//获取客户端iOS版本
        var version = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/);  
        version = parseInt(ver[1], 10);  
 
	if( version>=7.0 && version <8.0){
		getConsultationInfo(id);
	}else if(version>=8.0){
		 window.webkit.messageHandlers.getConsultationInfo.postMessage(id)
	} 
 
```
 
 
####4.GSWebView 实现思路
 
 <p> GSWebView内部一个UIView指针，初始化完成后，内部根据不同的系统版本指向WKWebView或者UIWebView，从代码内部看，GSWebView并未遵守任何协议，但初始化时，GSWebView应该遵循的协议都通过Runtime动态绑定。</p>
 
 <p>倘若内部由UIWebView实现，那么JS交互的JSContext也是通过Runtime进行属性添加。用到什么添加什么!</p>
  
 <br></br>
  <small>补充：希望阅读此文的你是干干净净的！</small>
  <br></br>
<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/"><img alt="知识共享许可协议" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/3.0/cn/88x31.png" /></a><br />本作品采用<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/cn/">知识共享署名-非商业性使用-禁止演绎 3.0 中国大陆许可协议</a>进行许可。


