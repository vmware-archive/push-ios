Pod::Spec.new do |s|
  s.name     = 'PCFPush'
  s.version  = '1.0.4'
  s.license  = { :type => 'CUSTOM', :file => 'LICENSE' }
  s.summary  = 'Pivotal CF Mobile Services Push Client SDK for iOS'
  s.homepage = 'https://github.com/cfmobile'
  s.authors  = 'Rob Szumlakowski'
  s.source   = { :git => 'https://github.com/cfmobile/push-ios.git', :tag => "push_sdk_1.0.4" }
  s.requires_arc = true

  s.ios.deployment_target = '7.0'

  s.public_header_files = 'PCFPush/**/*.h'
  s.source_files = 'PCFPush/**/*.{h,m}'
end
