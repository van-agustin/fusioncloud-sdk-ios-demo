# Uncomment the next line to define a global platform for your project
platform :ios, '15.1'

target 'TestAppDM' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TestAppDM
  pod 'ReachabilitySwift'
  pod 'Alamofire','~> 5.3.0'
  pod 'SVProgressHUD'
  pod 'Starscream', '~> 4.0.0'

  # Pods for FusionCloud
  pod 'ObjectMapper', '~> 4'
  pod 'IDZSwiftCommonCrypto', '~> 0.13'
end
post_install do |installer|
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          end
        end
      end
