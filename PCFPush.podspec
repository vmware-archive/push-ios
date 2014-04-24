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
  s.default_subspec = 'All'

  s.ios.deployment_target = '6.0'

  s.subspec 'All' do |all|
    all.dependency 'PCFPush/Push'
    all.dependency 'PCFPush/Analytics'
  end

  s.subspec 'Analytics' do |analytics|
    analytics.framework  = 'CoreData'
    # analytics.dependency 'PCFPush/SDK'
    analytics.source_files = 'PCFAnalytics/**/*.{h,m}'
  end

  s.subspec 'Push' do |push|
    push.dependency 'PCFPush/SDK'
    push.source_files = 'PCFPush/**/*.{h,m}'
  end

  s.subspec 'SDK' do |sdk|
    sdk.source_files = 'PCFSDK/**/*.{h,m}'
  end

end