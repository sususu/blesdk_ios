install! 'cocoapods', :warn_for_unused_master_specs_repo => false

platform :ios, '14.0'
# Match AiSDK Example / HaWoFit: dynamic frameworks for AiSDK + WatchfaceSDK.
# HwBluetoothSDK stays vendored as a static `.a` (see Vendor/HwBluetoothSDK).
use_frameworks!
inhibit_all_warnings!

target 'BleSdkDemo' do
  project 'BleSdkDemo'

  # Local static Bluetooth SDK (prebuilt `.a`); not available as dynamic framework.
  pod 'HwBluetoothSDK', :path => 'Vendor/HwBluetoothSDK'

  # Official SDK repos (same as AiSDK Example / production apps).
  # Zip + SSZipArchive are pulled transitively by WatchfaceSDK / AiSDK — do not vendor locally.
  pod 'AiSDK', :git => 'https://github.com/HWdan/HwAiSDK.git', :branch => 'main'
  pod 'WatchfaceSDK', :git => 'https://github.com/HWdan/WatchfaceSDK.git', :branch => 'main'
  # Host-owned JieLi converter; injected into AiSDK at app startup.
  pod 'JLBmpConvertKit', :git => 'https://github.com/sususu/JLBmpConvertKit.git', :tag => '1.2.0'

  pod 'AFNetworking', '~> 4.0.1'
end

post_install do |installer|
  hw_root = '${PODS_ROOT}/../Vendor/HwBluetoothSDK'
  hw_header_paths = [
    '$(inherited)',
    "\"#{hw_root}/include\"",
    "\"#{hw_root}/include/HwBluetoothSDK\"",
    "\"#{hw_root}/HwBluetoothSDK.framework/Headers\""
  ]
  hw_framework_paths = [
    '$(inherited)',
    "\"#{hw_root}\""
  ]

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      dep = (target.name == 'Zip' || target.name == 'SSZipArchive') ? '9.0' : '13.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = dep
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES' if target.name == 'Zip'
      if target.name == 'AiSDK'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
        config.build_settings['HEADER_SEARCH_PATHS'] = hw_header_paths
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = hw_framework_paths
      end
    end
  end

  %w[debug release].each do |cfg|
    xcconfig_path = File.join(installer.sandbox.root, 'Target Support Files/AiSDK', "AiSDK.#{cfg}.xcconfig")
    next unless File.exist?(xcconfig_path)
    contents = File.read(xcconfig_path)
    unless contents.include?('HwBluetoothSDK.framework/Headers')
      File.open(xcconfig_path, 'a') do |f|
        f.puts "HEADER_SEARCH_PATHS = $(inherited) \"#{hw_root}/include\" \"#{hw_root}/include/HwBluetoothSDK\" \"#{hw_root}/HwBluetoothSDK.framework/Headers\""
      end
    end
    unless contents.lines.any? { |line| line.start_with?('FRAMEWORK_SEARCH_PATHS') && line.include?('../Vendor/HwBluetoothSDK') }
      File.open(xcconfig_path, 'a') do |f|
        f.puts "FRAMEWORK_SEARCH_PATHS = $(inherited) \"#{hw_root}\""
      end
    end
  end

  hw_support = File.join(installer.sandbox.root, 'Target Support Files/HwBluetoothSDK')
  if File.directory?(hw_support)
    File.write(File.join(hw_support, 'HwBluetoothSDK.modulemap'), <<~MAP)
      framework module HwBluetoothSDK {
        umbrella header "../../../Vendor/HwBluetoothSDK/HwBluetoothSDK.framework/Headers/HwBluetoothSDK.h"
        export *
        module * { export * }
      }
    MAP
    File.write(File.join(hw_support, 'HwBluetoothSDK-umbrella.h'), <<~HDR)
      #ifdef __OBJC__
      #import <UIKit/UIKit.h>
      #else
      #ifndef FOUNDATION_EXPORT
      #if defined(__cplusplus)
      #define FOUNDATION_EXPORT extern "C"
      #else
      #define FOUNDATION_EXPORT extern
      #endif
      #endif
      #endif

      #import "../../../Vendor/HwBluetoothSDK/HwBluetoothSDK.framework/Headers/HwBluetoothSDK.h"
    HDR
  end
end
