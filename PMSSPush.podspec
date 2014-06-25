Pod::Spec.new do |s|
  s.name     = 'PMSSPush'
  s.version  = '0.4'
  s.license  = 'Apache 2.0'
  s.summary  = 'The push SDK used to attach to Pivotal Cloud Foundry Push Server.'
  s.homepage = 'https://github.com/cfmobile/'
  s.authors  = { 'Elliott Garcea' => 'egarcea@pivotallabs.com', 'Rob Szumlakowski' => 'rszumlakowski@pivotallabs.com' }
  s.source   = { :git => 'https://github.com/cfmobile/push-ios.git', :tag => "0.4" }
  s.requires_arc = true
  s.libraries    = 'z'
  s.default_subspec = 'All'

  s.ios.deployment_target = '6.0'

  s.subspec 'All' do |all|
    all.dependency 'PMSSPush/Push'
    all.dependency 'PMSSPush/Analytics'
  end

  s.subspec 'Analytics' do |analytics|
    analytics.framework  = 'CoreData'
    # analytics.dependency 'PMSSPush/SDK'
    analytics.source_files = 'PMSSAnalytics/**/*.{h,m}'
  end

  s.subspec 'Push' do |push|
    push.dependency 'PMSSPush/SDK'
    push.source_files = 'PMSSPush/**/*.{h,m}'
  end

  s.subspec 'SDK' do |sdk|
    sdk.source_files = 'PMSSSDK/**/*.{h,m}'
  end

end
