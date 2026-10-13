Pod::Spec.new do |s|
  s.name             = 'WatchfaceSDK'
  s.version          = '1.0.6'
  s.summary          = 'A short description of WatchfaceSDK.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/HWdan/WatchfaceSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = {"HWdan": "huangwentai@huawo-wear.com"}
  s.source           = { :path => '.' }
  s.ios.deployment_target = '9.0'
  s.swift_versions   = ["4.2", "5.0"]
  s.source_files     = ["WatchfaceSDK/Classes/Watchface/**/*", "WatchfaceSDK/Classes/OTA/**/*"]
  s.resources        = ["WatchfaceSDK/Assets/*"]
  s.vendored_frameworks = ["WatchfaceSDK/SFDialPlateSDK.framework", "WatchfaceSDK/eZIPSDK.framework", "WatchfaceSDK/SifliOTAManagerSDK.framework", "WatchfaceSDK/VideoWatchfaceSDK.framework"]
  s.frameworks       = ["AudioToolbox", "CoreMedia", "VideoToolbox", "AVFoundation"]
  s.libraries        = ["z", "bz2", "iconv"]
  s.dependency 'Zip', '~> 2.1'
  s.dependency 'SSZipArchive'
  s.dependency 'Masonry'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.xcconfig = { 'SUPPORTED_PLATFORMS' => 'iphoneos' }
end
