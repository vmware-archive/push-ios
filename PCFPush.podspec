Pod::Spec.new do |s|
  s.name     = 'PCFPush'
  s.version  = '0.4.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'The push SDK used to attach to Pivotal Cloud Foundry Push Server.'
  s.homepage = 'https://github.com/xtremelabs/'
  s.authors  = { 'Elliott Garcea' => 'egarcea@pivotallabs.com', 'Rob Szumlakowski' => 'rszumlakowski@pivotallabs.com' }
  s.source   = { :git => 'https://github.com/xtremelabs/pcf-pushsdk-ios.git', :tag => "0.4.0" }
  s.requires_arc = true
  s.libraries    = 'z'
  s.frameworks   = 'Foundation', 'CoreData'

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'PCFPush/**/*.h'
  s.source_files = 'PCFPush/**/*.{h,m}'
end