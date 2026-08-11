install! 'cocoapods', :warn_for_unused_master_specs_repo => false

platform :ios, '14.0'
use_frameworks! :linkage => :static
inhibit_all_warnings!

target 'BleSdkDemo' do
  project 'BleSdkDemo'

  pod 'HwBluetoothSDK', :path => 'Vendor/HwBluetoothSDK'
  pod 'Zip', :path => 'Vendor/Zip'
  pod 'SSZipArchive', :path => 'Vendor/SSZipArchive'
  pod 'WatchfaceSDK', :path => 'Vendor/WatchfaceSDK'
  # Local AiSDK with Esafenet headers replaced by reconstructed plaintext under Vendor/AiSDK.
  pod 'AiSDK', :path => 'Vendor/AiSDK'
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

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Zip / prebuilt SFDialPlate frameworks target iOS 9.0
      dep = (target.name == 'Zip' || target.name == 'SSZipArchive') ? '9.0' : '13.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = dep
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES' if target.name == 'Zip'
      # AiSDK needs HwBluetoothSDK headers for quoted / mixed imports
      if target.name == 'AiSDK'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
        config.build_settings['HEADER_SEARCH_PATHS'] = hw_header_paths
      end
    end
  end

  # Ensure AiSDK xcconfigs also carry header search paths (not only pbxproj)
  %w[debug release].each do |cfg|
    xcconfig_path = File.join(installer.sandbox.root, 'Target Support Files/AiSDK', "AiSDK.#{cfg}.xcconfig")
    next unless File.exist?(xcconfig_path)
    contents = File.read(xcconfig_path)
    unless contents.include?('HwBluetoothSDK.framework/Headers')
      File.open(xcconfig_path, 'a') do |f|
        f.puts "HEADER_SEARCH_PATHS = $(inherited) \"#{hw_root}/include\" \"#{hw_root}/include/HwBluetoothSDK\" \"#{hw_root}/HwBluetoothSDK.framework/Headers\""
      end
    end
  end

  # Replace CocoaPods-generated modulemap/umbrella (references headers not in the
  # prebuilt framework) with the vendored framework's own module map.
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
