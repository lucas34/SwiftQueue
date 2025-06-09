Pod::Spec.new do |s|
  s.name             = "SwiftQueue"
  s.version          = "6.0.2"
  s.summary          = "SwiftQueue"
  s.description      = "Job Scheduler for iOS with concurrent execution, retry/failure handling, persistence, and more."
  s.homepage         = "https://github.com/lucas34/SwiftQueue"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Lucas Nelaupe" => "lucas.nelaupe@gmail.com" }
  s.source           = { :git => "https://github.com/lucas34/SwiftQueue.git", :tag => s.version.to_s }

  s.swift_version = '5.10'

  s.ios.deployment_target     = "13.0"
  s.tvos.deployment_target    = "13.0"
  s.watchos.deployment_target = "6.0"
  s.osx.deployment_target     = "10.15"

  s.source_files = 'Sources/SwiftQueue/**/*.swift'
end