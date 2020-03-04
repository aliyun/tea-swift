Pod::Spec.new do |spec|

  spec.name         = "Tea"
  spec.version      = "0.3.0"
  spec.license      = "Apache 2.0"
  spec.summary      = "Alibaba Cloud Tea for Swift"
  spec.homepage     = "https://github.com/aliyun/tea-swift" 
  spec.author       = { "Alibaba Cloud SDK" => "sdk-team@alibabacloud.com" }

  spec.source       = { :git => spec.homepage + '.git', :tag => spec.version }
  spec.source_files = 'Sources/**/*.swift'

  spec.ios.framework   = 'Foundation'

  spec.ios.deployment_target     = '8.0'
  spec.osx.deployment_target     = '10.11'
  spec.watchos.deployment_target = '2.0'
  spec.tvos.deployment_target    = '9.0'

  spec.dependency 'AlamofirePromiseKit',  '~> 1.0.0'
  spec.dependency 'CryptoSwift',  '~> 1.3.0'
  spec.dependency 'SwiftyJSON',  '~> 5.0.0'
  spec.swift_version = '5.1'

end
