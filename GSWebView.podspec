

Pod::Spec.new do |s|


  s.name         = "GSWebView"
  s.version      = "1.0"
  s.summary      = "GSWebView是一个API实现两代WebView的JS交互，快速轻量，与UIWebView的使用方式极为相似"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = "GSWebView是一个API实现两代WebView的JS交互，快速轻量，与UIWebView的使用方式极为相似"

  s.homepage     = "https://github.com/xorshine/GSWebView"

  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "K" => "xorshine@icloud.com" }

  s.platform     = :iOS, "7.0"

  s.source       = { :git => "https://github.com/xorshine/GSWebView.git", :tag => "1.0.1}" }

  s.source_files  = "GSWebView", "GSWebView/**/*.{h,m}"

  s.frameworks = "WebKit", "JavaScriptCore"

  s.requires_arc = true

end
