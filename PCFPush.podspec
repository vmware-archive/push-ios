Pod::Spec.new do |s|
  s.name     = 'OmniaPush'
  s.version  = '0.4.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'The push SDK used to attach to Omnia Push Server.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.authors  = { 'Elliott Garcea' => 'egarcea@pivotallabs.com', 'Rob Szumlakowski' => 'rszumlakowski@pivotallabs.com' }
  s.source   = { :git => 'https://github.com/xtremelabs/omnia-pushsdk-ios.git', :tag => "0.4.0" }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'

  s.public_header_files = 'OmniaPush/**/*.h'
  s.source_files = 'OmniaPush/**/*.{h,m}'
end