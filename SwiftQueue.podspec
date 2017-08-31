Pod::Spec.new do |s|
  s.name             = "SwiftQueue"
  s.version          = "0.0.8"
  s.summary          = "SwiftQueue"
  s.description      = "Job Scheduler for IOS with Concurrent run, failure/retry, persistence, repeat, delay and more"
  s.homepage         = "https://github.com/lucas34/SwiftQueue"
  s.license          = 'MIT'
  s.author           = { "Lucas Nelaupe" => "lucas.nelaupe@gmail.com" }
  s.source           = { :git => "https://github.com/lucas34/SwiftQueue.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'SwiftQueue/**.swift'
  
  s.dependency 'ReachabilitySwift', '~> 3'
  
end