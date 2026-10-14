Pod::Spec.new do |s|
  s.name             = 'HwBluetoothSDK'
  s.version          = '3.2.17'
  s.summary          = 'HuaWo Bluetooth SDK (prebuilt static framework)'
  s.description      = 'Local vendored HwBluetoothSDK (static archive) for BleSdkDemo'
  s.homepage         = 'https://github.com/sususu/LYSpecs'
  s.license          = { :type => 'MIT' }
  s.author           = { 'SuJiang' => 'sujiang@huawo-wear.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '13.0'
  s.static_framework = true

  # Binary inside .framework is a static ar archive — link as a library so the app
  # does not get an @rpath/HwBluetoothSDK.framework load command at runtime.
  s.preserve_paths = 'HwBluetoothSDK.framework', 'include', 'libHwBluetoothSDK.a'
  s.vendored_libraries = 'libHwBluetoothSDK.a'
  s.module_map = 'HwBluetoothSDK.framework/Modules/module.modulemap'

  s.frameworks = 'CoreBluetooth', 'Foundation', 'UIKit'
  s.libraries = 'z', 'c++'

  root = '$(PODS_ROOT)/../Vendor/HwBluetoothSDK'
  header_paths = [
    "\"#{root}/include\"",
    "\"#{root}/include/HwBluetoothSDK\"",
    "\"#{root}/HwBluetoothSDK.framework/Headers\""
  ].join(' ')

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => header_paths,
    'FRAMEWORK_SEARCH_PATHS' => "\"#{root}\"",
    'LIBRARY_SEARCH_PATHS' => "\"#{root}\"",
    'DEFINES_MODULE' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.user_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => header_paths,
    'FRAMEWORK_SEARCH_PATHS' => "\"#{root}\"",
    'LIBRARY_SEARCH_PATHS' => "\"#{root}\""
  }
end
