Pod::Spec.new do |s|
  s.name     = 'MSSPush'
  s.version  = '0.5'
  s.license  = { :type => 'CUSTOM', :file => 'LICENSE' }
  s.summary  = 'The Push SDK used to attach to Pivotal Mobile Services Suite'
  s.homepage = 'https://github.com/cfmobile'
  s.authors  = 'Rob Szumlakowski'
  s.source   = { :git => 'git@github.com:cfmobile/push-ios', :tag => "0.5" }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'MSSPush/**/*.h'
  s.source_files = 'MSSPush/**/*.{h,m}'
end
