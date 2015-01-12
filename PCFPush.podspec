Pod::Spec.new do |s|
  s.name     = 'PCFPush'
  s.version  = '1.0.3'
  s.license  = { :type => 'CUSTOM', :file => 'LICENSE' }
  s.summary  = 'Pivotal CF Mobile Services Push Client SDK for iOS'
  s.homepage = 'https://github.com/cfmobile'
  s.authors  = 'Rob Szumlakowski'
  s.source   = { :git => 'git@github.com:cfmobile/push-ios', :tag => "1.0.3" }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'PCFPush/**/*.h'
  s.source_files = 'PCFPush/**/*.{h,m}'
end
