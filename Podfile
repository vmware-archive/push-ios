workspace './PCFPush'
xcodeproj 'Specs/PCFPushSpecs'

puts "***"
puts "EXTREME WARNING: DO NOT UPGRADE TO COCOAPODS 1.0! IT HAS A BUG THAT CAUSES TESTS TO BE UNABLE TO RUN RANDOMLY."
puts "https://github.com/CocoaPods/Xcodeproj/issues/264"
puts "EXTREME SADNESS."
puts "Cocoapods version 0.39.0 is recommended."
puts "***"
puts ""

target 'PCFPushSpecs' do
  xcodeproj 'Specs/PCFPushSpecs'

  platform :ios, '7.0'
  link_with 'PCFPushSpecs'
  pod 'Kiwi'
  pod 'PCFPush', :path => './'
end
