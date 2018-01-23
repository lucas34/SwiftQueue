Pod::Spec.new do |s|
  s.name             = "SwiftQueue"
  s.version          = "1.4.1"
  s.summary          = "SwiftQueue"
  s.description      = "Job Scheduler for IOS with Concurrent run, failure/retry, persistence, repeat, delay and more"
  s.homepage         = "https://github.com/lucas34/SwiftQueue"
  s.license          = 'MIT'
  s.author           = { "Lucas Nelaupe" => "lucas.nelaupe@gmail.com" }
  s.source           = { :git => "https://github.com/lucas34/SwiftQueue.git", :tag => s.version.to_s }

  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target= "9.0"
  s.watchos.deployment_target = "2.0"
  s.osx.deployment_target= "10.10"

  s.requires_arc = true

  s.source_files = 'Sources/SwiftQueue/**.swift'
  
  s.ios.dependency 'ReachabilitySwift', '~> 4.1'
  s.tvos.dependency 'ReachabilitySwift', '~> 4.1'
  s.osx.dependency 'ReachabilitySwift', '~> 4.1'
  
end