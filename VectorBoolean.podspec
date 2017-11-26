Pod::Spec.new do |s|
  s.name             = "VectorBoolean"
  s.version          = "0.1.1"
  s.summary          = "VectorBoolean bezier path tools"
  s.description      = <<-DESC
                       A Swift iOS rewrite of Andy Finnell's VectorBoolean bezier path tools
                       DESC
  s.homepage         = "https://github.com/lrtitze/Swift-VectorBoolean"
  s.license          = "MIT"
  s.author           = { "lrtitze" => "" }
  s.platform         = :ios
  s.source           = { :git => "https://github.com/lrtitze/Swift-VectorBoolean.git", :tag => "v#{s.version}" }
  s.source_files     = "Swift VectorBoolean/VectorBoolean/**/*.{swift}"
  s.requires_arc     = true
  s.ios.deployment_target = '9.0'
end