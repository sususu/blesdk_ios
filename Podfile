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
  # JLBmpConvertKit comes from AiSDK vendored_frameworks — do not add a local duplicate pod.

  pod 'AFNetworking', '~> 4.0.1'
end

# Git AiSDK also vendors `HwBluetoothSDK.framework`; Demo already links the local `:path` pod.
# Strip only HwBluetoothSDK to avoid duplicate ObjC symbols. Keep NativeLib + JLBmpConvertKit.
pre_install do |installer|
  installer.analysis_result.specifications.each do |spec|
    next unless spec.name == 'AiSDK'
    vendored = spec.attributes_hash['vendored_frameworks']
    next if vendored.nil?
    filtered = Array(vendored).flat_map { |entry| entry.to_s.split(/,\s*/) }
      .map(&:strip)
      .reject { |f| f.empty? || f.include?('HwBluetoothSDK') }
    spec.attributes_hash['vendored_frameworks'] = filtered
  end
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
      dep = (target.name == 'Zip' || target.name == 'SSZipArchive') ? '9.0' : '13.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = dep
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES' if target.name == 'Zip'
      if target.name == 'AiSDK'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
        config.build_settings['HEADER_SEARCH_PATHS'] = hw_header_paths
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

  hw_dup = File.join(installer.sandbox.root, 'AiSDK/HwBluetoothSDK.framework')
  FileUtils.rm_rf(hw_dup) if File.directory?(hw_dup)

  %w[debug release].each do |cfg|
    aggregate = File.join(installer.sandbox.root, 'Target Support Files/Pods-BleSdkDemo', "Pods-BleSdkDemo.#{cfg}.xcconfig")
    next unless File.exist?(aggregate)
    contents = File.read(aggregate)
    contents = contents.gsub(/-framework "HwBluetoothSDK"\s*/, '')
    File.write(aggregate, contents)
  end
end
