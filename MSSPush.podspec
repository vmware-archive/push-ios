Pod::Spec.new do |s|
  s.name     = 'MSSPush'
  s.version  = '0.4'
  s.license  = 'Apache 2.0'
  s.summary  = 'The Push SDK used to attach to Pivotal Mobile Services Suite'
  s.homepage = 'https://github.com/cfmobile/'
  s.authors  = { 'Elliott Garcea' => 'egarcea@pivotallabs.com', 'Rob Szumlakowski' => 'rszumlakowski@pivotallabs.com' }
  s.source   = { :git => 'https://github.com/cfmobile/push-ios.git', :tag => "0.4" }
  s.requires_arc = true
  s.libraries    = 'z'
  s.default_subspec = 'All'

  s.ios.deployment_target = '6.0'

  s.subspec 'All' do |all|
    all.dependency 'MSSPush/Push'
    all.dependency 'MSSPush/Analytics'
  end

  s.subspec 'Analytics' do |analytics|
    analytics.framework  = 'CoreData'
    # analytics.dependency 'MSSPush/SDK'
    analytics.source_files = 'MSSAnalytics/**/*.{h,m}'
  end

  s.subspec 'Push' do |push|
    push.dependency 'MSSPush/Base'
    push.source_files = 'MSSPush/**/*.{h,m}'
  end

  s.subspec 'Base' do |sdk|
    sdk.source_files = 'MSSBase/**/*.{h,m}'
  end

end
