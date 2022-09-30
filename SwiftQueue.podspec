Pod::Spec.new do |s|
  s.name             = "SwiftQueue"
  s.version          = "6.0.1"
  s.summary          = "SwiftQueue"
  s.description      = "Job Scheduler for IOS with Concurrent run, failure/retry, persistence, repeat, delay and more"
  s.homepage         = "https://github.com/lucas34/SwiftQueue"
  s.license          = 'MIT'
  s.author           = { "Lucas Nelaupe" => "lucas.nelaupe@gmail.com" }
  s.source           = { :git => "https://github.com/lucas34/SwiftQueue.git", :tag => s.version.to_s }

  s.swift_version = '5.7.0'

  s.ios.deployment_target = "12.0"
  s.tvos.deployment_target= "12.0"
  s.watchos.deployment_target = "5.0"
  s.osx.deployment_target= "10.14"

  s.source_files = 'Sources/SwiftQueue/**.swift'
  
end
