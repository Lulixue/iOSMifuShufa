# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'iOSMifuShufa' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for iOSMifuShufa

  pod 'SwiftyJSON'
  pod 'MMKVCore', '1.3.4'
  pod 'MMKV', '1.3.4'
  pod 'Alamofire', '~> 5.4'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'Ads-CN','6.1.1.0'
#  pod 'Ads-CN-Beta'
  pod 'LzmaSDK-ObjC', :inhibit_warnings => true
  pod 'MijickPopupView'
  pod 'Zip', '~> 2.1'
  pod 'DeviceKit'
  pod 'SwiftUIIntrospect'
  pod 'SDWebImageSwiftUI'
  
  target 'iOSMifuShufaTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'iOSMifuShufaUITests' do
    # Pods for testing
  end

  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
        end
      end
    end
  end

end
