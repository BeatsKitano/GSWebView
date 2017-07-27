

Pod::Spec.new do |s|


  s.name         = "GSWebView"
  s.version      = "1.0.2"
  s.summary      = "GSWebView is a high performance webb view"
  s.description  = "GSWebView是一个API实现两代WebView的JS交互，快速轻量，与UIWebView的使用方式极为相似"

  s.homepage     = "https://github.com/xorshine/GSWebView"

  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "K" => "xorshine@icloud.com" }

  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/xorshine/GSWebView.git", :tag => "1.0.2}" }

  s.source_files  = "GSWebView", "GSWebView/**/*.{h,m}"

  s.frameworks = "WebKit", "JavaScriptCore"

  s.requires_arc = true

end
