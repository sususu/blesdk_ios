/*!
 @header HwBluetoothCenter.h
 
 @author sujiang on 2018/5/23.
 @copyright  2021年 huawo. All rights reserved.
 */
#import "HwBluetoothCenter+Utils.h"
#import "HwBluetoothCenter+Sport.h"
#import "HwBluetoothCenter+Device.h"
#import "HwBluetoothCenter+User.h"
#import "HwBluetoothCenter+DrinkWater.h"
#import "HwBluetoothCenter+PhoneSchedule.h"
#import "HwBluetoothCenter+StandingSetting.h"
#import "HwBluetoothCenter+Ota.h"
#import "HwOtaV2Service.h"
#import "HwMultipleFileTransferModel.h"
#import "HwMultipleFileTransferService.h"
#import "HwBluetoothCenter+FileDifferenceOta.h"
#import "HwBluetoothCenter+Expand.h"
#import "HwBluetoothCenter+StatusSetting.h"
#import "HwBluetoothCenter+WorkoutTrack.h"
#import "HwBluetoothCenter+WatchFace.h"
#import "HwBluetoothCenter+Workout.h"
#import "HwBluetoothCenter+Customize.h"
#import "HwBluetoothCenter+Unit.h"
#import "HwCommonDefines.h"
#import "HwHeartrateFatigue.h"
#import "HwHeartrateAlarm.h"
#import "HwCustomWatchface.h"
#import "HwSedentaryReminder.h"
#import "HwLanguageUtil.h"
#import "HwUserInfo.h"
#import "HwSleep.h"
#import "HwWorldClockCity.h"
#import "HwSimpleCustomWatchface.h"
#import "HwBluetoothCenter.h"
#import "HwFileUtils.h"
#import "HwGpsStatus.h"
#import "HwBluetoothCenter+AI.h"
#import "HwBluetoothCenter+Muslim.h"
#import "HwBluetoothCenter+BigDataSport.h"
#import "HwBluetoothCenter+BleFileSender.h"
#import "HwLS16.h"
#import "HwDeviceInfo.h"
#import "HwMuslimDayAlert.h"
#import "HwBluetoothDeviceRequestManager.h"
#import "HwBluetoothDeviceRequestManager+DrinkWaterRecords.h"

#define HwBluetoothSDK_Version @"3.2.10"

typedef NS_ENUM(NSInteger, HWPlatformType) {
    HWPlatformTypeSifli = 0,
    HWPlatformTypeRealtek,
    HWPlatformTypeJieLi,
};

/**
 3.2.10:
 1. Add new language enum values;
 2. Add qrcode card feature.
 */
/**
 3.2.9:
 1. Add support for blood pressure feature;
 2. Fix the problem: When the device cannot be scanned, there is no callback for connection failure;
 3. 'getLastConnectedDevice' add memory cache.
 4. Add new API: updateMacAddressIfNeedWithMac, which for reconnect.
 5. Fix: 'setContactWithContacts' sub contracting problem caused slow response when adding contacts more than 8
 */

/**
 # BLE SDK
 ## Setup:
 Each API in the SDK, except for static methods, needs to be called through a single instance. Do not create an instance yourself. Otherwise, SDK status may be wrong.
 1. Init the SDK: [[HwBluetoothSDK sharedInstance] initSDK];
 2. When you no longer need to use the SDK, call 'destroySDK'.
 3. Get SDK version by call 'version'.
 
 We recommend initializing the SDK when the app is started, for example, in the method 'didFinishLaunchingWithOptions'
 and destroy the SDK when the app terminated.
 
 
 ## Connection:
 # The Bluetooth connection is only valid when the Bluetooth status is available (power on).
 ## Bluetooth Status:
 You can monitor Bluetooth status by 'addBluetoothStateChangedCallback'
 @example
 [[HwBluetoothSDK sharedInstance] addBluetoothStateChangedCallback:^(HwBluetoothState state) {
     if (state == HwBluetoothStateAvailable) {
        // Connect your watch.
     } else {
        
     }
 }];
 
 ## How to connect my watch?
 1. You can make a ble connection by calling 'connectWithBleName' to pass in the Bluetooth name of the watch.
 2. Or you can call 'connectWithDevice' with the device returned by 'scanDevicesWithCallback' API.
 3. You can monitor Bluetooth connection status by 'addBluetoothConnectionStateChangedCallback'
 4. 'connected' Get bluetooth connection status
 5. 'getPhoneConnectedDevices' Get the connected devices in the Bluetooth settings of the mobile phone.
 
 ## After connected, you can call any APIs to read/write data.
 
 */
@interface HwBluetoothSDK : NSObject

+ (HwBluetoothSDK *_Nonnull) sharedInstance;

#pragma mark - SDK init
@property (nonatomic, strong, readonly, nullable) HwOtaV2Service *otaV2Service;
@property (nonatomic, strong, readonly) HwMultipleFileTransferService *multipleFileTransferService;
/**
 Initialize the SDK. The SDK initializes some parameters and statuses and starts listening for status changes.
 */
- (void) initSDK;
/**
 Destroy recovered data and stop listening for status changes.
 */
- (void) destroySDK;

- (HwBluetoothState) state;
/**
 Get SDK version.
 */
- (NSString *_Nonnull) version;

#pragma mark - iPhone Bluetooth
/**
 
 */
- (void) addBluetoothStateChangedCallback:(HwBluetoothStateChangedCallback _Nonnull)callback;
/**
 
 */
- (void) removeBluetoothStateChangedCallback:(HwBluetoothStateChangedCallback _Nonnull)callback;

- (void) addBluetoothConnectionStateChangedCallback:(HwBluetoothConnectionStateChangedCallback _Nonnull)callback;
- (void) removeBluetoothConnectionStateChangedCallback:(HwBluetoothConnectionStateChangedCallback _Nonnull)callback;

/**
 Whether a device is connected right now
 */
- (BOOL) connected;
/**
 Whether connecting a device right now
 */
- (BOOL) connecting;
/**
 Whether no device is connected
 */
- (BOOL) disconnected;

/**
 Whether bluetooth state is power on
 */
- (BOOL) powerOn;

/**
 Return bluetooth central manager
 */
- (CBCentralManager *_Nonnull) getManager;

/**
 Return connected device if is connected == true
 */
- (HwBluetoothDevice *_Nullable) connectedDevice;

/*!
 @brief Scan the surrounding ble devices, and the returned results include the paired devices of the mobile phone
 
 @param callback Every time the device is scanned, it will be adjusted back
 @param second Scan timeout
 @param stopCallback Stop callback
 */
- (void) scanWithCallback:(HwSearchDevicesCallback _Nonnull)callback
                stopAfter:(NSTimeInterval)second
             stopCallback:(HwStopSearchingDevicesCallback _Nonnull)stopCallback;

/*! @brief
 Stop scanning bluetooth devices
 */
- (void) stopScan;

/*!
 @brief Connect watch by Bluetooth name
 
 @param bleName name
 @param callback callback
 */
- (void) connectWithBleName:(NSString *_Nonnull)bleName
                   callback:(HwConnectCallback _Nonnull)callback;
/*!
 @brief Connect watch by mac address
 
 @param mac mac
 @param callback callback
 */
- (void) connectWithMac:(NSString *_Nonnull)mac
               callback:(HwConnectCallback _Nonnull)callback;

/*!
 @brief Connect watch by mac address
 
 @param mac watch's bluetooth mac address
 @param timeout timeout
 @param callback callback
 */
- (void) connectWithMac:(NSString *_Nonnull)mac
                timeout:(NSInteger)timeoutSeconds
               callback:(HwConnectCallback _Nullable)callback;

- (void) connectWithBleName:(NSString *_Nonnull)bleName
                    timeout:(NSInteger)timeoutSeconds
                   callback:(HwConnectCallback _Nullable)callback;

- (void) connectWithDevice:(HwBluetoothDevice *_Nonnull)device
                  callback:(HwConnectCallback _Nullable)callback;


- (void) connectWithDevice:(HwBluetoothDevice *_Nonnull)device
                   timeout:(NSInteger)timeoutSeconds
                  callback:(HwConnectCallback _Nullable)callback;

/**
 Disconnect the watch's BLE. If the watch has been paired with the phone, the BLE cannot be disconnected after this method is called.
 */
- (void) disconnectWithCallback:(HwConnectCallback _Nullable)callback;

/**
 Device Disconnect BLE. If Without a matchwith the phone, the BLE cannot be disconnected after this method is called.
 */
- (HwBluetoothTask *_Nullable) setDeviceBleDisconnectionWithCallback:(HwBoolCallback _Nullable)callback;

/**
 Get the paired and connected watchs on the phone's bluetooth settings
 */
- (NSArray<HwBluetoothDevice *> *_Nullable) getPhoneConnectedDevices;

/*!
 @brief Get device connected last time
 */
- (HwBluetoothDevice *_Nullable) getLastConnectedDevice;

/*!
 @brief When device already connected to iPhone, SDK can not gain the mac address from the device's advertisement data.
 In this case, when you connect device with mac again, SDK can not find the device because mac address is nil, it can not match the mac address you pass in, as a result, it will failed.
 
 This is a remedial method. You can get the MAC address through ```getDeviceMacAddressWithCallback``` and call this method to let the SDK know that this peripheral corresponds to this MAC address. The SDK can correctly match the corresponding device the next time you connect.
 
Usage:
 You can get the MAC address of the device every time you connect to the device, and then call this method.
 */
- (void) updateMacAddressIfNeedWithMac:(NSString *_Nonnull)mac;

/*!
 @brief Clear up device connection info
 */
- (void) removeConnectionCache;

/**
 Cancel all ble task in the queue
 */
- (void) cancelAllBluetoothTasks;

- (NSInteger) bluetoothTaskCount;

#pragma mark - APIs
#pragma mark - Device Relative APIs
- (void) heartbeat:(HwBoolCallback _Nonnull)callback;

/*! @brief
 Set units of distance
 0 kilometers
 1 miles
 
 @param unit HwUnit
 @param callback HwUnitCallback
 */
- (void) setUnit:(HwUnit)unit
        callback:(HwBoolCallback _Nullable)callback;
- (void) getUnitWithCallback:(HwUnitCallback _Nonnull)callback;

/*! @brief
 Notify the watch to enter the photographing interface
 */
- (void) enterCameraWithCallback:(HwBoolCallback _Nullable)callback;
/*! @brief
 Notify the watch to exit the photographing interface
 */
- (void) exitCameraWithCallback:(HwBoolCallback _Nullable)callback;

/**
Device's camera interface event listener
 
 @param callback 回调
 */
- (void) addCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeAllCameraEventCallbacks;

- (void) addCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeAllCameraDelayEventCallbacks;

#pragma mark - 手表基本信息 basic info about watch

- (void) getDeviceFeaturesWithCallback:(HwDataCallback _Nonnull)callback;

#pragma mark - 猎声获取版本信息
/*! @brief
 Get for version information
 */
- (void) getVersionForLSWithCallback:(HwDataCallback _Nonnull)callback;

/*! @brief
 Querying the SN
 */
- (void) getDeviceSNWithCallback:(HwStringCallback _Nonnull)callback;

/*! @brief
 Get the GPS firmware version number and the valid period of AGPS data
 */
- (void) getDeviceGpsStatusWithCallback:(HwGpsStatusCallback _Nonnull)callback;
- (void) setDeviceGpsInfoWithClipType:(NSString *_Nonnull)clipType
                            secretKey:(NSString *_Nonnull)secretKey
                             callback:(HwBoolCallback _Nullable)callback;
- (void) setCurrentGpsLocationWithLatitude:(double)latitude
                                 longitude:(double)longitude
                                 timestamp:(NSTimeInterval)timestamp
                                  callback:(HwBoolCallback _Nullable)callback;
- (void) setCurrentGpsOrNetLocationWithLatitude:(double)latitude
                                      longitude:(double)longitude
                                      timestamp:(NSTimeInterval)timestamp
                                       callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get the ID and unique identification of the device
 
 @param callback string callback
 
 */
- (void) getDeviceIdWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 Get Mac address of the watch

 @param callback string callback

*/
- (void) getDeviceMacAddressWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 Get firmware version.
 This API will return a string, similar to:
 V1.0.0R0.1T0.5H0.0B20.
 
 R0.1: the picture lib version is 0.1
 T0.5: the touch driver version is 0.5
 V1.0.0: the version of the firmware is 1.0.0
 B20: the build of the firmware is 20
 
 How to compare firmware version numbers:
 Step1: Compare the V version number;
 Step2: Compare the B build version;
 Step3: Compare the R version number.
 
 In general, the T version number is never updated, only for development.
 
 @param callback string
 */
- (void) getFirmwareVersionWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 Get firmware version for TA

 @param callback string callback
*/
- (void) getFirmwareVersionForTAWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 Get device type(Watch model)
 
 @param callback string
 
 */
- (void) getDeviceTypeWithCallback:(HwStringCallback _Nullable)callback;

- (void) getDeviceInfoWithCallback:(HwDeviceInfoCallback _Nullable)callback;
- (void) getDeviceWatchfaceVersionWithCallback:(HwBCIntegerCallback _Nullable)callback;
- (void) getDeviceProtocolVersionWithCallback:(HwBCIntegerCallback _Nullable)callback;
- (void) setDeviceMapAuthCode:(NSString *_Nonnull)authCode
                         uuid:(NSString *_Nonnull)uuid
                     callback:(HwBoolCallback _Nullable)callback;
- (void) setDeviceMapTheme:(HwMapTheme)theme
                  callback:(HwBoolCallback _Nullable)callback;
- (void) setDeviceMapCenterWithLongitude:(double)longitude
                                latitude:(double)latitude
                                callback:(HwBoolCallback _Nullable)callback;
- (void) setDeviceMapRangeWithLongitude:(double)longitude
                               latitude:(double)latitude
                           maxLongitude:(double)longitude
                           minLongitude:(double)minLongitude
                            maxLatitude:(double)maxLatitude
                            minLatitude:(double)minLatitude
                               callback:(HwBoolCallback _Nullable)callback;
- (void) setDeviceBullets:(NSArray<HwDeviceBullet *> *_Nullable)bullets
                       on:(BOOL)on
                 callback:(HwBoolCallback _Nullable)callback;

/*! @brief
Start to bind with watch
 
 @param callback bool回调
 
 */
- (void) startBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

- (void) startBindSifliDeviceWithCallback:(HwBoolCallback _Nullable)callback;

- (void) startBindDeviceNoConfirmWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 LS16 bind API, SOP:
 1. Connect watch by mac address (If current mac address is connected, will continue next step);
 2. Check watch's UID whether is same as userInfo.Id, and callback onBinding with the reslt;
 3. Notify watch to show confirm screen;
 4. Callback deviceConfirmedCallback when the √ is clicked/Callback failedCallback with the error code 60 when × is clicked;
 5. Set user info to watch(This step is very import as it can ensure the accuracy of health data of the watch);
 6. Set watch time, as default, set '[Date date]' to the watch;
 7. Notify watch that binding SOP is finished so that watch can do some initialization.
 @param userInfo Please check HwUserInfo.h
 @param isNewDevice YES: new device  NO: old device
 @param deviceBindingCallback Callback an Boolean, whether the watch was binded before
 @param deviceConfirmedCallback Callback when √ is clicked
 @param deviceBindAgainCallback Callback when user confirm to bind again
 @param finishCallback Callback when binding SOP is done
 @param failedCallback Callback when user click × on the watch or any other exception happens
*/
- (void) startLS16BindWithUserInfo:(HwUserInfo *_Nonnull)userInfo
                       isNewDevice:(BOOL)isNewDevice
             deviceBindingCallback:(HwBoolCallback _Nullable)deviceBindingCallback
           deviceConfirmedCallback:(HwBCVoidCallback _Nullable)deviceConfirmedCallback
           deviceBindAgainCallback:(HwBCVoidCallback _Nullable)deviceBindAgainCallback
                    finishCallback:(HwBCVoidCallback _Nullable)finishCallback
                    failedCallback:(HwFailedCallback _Nullable)failedCallback;

/*! @brief
 Start to bind with watch using QRCODE
 
 @param callback bool
 
 */
- (void) startQRBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 End binding
 
 @param callback bool
 
 */
- (void) endBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get bind state of device

 @param callback bindState
 
 */
- (void) getBindStateWithCallback:(void(^_Nonnull)(HwBindState bindState, NSError * _Nullable error))callback;

/*! @brief
 Set time to device
 
 @param time 时间
 @param callback bool回调
 */
- (void) setDeviceTime:(NSDate *_Nonnull)time
              callback:(HwBoolCallback _Nullable)callback;

- (void) setDeviceTime:(NSDate *_Nonnull)time
                 is24H:(BOOL)is24H
              callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置设备时间 Set time format of watch
 
 @param is24H 是否24小时制 if time format is 24H
 @param callback bool回调
 */
- (void) setDeviceTimeWith24H:(BOOL)is24H
                     callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get time from device
 
 @param callback HwDateCallback
 
 */
- (void) getDeviceTimeWithCallback:(HwDateCallback _Nullable)callback;

/*! @brief
 Power off the watch
 
 @param callback bool
 
 */
- (void) shutdownDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Restart the watch
 
 @param callback bool
 
 */
- (void) restartDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/**
 Unbind the watch
 @param callback bool回调
 */
- (void) unbindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/**
 查询BT开关状态
 */
- (void)getBtSwitchWithCallback:(HwBoolCallback _Nullable)callback;

/**
 设置BT开关
 */
- (void)setBtSwitch:(BOOL)on callback:(HwBoolCallback _Nullable)callback;

- (void)setBtSwitch:(BOOL)on autoConnect:(BOOL)autoConnect callback:(HwBoolCallback _Nullable)callback;

/**
 Find watch
 */
- (void) findDeviceWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - World clock
- (void) setWorldClockCities:(NSArray<HwWorldClockCity *> *_Nonnull)cities
                    callback:(HwBoolCallback _Nullable)callback;
- (void) addWorldClockCity:(HwWorldClockCity *_Nonnull)city
                  callback:(HwBoolCallback _Nullable)callback;
- (void) getWorldClockCitiesWithCallback:(void(^_Nonnull)(NSArray<HwWorldClockCity *> *_Nullable cities, NSError * _Nullable error))callback;
- (void) delWorldClockCityById:(NSInteger)Id
                      callback:(HwBoolCallback _Nullable)callback;
- (void) delAllWorldClockCitiesWithCallback:(HwBoolCallback _Nullable)callback;
- (void) delWorldClockCities:(NSArray *_Nonnull)idList
                    callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 手表设置 [watch setting]

/*! @brief
 Reset the watch. After resetting, the watch will restart and return to the factory settings.
 
 @param callback bool
 
 */
- (void) resetDeviceWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 亮度 [brightness]

/*! @brief
 Set the watch screen brightness. The brightness value range is 0 to 100. The larger the value, the brighter the screen.
 
 @param value 0 ～ 100, e.g. 20/40/60/80/100
 @param callback bool
 
 */
- (void) setBrightnessValue:(NSInteger)value callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get the watch screen brightness. The brightness value range is 1 to 5. The larger the value, the brighter the screen.
 
 @param callback integer
 
 */
- (void) getBrightnessValueWithCallback:(HwBCIntegerCallback _Nullable )callback;

#pragma mark - 语言 [language]

/*! @brief
 Set watch's language
 
 @param language HwLanguage
 @param callback HwBoolCallback
 
 */
- (void) setLanguage:(HwLanguage)language callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 Get watch's language
 
 @param callback HwLanguageCallback
 
 */
- (void) getLanguageWithCallback:(HwLanguageCallback _Nullable )callback;

/*! @brief
 Get DeviceSupportedLanguages
 
 @param callback HwSupportedLanguagesCallback
 
 */
- (void) getDeviceSupportedLanguages:(HwSupportedLanguagesCallback _Nullable )callback;


#pragma mark - watch time face style

- (void) setWatchfaceWithId:(NSInteger)Id
                   callback:(HwBoolCallback _Nullable)callback;
- (void) getWatchfaceIdWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (void) setSifliDisplayingWatchfaceName:(NSString *_Nonnull)name
                                callback:(HwBoolCallback _Nullable)callback;
- (void) getSifliDisplayingWatchfaceNameWithCallback:(HwStringCallback _Nonnull)callback;
- (void) getSifliInstalledWatchfaceNamesWithCallback:(HwBCStringArrayCallback _Nonnull)callback;
- (void) delWatchfaceByWatchfaceName:(NSString *_Nonnull)name
                            callback:(HwBoolCallback _Nullable)callback;

- (void) addWatchfaceNameChangedCallback:(HwWatchfaceNameChangedCallback _Nonnull)callback;
- (void) removeWatchfaceNameChangedListener:(HwWatchfaceNameChangedCallback _Nonnull)callback;
- (void) removeAllWatchfaceNameChangedListeners;

- (void) addCurrentWeatherUnitChangedCallback:(HwCurrentWeatherUnitChangedCallback _Nonnull)callback;
- (void) removeCurrentWeatherUnitChangedListener:(HwCurrentWeatherUnitChangedCallback _Nonnull)callback;
- (void) removeAllCurrentWeatherUnitChangedListeners;

- (void) addUnitUpdateChangedListenerCallback:(HwUnitUpdateChangedCallback _Nonnull)callback;
- (void) removeUnitUpdateChangedListener:(HwUnitUpdateChangedCallback _Nonnull)callback;
- (void) removeAllUnitUpdateChangedListeners;

- (void) addDeviceAgpsShouldUpdateListener:(HwGpsShouldUpdateCallback _Nonnull)callback;
- (void) removeDeviceAgpsShouldUpdateListener:(HwGpsShouldUpdateCallback _Nonnull)callback;
- (void) removeAllDeviceAgpsShouldUpdateListeners;

- (void) addWatchfaceIdChangedListener:(HwWatchfaceIdChangedCallback _Nonnull)callback;
- (void) removeWatchfaceIdChangedListener:(HwWatchfaceIdChangedCallback _Nonnull)callback;
- (void) removeAllWatchfaceIdChangedListeners;

- (void) addDeviceRequestGpsLocationListener:(HwRequestGpsLocationCallback _Nonnull)callback;
- (void) removeDeviceRequestGpsLocationListener:(HwRequestGpsLocationCallback _Nonnull)callback;
- (void) removeAllDeviceRequestGpsLocationListeners;

- (void) setTimeFormat:(HwTimeFormat)timeFormat
              callback:(HwBoolCallback _Nullable)callback;
- (void) getTimeFormatWithCallback:(void(^_Nonnull)(HwTimeFormat timeFormat, NSError *_Nullable error))callback;

- (void) setSosName:(NSString *_Nullable)name
        phoneNumber:(NSString *_Nullable)phoneNumber
           callback:(HwBoolCallback _Nullable)callback;

- (void) setCurrentWatchfaceByIndex:(NSInteger)index
                           callback:(HwBoolCallback _Nullable)callback;
- (void) getCurrentWatchfaceIndexWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (void) addHeartrateValueChangedListener:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeHeartrateValueChangedListener:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllHeartrateValueChangedListeners;

- (void) addStressValueChangedListener:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeStressValueChangedListener:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllStressValueChangedListeners;

- (void) addSpo2ValueChangedListener:(HwSpo2ValueChangedCallback _Nonnull)callback;
- (void) removeSpo2ValueChangedListener:(HwSpo2ValueChangedCallback _Nonnull)callback;
- (void) removeAllSpo2ValueChangedListeners;

- (void) addWorkoutStateUpdatedCallback:(HwWorkoutStateUpdatedCallback _Nonnull)callback;
- (void) removeWorkoutStateUpdatedCallback:(HwWorkoutStateUpdatedCallback _Nonnull)callback;
- (void) removeAllWorkoutStateUpdatedCallbacks;

- (void) addSpO2StateUpdatedCallback:(HwSpO2StateUpdatedCallback _Nonnull)callback;
- (void) removeSpO2StateUpdatedCallback:(HwSpO2StateUpdatedCallback _Nonnull)callback;
- (void) removeAllSpO2StateUpdatedCallbacks;

/**
 Start watch SpO2 monitoring
 */
- (void) startSpO2MonitoringWithCallback:(HwBoolCallback _Nullable)callback;
/**
 Stop watch SpO2 monitoring
 */
- (void) stopSpO2MonitoringWithCallback:(HwBoolCallback _Nullable)callback;


#pragma mark - 自定义表盘 [custom watch face]
- (void) otaCustomWatchface:(HwCustomWatchface *_Nonnull)customWatchface
           progressCallback:(void(^_Nullable)(float f))progressCallback
             finishCallback:(void(^_Nullable)(BOOL b, NSError * _Nullable error))finishCallback;

- (void) otaHR04CustomWatchface:(HwCustomWatchface *_Nonnull)customWatchface
               progressCallback:(void(^_Nullable)(float f))progressCallback
                 finishCallback:(void(^_Nullable)(BOOL b, NSError * _Nullable error))finishCallback;

- (void) otaOnlineWatchface:(NSData *_Nonnull)binData
           progressCallback:(void(^_Nullable)(float f))progressCallback
             finishCallback:(void(^_Nullable)(BOOL b, NSError * _Nullable error))finishCallback;

- (void) otaOnlineWatchfaceWithID:(NSInteger)Id
                          binData:(NSData *_Nonnull)binData
                 progressCallback:(void(^_Nullable)(float f))progressCallback
                   finishCallback:(void(^_Nullable)(BOOL b, NSError * _Nullable error))finishCallback;

- (void) otaSimpleCustomWatchface:(HwSimpleCustomWatchface *_Nonnull)customWatchface
                 progressCallback:(void(^_Nullable)(float f))progressCallback
                   finishCallback:(void(^_Nullable)(BOOL b, NSError * _Nullable error))finishCallback;

#pragma mark - OTA
/**
 Each kind of Ota data needs to be assembled into HwOtaDataModel, and each kind of data can have multiple.
 1. The API will first ask whether the watch can OTA, and this step will call back readyCallback;
 2. This API will transfer data to the watch (verify while transmitting);
 3. This API will call back finishcallback to inform app of Ota results.
 Please note: if the readyCallback callback result is NO (the device does not allow OTA, or other exceptions occur), finishCallback will not be called again.
 */
- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *_Nonnull)dataModels
             otaDeviceName:(NSString *_Nonnull)otaDeviceName
             readyCallback:(HwBoolCallback _Nonnull)readyCallback
          progressCallback:(HwBCFloatCallback _Nullable)progressCallback
            finishCallback:(HwBoolCallback _Nonnull)finishCallback;
- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *_Nonnull)dataModels
              batteryLimit:(NSInteger)batteryLimit
             readyCallback:(HwBoolCallback _Nonnull)readyCallback
          progressCallback:(HwBCFloatCallback _Nullable)progressCallback
            finishCallback:(HwBoolCallback _Nonnull)finishCallback;

#pragma mark - weather

- (void) setWeatherInfoWithCity:(NSString *_Nonnull)city
                    weatherInfo:(HwWeatherInfo *_Nonnull)weatherInfo
                       forecast:(NSArray<HwWeatherInfo *> *_Nullable)forecasts
                       callback:(HwBoolCallback _Nullable)callback;

- (void) getWeatherUnitWithCallback:(void(^_Nonnull)(HwWeatherUnit unit, NSError * _Nullable error))callback;

- (void) setWeatherUnit:(HwWeatherUnit)unit
               callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取系统的语言类型（非蓝牙指令）[get system language]
 
 @return 语言类型
 */
- (HwLanguage) getSystemLanguageValue;

#pragma mark - 手机匹配弹框操作

//查询设备状态
- (void)getDeviceUpgradeStatusWithCallback:(void(^_Nullable)(HwDeviceUpgradeState state, NSError * _Nullable error))callback;
//查询匹配的状态
- (void) getPairStateWithCallback:(HwBoolCallback _Nonnull)callback;
//设置
- (void) requestDeviceToPairWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 获取BT连接状态
- (void) getBtConnectionStateWithCallback:(HwBoolCallback _Nullable)callback;

- (void) setAppState:(HwAppState)state
            callback:(HwBoolCallback _Nullable)callback;

#pragma mark - power
/*! @brief
 Get watch's battery
 
 @param callback 回调0-100
 
 */
- (void) getBatteryWithCallback:(HwBCIntegerCallback _Nonnull)callback;

/*! @brief
 Get watch's battery and charging state
 
 @param callback battery: 0%~100%, charging: BOOL
 */
- (void) getBatteryStateWithCallback:(HwBatteryStateCallback _Nonnull)callback;

/*! @brief
 Callback when battery or charging state changed
 
 @param callback battery: 0%~100%, charging: BOOL
 */
- (void) addBatteryStateChangedListener:(HwBatteryStateChangedCallback _Nonnull)callback;
- (void) removeBatteryStateChangedListener:(HwBatteryStateChangedCallback _Nonnull)callback;
- (void) removeAllBatteryStateChangedListeners;

/*! @brief
 Get the timeout time of device screen lightening.
 The value of the callback is in seconds.
 
 @param callback 回调
 
 */
- (void) getScreenOnDurationWithCallback:(HwBCIntegerCallback _Nonnull)callback;

/*! @brief
 Set the timeout time of device screen lightening.
 We recommend the timeout length of 5 seconds, 10 seconds, 15 seconds, 30 seconds, 45 seconds and 60 seconds.
 
 @param second second
 @param callback callback
 */
- (void) setScreenOnDuration:(NSInteger)second
                    callback:(HwBoolCallback _Nullable)callback;


#pragma mark - 设置生理周期
/// 设置生理周期
/// @param periods 想要传递的周期
/// @param callback 回调
- (void)setMenstrualPeriods:(NSArray<HwMenstrual *> *_Nonnull)periods
                   callback:(HwBoolCallback _Nullable)callback __attribute__((deprecated("Use -setPhysiologicalPeriodSetting:callback:")));

- (void)setNewMenstrualPeriods:(NSArray<HwMenstrual *> *_Nonnull)periods
                      callback:(HwBoolCallback _Nullable)callback __attribute__((deprecated("Use -setPhysiologicalPeriodSetting:callback:")));

- (void) setPhysiologicalPeriodSetting:(HwPhysiologicalPeriodSetting *_Nonnull)setting
                              callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 设备屏锁密码
/**
 Set device's passcode
 */
- (void) setDevicePasscode:(NSString *_Nonnull)passcode
                  callback:(HwBoolCallback _Nullable)callback;

/**
 Set device's switch and passcode
 */
- (void) setDevicePasscode:(NSString *_Nonnull)passcode
                        on:(BOOL)on
                  callback:(HwBoolCallback _Nullable)callback;

/**
 Delete watch's passcode
 */
- (void) delDevicePasscodeWithCallback:(HwBoolCallback _Nullable)callback;

/**
 Get watch's switch and passcode
 */
- (void) getDeviceSwitchPasscodeWithCallback:(HwDevicePasscodeCallback _Nullable)callback;

/**
 Get watch's passcode
 */
- (void) getDevicePasscodeWithCallback:(HwStringCallback _Nullable)callback;

#pragma mark - 设备数据
/**
 Delete all activity/sleep/heartrate/hrv data on watch
 */
- (void) deleteDeviceDataWithCallback:(HwBoolCallback _Nullable)callback;

/**
 Set contacts to watch
 */
- (void) setContacts:(NSArray<HwContact *> *_Nullable)contacts
            callback:(HwBoolCallback _Nullable)callback;

- (void) setContactsV2:(NSArray<HwContact *> *_Nullable)contacts
            callback:(HwBoolCallback _Nullable)callback;

- (void) getContactsWithCallback:(void(^_Nonnull)(NSArray<HwContact *> *_Nullable contacts, NSError *_Nullable error))callback;

#pragma mark - 运动相关APIs
#pragma mark - goal 目标[goal]
/*! @brief
 设置目标值[set goal value]
 
 @param type 类型[type]
 @param goal 目标值[gole]
 @param callback 回调[callback]
 
 */
- (void) setGoalWithType:(HwGoalType)type
                    goal:(NSInteger)goal
                callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 获取目标值[gain goal value]
 
 @param callback 数据模型回调[data models callback]
 
 */
- (void) getGoalWithCallback:(HwGoalInfoCallback _Nullable)callback;

- (void) addGoalUpdatedListener:(HwGoalUpdatedCallback _Nonnull)callback;
- (void) removeGoalUpdatedListener:(HwGoalUpdatedCallback _Nonnull)callback;
- (void) removeAllGoalUpdatedListeners;

- (void) addGoalsUpdatedListener:(HwGoalsUpdatedCallback _Nonnull)callback;
- (void) removeGoalsUpdatedListener:(HwGoalsUpdatedCallback _Nonnull)callback;
- (void) removeAllGoalsUpdatedListeners;

- (void) addHealthDataUpdatedListener:(HwHealthDataUpdatedCallback _Nonnull)callback;
- (void) removeHealthDataUpdatedListener:(HwHealthDataUpdatedCallback _Nonnull)callback;
- (void) removeAllHealthDataUpdatedListeners;

#pragma mark - Health data
/*! @brief
 Get the newest heartrate data.
 */
- (void) getNewestHeartrateWithCallback:(HwNewestHeartRateCallback _Nonnull)callback;

/*! @brief
 Get all health data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getHealthDataForLSWithStartTime:(NSTimeInterval)startTime
                                 endTime:(NSTimeInterval)endTime
                      activitiesCallback:(HwActivitiesCallback _Nonnull)activitiesCallback
                         activesCallback:(HwActivesCallback _Nonnull)activesCallback
                          sleepsCallback:(HwSleepsCallback _Nonnull)sleepsCallback
                      heartratesCallback:(HwHeartRateInfoArrayCallback _Nonnull)heartratesCallback
                           spo2sCallback:(HwSpo2sCallback _Nonnull)spo2sCallback
                          stressCallback:(HwStressCallback _Nonnull)stressCallback;

/*! @brief
 Get Aactivity data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getActivitiesForLSWithStartTime:(NSTimeInterval)startTime
                                 endTime:(NSTimeInterval)endTime
                      activitiesCallback:(HwActivitiesCallback _Nonnull)activitiesCallback;
/*! @brief
 Get active data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getActiveForLSWithStartTime:(NSTimeInterval)startTime
                             endTime:(NSTimeInterval)endTime
                     activesCallback:(HwActivesCallback _Nonnull)activesCallback;
/*! @brief
 Get sleep data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getSleepsForLSWithStartTime:(NSTimeInterval)startTime
                             endTime:(NSTimeInterval)endTime
                      sleepsCallback:(HwSleepsCallback _Nonnull)sleepsCallback;
/*! @brief
 Get heart rate data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getHeartratesForLSWithStartTime:(NSTimeInterval)startTime
                                 endTime:(NSTimeInterval)endTime
                      heartratesCallback:(HwHeartRateInfoArrayCallback _Nonnull)heartratesCallback;
/*! @brief
 Get Stress data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getStressForLSWithStartTime:(NSTimeInterval)startTime
                             endTime:(NSTimeInterval)endTime
                      stressCallback:(HwStressCallback _Nonnull)stressCallback;
/*! @brief
 Get spO2 data between startTime and endTime. This API is only useful for LS16 watches
 */
- (void) getSpO2sForLSWithStartTime:(NSTimeInterval)startTime
                            endTime:(NSTimeInterval)endTime
                      spO2sCallback:(HwSpo2sCallback _Nonnull)spO2sCallback;
/*! @brief
 Get blood pressure data. This API is only useful for watches with blood pressure feature supported.
 */
- (void) getBpsWithCallback:(HwBpsCallback _Nonnull)bpsCallback;
- (void) delBpsWithCallback:(HwBoolCallback _Nullable)callback;

- (void) getPAIsWithCallback:(HwPAIsCallback _Nonnull)callback;
- (void) delPAIsWithCallback:(HwBoolCallback _Nullable)callback;
- (void) getVO2maxsWithCallback:(HwVO2maxsCallback _Nonnull)callback;
- (void) delVO2maxsWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get the number of health data in the watch,
 including: number of activity data, number of heart rate data, number of sleep data, number of blood oxygen data, number of pressure data
 */
- (void) getHealthDataCountWithCallback:(HwHealthDataCountCallback _Nullable)callback;

/*! @brief
 Get the activity data (steps, calories, distance and exercise duration) of the health data in the watch, the number of activity data to be passed in is returned by the interface 'getHealthDataCountWithCallback'.
 
 @param activityCount number of activity data, returned by API 'getHealthDataCountWithCallback'
 */
- (void) getActivities:(NSUInteger)activityCount callback:(HwActivitiesCallback _Nullable)callback;

/*! @brief
 Delete the activity data.
 After getting the data, it should be called once to ensure that there is not too much data left in the watch. The next time getting the data, it will not obtain the old data, so as to improve the speed of getting the data. 
 */
- (void) deleteActivitiesWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - sleep
/*! @brief
 Get the sleep data of the health data in the watch, the number of sleep point data to be passed in is returned by the interface 'getHealthDataCountWithCallback'.
 
 @param sleepPointCount number of sleep point data, returned by API 'getHealthDataCountWithCallback'
 */
- (void) getSleeps:(NSUInteger)sleepPointCount callback:(HwSleepsCallback _Nonnull)callback;

/*! @brief
 Delete the sleep data.
 After getting the data, it should be called once to ensure that there is not too much data left in the watch. The next time getting the data, it will not obtain the old data, so as to improve the speed of getting the data.
 
 */
- (void) deleteSleepsWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - SedentaryReminder
typedef void (^HwSedentaryReminderCallback)(HwSedentaryReminder *_Nullable reminder, NSError *_Nullable error);

/*! @brief
 Get sedentary reminder config to the device
 
 @param callback callback
 */
- (void) getSedentaryReminderWithCallback:(HwSedentaryReminderCallback _Nonnull)callback;

/**
 * Set sedentary reminder config to the device
 *
 * @param reminder SedentaryReminder config
 * @param callback BoolCallback
 */
- (void) setSedentaryReminder:(HwSedentaryReminder *_Nonnull)reminder
                     callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Get sedentary reminder config to the device
 
 @param callback callback
 */
- (void) getSedentaryReminderForLS16WithCallback:(HwSedentaryReminderForLS16Callback _Nonnull)callback;

/**
 * Set sedentary reminder config to the device
 *
 * @param reminder SedentaryReminder config
 * @param callback BoolCallback
 */
- (void) setSedentaryReminderForLS16:(HwSedentaryReminderForLS16 *_Nonnull)reminder
                            callback:(HwBoolCallback _Nullable)callback;





#pragma mark - Heart rate data
/*! @brief
 Get the heart rate data of the health data in the watch, the number of sleep point data to be passed in is returned by the interface 'getHealthDataCountWithCallback'.
 
 @param count number of heart rate data, returned by API 'getHealthDataCountWithCallback'
 */
- (void) getHeartrates:(NSUInteger)count callback:(HwHeartRateInfoArrayCallback _Nullable)callback;

/*! @brief
 Delete the heart rate data.
 After getting the data, it should be called once to ensure that there is not too much data left in the watch. The next time getting the data, it will not obtain the old data, so as to improve the speed of getting the data.
 */
- (void) deleteHeartratesWithCallback:(HwBoolCallback _Nullable)callback;

typedef void (^HwHeartrateFatiguesCallback)(NSArray<HwHeartrateFatigue *> *_Nullable heartrateFatigues, NSError *_Nullable error);
/**
 根据心率疲劳度个数获取设备中的心率疲劳度详情[get the heartrate fatigue detail based on the heartrate fatigue numbers]
 
 @param count 心率疲劳度个数[heartrate fatigue numbers]
 @param callback 详情回调[detail callback]
 */
- (void) getHeartrateFatigues:(NSUInteger)count callback:(HwHeartrateFatiguesCallback _Nullable)callback;

/**
 删除心率疲劳度详情[delete heartrate fatigue detail]
 
 @param callback 成功与否回调[callback successfully or not]
 */
- (void) deleteHeartrateFatiguesWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置手表自动检测心率时间间隔[set the time span of the heartrate auto-check]
 
 @param interval 每隔多少分钟产生一笔心率数据，有效值有：0、5、10、15、30、45、60[how often a new heartrate will be produced, effective value: 0 ,5,10,15,30,45,60]
 其中0表示关闭['0' is off]
 @param callback 回调[callback]
 */
- (void) setHeartrateMonitoringInterval:(int)interval
                               callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Heart rate monitoring interval
 回调中的整型单位是分种[unit of callback is minute]
 @param callback 回调(NSInteger, NSError)
 */
- (void) getHeartrateMonitoringIntervalWithCallback:(HwBCIntegerCallback _Nullable)callback;

typedef void (^HwHeartrateAlarmCallback)(HwHeartrateAlarm *_Nullable hrAlarm, NSError *_Nullable error);
/*! @brief
 Get the heart rate alarm configuration of the watch
 
 @param callback 回调[callback]
 
 */
- (void) getHeartrateAlarmWithCallback:(HwHeartrateAlarmCallback _Nullable)callback;


/*! @brief
 Set the heart rate alarm configuration of the watch
 @param hrAlarm config
 @param callback callback
 */
- (void) setHeartrateAlarm:(HwHeartrateAlarm *_Nonnull)hrAlarm
                  callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置血氧自动检测值
 
 @param span 检测时间间隔[check the span ]
 @param callback 回调[callback]
 */
- (void) autoDetectBloodOxygenWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取血氧自动检测的值[Get the value of the automatic blood oxygen test]
 
 @param callback 回调[callback]
 */
- (void) getAutoDetectBloodOxygenSpanWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置低血氧提醒
 
 @param span 低血氧提醒罚值[check the span ]
 @param callback 回调[callback]
 */
- (void) setBloodOxygenAlertWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取低血氧提醒的值[Get the value of the blood oxygen alert]
 
 @param callback 回调[callback]
 */
- (void) getBloodOxygenAlertWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置压力自动检测值
 
 @param span 检测时间间隔[check the span ]
 @param callback 回调[callback]
 */
- (void) autoDetectStressWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取压力自动检测的值[Gets the value of the automatic pressure detection]
 
 @param callback 回调[callback]
 */
- (void) getAutoDetectStressSpanWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 Get automatic stress monitoring switch
 @param callback callback
 
 */
- (void) getStressMonitorEnableWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Set automatic stress monitoring switch
 
 @param on switch status
 @param callback callback
 */
- (void) setStressMonitorEnable:(BOOL)on
                       callback:(HwBoolCallback _Nullable)callback;

- (void) getSpO2MonitorEnableWithCallback:(HwBoolCallback _Nullable)callback;
- (void) setSpO2MonitorEnable:(BOOL)on
                     callback:(HwBoolCallback _Nonnull)callback;
- (void) getAODEnableWithCallback:(HwBoolCallback _Nonnull)callback;
- (void) setAODEnable:(BOOL)on
             callback:(HwBoolCallback _Nonnull)callback;

- (void) getLiftWristAwakenEnableWithCallback:(HwBoolCallback _Nonnull)callback;
- (void) setLiftWristAwakenEnable:(BOOL)on callback:(HwBoolCallback _Nullable)callback;

// 删除压力详情
- (void) deleteStressWithCallback:(HwBoolCallback _Nullable)callback;
// 删除血氧详情
- (void) deleteBloodOxygenWithCallback:(HwBoolCallback _Nullable)callback;
// 删除hrv详情
- (void) deleteHrvWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 用户相关API接口[API port]
#pragma mark - 用户信息[user's information]
/*! @brief
 设置个人信息[set personal details]
 
 gender 性别 0 --> 男、1 --> 女[gender]
 age 年龄（设备上默认的单位：岁）[age]
 height 身高（设备上默认的单位：cm）[height(default unit is cm)]
 weight 体重（设备上默认的单位：0.1KG）[weight(default unit is kg)]
 */
- (void) setUserInfo:(HwUserInfo *_Nonnull)userInfo
            callback:(HwBoolCallback _Nullable)callback;

- (void) getUserInfoWithCallback:(void(^_Nonnull)(HwUserInfo *_Nonnull userInfo, NSError *_Nullable error))callback;

#pragma mark - 用户习惯[user's habit]
/*! @brief
 获取用户带手表的习惯（左右手）[get user's habit of wearing watches]
 
 @param callback 回调[callback]
 */
- (void) getUserHandHabitWithCallback:(HwBCHandHabitCallback _Nonnull)callback;

/*! @brief
 设置用户带手表习惯[set user's habit of wearing watches]
 
 @param handHabit 左右手[handHabit]
 @param callback 回调[callback]
 */
- (void) setUserHandHabit:(HwHandHabit)handHabit
                 callback:(HwBoolCallback _Nullable)callback;

- (void) getHandwashingConfigWithCallback:(HwHandwashingConfigCallback _Nonnull)callback;

- (void) setHandwashingConfig:(HwHandwashingConfig *_Nonnull)config
                     callback:(HwBoolCallback _Nullable)callback;


- (void) getDrinkWaterConfigWithCallback:(HwDrinkWaterConfigCallback _Nonnull)callback;

- (void) setDrinkWaterConfig:(HwDrinkWaterConfig *_Nonnull)config
                    callback:(HwBoolCallback _Nullable)callback;

#pragma mark - Drink water records
- (void) getAvailableDrinkWaterRecordIdsWithCallback:(HwDrinkWaterRecordIdsCallback _Nonnull)callback;
- (void) getAllDrinkWaterRecordsWithCallback:(HwDrinkWaterRecordsCallback _Nonnull)callback;
- (void) addDrinkWaterRecord:(HwDrinkWaterRecord *_Nonnull)record callback:(HwBoolCallback _Nullable)callback;
- (void) editDrinkWaterRecord:(HwDrinkWaterRecord *_Nonnull)record callback:(HwBoolCallback _Nullable)callback;
- (void) deleteDrinkWaterRecordWithId:(NSInteger)recordId callback:(HwBoolCallback _Nullable)callback;
- (void) deleteAllDrinkWaterRecordsWithCallback:(HwBoolCallback _Nullable)callback;
- (void) setAllDrinkWaterRecords:(NSArray<HwDrinkWaterRecord *> *_Nonnull)records callback:(HwBoolCallback _Nullable)callback;
- (void) addDrinkWaterRecordsChangedListener:(HwDrinkWaterRecordsChangedCallback _Nonnull)callback;
- (void) removeDrinkWaterRecordsChangedListener:(HwDrinkWaterRecordsChangedCallback _Nonnull)callback;
- (void) removeAllDrinkWaterRecordsChangedListeners;

#pragma mark - Phone schedule sync
- (void) syncPhoneSchedules:(NSArray<HwPhoneScheduleEvent *> *_Nonnull)events callback:(HwBoolCallback _Nullable)callback;

#pragma mark - Standing setting
- (void) getStandingSettingWithCallback:(HwStandingSettingCallback _Nonnull)callback;
- (void) setStandingSetting:(HwStandingSetting *_Nonnull)setting callback:(HwBoolCallback _Nullable)callback;

#pragma mark - Workout APIs
- (void) getWorkoutsWithCallback:(HwWorkoutsCallback _Nonnull)callback;
/*! @brief
 Whether the watch is exercising, 1 indicates that it is exercising, 0 indicates that it is not exercising
 */
- (void) getWorkoutStateWithCallback:(HwBCIntegerCallback _Nonnull)callback;

/*! @brief
 Get workout data between startTime and endTime
 @param callback HwWorkoutsCallback
 */
- (void) getWorkoutsForLSWithStartTime:(NSTimeInterval)startTime
                               endTime:(NSTimeInterval)endTime
                              callback:(HwWorkoutsCallback _Nonnull)callback;

/*! @brief
 Delete workout data on the watch, it will not effect the display on the watch.
 
 @param callback HwBoolCallback
 */
- (void) deleteWorkoutsWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Set workout realtime data
 
 @param realtimeData HwWorkoutRealtimeData
 @param callback HwBoolCallback
 */
- (void) setWorkoutRealtimeData:(HwWorkoutRealtimeData *_Nonnull)realtimeData
                       callback:(HwBoolCallback _Nullable)callback;
/*! @brief
 Get workout realtime data
 
 @param callback HwWorkoutRealtimeDataCallback
 */
- (void) getWorkoutRealtimeDataWithCallback:(HwWorkoutRealtimeDataCallback _Nonnull)callback;

/*! @brief
 Set the current GPS location data
 
 @param longitude longitude
 @param latitude latitude
 @param time timestamp
 @param callback HwBoolCallback
 */
- (void) setDeviceGpsLocationWithLongitude:(double)longitude
                                  latitude:(double)latitude
                                      time:(long)time
                                  callback:(HwBoolCallback _Nullable )callback;
// 和上面的区别就是，这个gps精度要求不高
- (void) setDeviceNonPreciseGpsLocationWithLongitude:(double)longitude
                                            latitude:(double)latitude
                                                time:(long)time
                                            callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 Start workout
 */
- (void) startWorkoutWithType:(HwWorkoutType)type
                     callback:(HwBoolCallback _Nullable)callback;

- (void) startWorkoutWithType:(HwWorkoutType)type
                     goalType:(NSInteger)goalType
                    goalValue:(NSInteger)goalVal
                     callback:(HwBoolCallback _Nullable)callback;

- (void) startWorkoutWithType:(HwWorkoutType)type
                    goalTypes:(NSArray<NSNumber *> * _Nonnull)goalTypes
                   goalValues:(NSArray<NSNumber *> * _Nonnull)goalVals
                     callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Start workout
 */
- (void) startWorkoutWithType:(HwWorkoutType)type
           dataUpdateInterval:(NSInteger)dataUpdateInterval
                     callback:(HwBoolCallback _Nullable)callback;
/*! @brief
 Suspend workout
 */
- (void) suspendWorkoutWithCallback:(HwBoolCallback _Nullable)callback;
/*! @brief
 Resume workout
 */
- (void) resumeWorkoutWithCallback:(HwBoolCallback _Nullable)callback;
/*! @brief
 Stop workout
 */
- (void) stopWorkoutWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 Add workout realtime data update listener
 */
- (void) addWorkoutRealtimeDataUpdateListener:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
/*! @brief
 Remove workout realtime data update listener
 */
- (void) removeWorkoutRealtimeDataUpdateListener:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
/*! @brief
 Remove all workout realtime data update listeners
 */
- (void) removeAllWorkoutRealtimeDataUpdateListeners;

#pragma mark - 状态设置 APIs
- (void) getFeatureSwitchesWithCallback:(HwFeatureSwitchCallback _Nonnull)callback;

- (void) setFeatureSwitchWithType:(HwFeatureSwitchType)type
                                S:(BOOL)S
                         callback:(HwBoolCallback _Nullable)callback;

- (void) getFeatureSwitchStateOfType:(HwFeatureSwitchType)type
                            callback:(HwBoolCallback _Nullable)callback;
// 如果没有传，默认是关闭[if it is not spread, default is off]
- (void) setAllFeatureSwitches:(NSArray<HwFeatureSwitch *> *_Nonnull)models
                      callback:(HwBoolCallback _Nullable)callback;

#pragma mark - social switch
- (void) getSocialSwitchesWithCallback:(HwSocialSwitchesCallback _Nonnull)callback;

- (void) setSocialSwitchWithType:(HwSocialSwitchType)type
                               S:(BOOL)S
                        callback:(HwBoolCallback _Nullable)callback;

- (void) setSocialSwitch:(HwSocialSwitch *_Nonnull)ss
                callback:(HwBoolCallback _Nullable)callback;

- (void) setSocialSwitches:(NSArray<HwSocialSwitch *> *_Nonnull)models
                  callback:(HwBoolCallback _Nullable)callback;

- (void) setSocialApps:(NSArray<HwSocialApp *> *_Nonnull)socialApps
      progressCallback:(HwBCFloatCallback _Nonnull)progressCallback
        finishCallback:(HwBoolCallback _Nonnull)finishCallback;

- (void) getSocialAppsWithCallback:(HwSocialAppsCallback _Nonnull)callback;

#pragma mark - Reminder
- (void) getRemindersWithCallback:(HwRemindersCallback _Nonnull)callback;
- (void) getAvailableReminderIdWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (void) addReminder:(HwReminder *_Nonnull)reminder
            callback:(HwBoolCallback _Nullable)callback;

- (void) updateReminder:(HwReminder *_Nonnull)reminder
               callback:(HwBoolCallback _Nullable)callback;

- (void) deleteReminderByID:(NSUInteger)Id
                   callback:(HwBoolCallback _Nullable)callback;

- (void) deleteRemindersWithCallback:(HwBoolCallback _Nullable)callback;

/*
 根据type类型，查询提醒总数
  */
- (void) getAllReminderEventCountByType:(HwReminderType)type
                                            callback:(HwBCIntegerCallback _Nonnull)callback;
/*
 根据type类型，获取提醒数据
 */
- (void) getAllReminderEvents:(HwReminderType)type
                                  callback:(HwRemindersCallback _Nonnull)callback;

/*
 根据type类型，删除该类型全部提醒
 */
- (void) delAllReminderEvents:(HwReminderType)type
                                  callback:(HwBoolCallback _Nonnull)callback;
/*
 根据type类型，批量覆盖添加
 */
- (void) setReminderEvents:(NSArray<HwReminder *> *_Nonnull)reminderList
                      type:(HwReminderType)type
                  callback:(HwBoolCallback _Nullable)callback;

#pragma mark - Alarms
/**
 Get all alarms in the watch.
 */
- (void) getAlarmsWithCallback:(HwAlarmsCallback _Nonnull)callback;
/**
 Get an id for alarm, which uses to set the alarm if needed
 */
- (void) getAvailableAlarmIdWithCallback:(HwBCIntegerCallback _Nonnull)callback;

/**
 Add an alarm
 */
- (void) addAlarm:(HwAlarm *_Nonnull)alarm
         callback:(HwBoolCallback _Nullable)callback;

/**
 Set alarms in batch. This API will overwrite other alarms in the watch.
 */
- (void) setAlarms:(NSArray<HwAlarm *> *_Nonnull)alarmList
          callback:(HwBoolCallback _Nullable)callback;

- (void) updateAlarm:(HwAlarm *_Nonnull)alarm
            callback:(HwBoolCallback _Nullable)callback;

- (void) deleteAlarmByID:(NSUInteger)Id
                callback:(HwBoolCallback _Nullable)callback;

- (void) deleteAlarmsWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - QrCode Card
- (void) getQrcodeCardsWithCallback:(HwQrcodeCardsCallback _Nonnull)callback;
- (void) getQrcodeCardContentById:(NSInteger)Id
                         callback:(HwStringCallback _Nonnull)callback;
- (void) addQrcodeCard:(HwQrCard *_Nonnull)card
              callback:(HwBoolCallback _Nonnull)callback;
- (void) editQrcodeCard:(HwQrCard *_Nonnull)card
               callback:(HwBoolCallback _Nonnull)callback;
- (void) delQrcodeCardById:(NSInteger)Id
                  callback:(HwBoolCallback _Nonnull)callback;
- (void) delAllQrcodeCardsWithCallback:(HwBoolCallback _Nonnull)callback;
- (void) setElectronicCardSorts:(NSArray *_Nonnull)cardSorts callback:(HwBoolCallback _Nonnull)callback;

#pragma mark - Events
/**
 After clicking on the watch to find my phone, the watch will send instructions to the app. After receiving the instructions, the app will respond to the watch with 'acceptedFindMyPhoneRequest', which has received the instructions, and then carry out its own business operations
 */
- (void) addFindMyPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;
- (void) removeFindMyPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;
- (void) removeAllFindMyPhoneCallbacks;
- (void) acceptedFindMyPhoneRequest;

/**
 The equipment regularly sends events to the app, which can be processed or ignored by the app, depending on the specific requirements
 
 @param callback 回调
 */
- (void) addDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
- (void) removeDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
- (void) removeAllDeviceEventCallbacks;

typedef void (^HwBtConnectionStateCallback)(BOOL connected);
/**
 In BLE and BT single-chip watches, the iPhone (ios13 or later) will automatically connect to BT after being paired with BLE.
 Due to the bug of the iPhone itself, sometimes the BT connection fails. At this time, the firmware will notify the app. From the product point of view, the app needs to prompt the user to go to the Bluetooth settings of the mobile phone and click the name of the paired watch.
 */
- (void) addBtConnectionStateCallback:(HwBtConnectionStateCallback _Nonnull)callback;
- (void) removeBtConnectionStateCallback:(HwBtConnectionStateCallback _Nonnull)callback;
- (void) removeAllBtConnectionStateCallbacks;

/**
 If the pairing request between the watch and the mobile phone is initiated by the mobile phone, the device will notify the app after the pairing is completed
 */
- (void) addDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeAllDevicePairStateCallbacks;

#pragma mark - Error Code Handle
- (void) setHandler:(void(^_Nonnull)(HwBluetoothData * _Nullable dataModel))handler
       forErrorCode:(HwBCCode)errorCode;
- (void) clearErrorCodeHandlers;

#pragma mark - Album
- (void) getAlbumFilesCountWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (void) getAlbumFilesIdListWithCallback:(HwBCArrayCallback _Nonnull)callback;
- (void) delAlbumFiles:(NSArray *_Nullable)idList
                                    callback:(HwBoolCallback _Nonnull)callback;
- (void) delAllAlbumFilesWithCallback:(HwBoolCallback _Nonnull)callback;

- (void) getMusicAvailableStorageWithCallback:(HwAvailableStorageCallback _Nonnull)callback;
- (void) getOfflineMapAvailableStorageWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (void) getCoustomInterfaceAvailableStorageWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (void) addDeviceMusicStorageChangedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeDeviceMusicStorageChangedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeAllDeviceMusicStorageChangedListeners:(HwAvailableStorageCallback _Nonnull)callback;

#pragma mark - 高原关爱
- (void) setPlateauCareWithInterval:(NSInteger)interval
                           callback:(HwBoolCallback _Nullable)callback;
- (void) getPlateauCareWithCallback:(HwBCIntegerCallback _Nonnull)callback;

#pragma mark - AI

#pragma mark - AI智能体
- (void) setAiAgentsWithAiAgents:(NSArray<HwAiAgent *> * _Nonnull)aiAgents
                                              callback:(HwBoolCallback _Nullable)callback;
- (void) getAiAgentsWithCallback:(void(^_Nonnull)(NSArray<HwAiAgent *> *_Nullable aiAgents, NSError *_Nullable error))callback;

/// Tell watch the app status
/// @param appStatus HwAppState
- (void)setAppStatus:(HwAppState)appStatus;

/// Response watch start recording request
/// @param code 0 represents success
/// @param msg error message
- (void) setStartRecordingResultWithCode:(int)code
                                     msg:(NSString *_Nullable)msg;

/// Response watch end recording request
/// @param code 0 represents success
/// @param msg error message
- (void) setEndRecordingResultWithCode:(int)code
                                   msg:(NSString *_Nullable)msg;

- (void) setRecordToTextResultWithResult:(NSString *_Nullable)result
                                    code:(int)code
                                     msg:(NSString *_Nullable)msg;

- (void) setAiAnswerResultWithResult:(NSString *_Nullable)result
                                code:(int)code
                                 msg:(NSString *_Nullable)msg;

- (void) setAiTranslateResultWithResult:(NSString *_Nullable)result
                                   code:(int)code
                                    msg:(NSString *_Nullable)msg;

- (void) setAiAgentResultWithResult:(NSString *_Nullable)result
                               code:(int)code
                                msg:(NSString *_Nullable)msg;
- (void) setAiMeetingResult:(HwMeeting *_Nullable)meeting
                       type:(NSInteger)type
                       code:(int)code
                        msg:(NSString *_Nullable)msg;

- (void) notifyAiMeetingHandling;

- (void) setAiWatchfacePreviewWithPreviewName:(NSString *_Nullable)previewName
                                         code:(int)code
                                          msg:(NSString *_Nullable)msg;

- (void) setAiWatchfaceResultWithWatchfaceName:(NSString *_Nullable)watchfaceName
                                          code:(int)code
                                           msg:(NSString *_Nullable)msg;
- (void) getAiRecordDataWithCallback:(HwDataCallback _Nonnull)callback;
- (void) getJLAiRecordDataWithCallback:(HwDataCallback _Nonnull)callback;

- (void) getMeetingRecordDataWithCallback:(HwDataCallback _Nonnull)callback;

- (void) addAiWatchfaceEnterOrExitListener:(HwAiWatchfaceEnterOrExitCallback _Nonnull)callback;
- (void) removeAiWatchfaceEnterOrExitListener:(HwAiWatchfaceEnterOrExitCallback _Nonnull)callback;
- (void) removeAllAiWatchfaceEnterOrExitListeners;

- (void) addAiAnswerEnterOrExitListener:(HwAiAnswerEnterOrExitCallback _Nonnull)callback;
- (void) removeAiAnswerEnterOrExitListener:(HwAiAnswerEnterOrExitCallback _Nonnull)callback;
- (void) removeAllAiAnswerEnterOrExitListeners;

- (void) addAppStatusRequestListener:(HwAppStatusRequestCallback _Nonnull)callback;
- (void) removeAppStatusRequestListener:(HwAppStatusRequestCallback _Nonnull)callback;
- (void) removeAllAppStatusRequestListeners;

- (void) addStartRecordingRequestListener:(HwStartRecordingCallback _Nonnull)callback;
- (void) removeStartRecordingRequestListener:(HwStartRecordingCallback _Nonnull)callback;
- (void) removeAllStartRecordingRequestListeners;

- (void) addEndRecordingRequestListener:(HwEndRecordingCallback _Nonnull)callback;
- (void) removeEndRecordingRequestListener:(HwEndRecordingCallback _Nonnull)callback;
- (void) removeAllEndRecordingRequestListeners;

- (void) addGenerateAiWatchfaceRequestListener:(HwGenerateAiWatchfaceRequestCallback _Nonnull)callback;
- (void) removeGenerateAiWatchfaceRequestListener:(HwGenerateAiWatchfaceRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiWatchfaceRequestListeners;

- (void) addGenerateAiAnswerRequestListener:(HwGenerateAiAnswerRequestCallback _Nonnull)callback;
- (void) removeGenerateAiAnswerRequestListener:(HwGenerateAiAnswerRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiAnswerRequestListeners;

- (void) addGenerateAiWatchfacePreviewRequestListener:(HwGenerateAiWatchfacePreviewRequestCallback _Nonnull)callback;
- (void) removeGenerateAiWatchfacePreviewRequestListener:(HwGenerateAiWatchfacePreviewRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiWatchfacePreviewRequestListeners;

- (void) addAiEventListener:(HwAiEventCallback _Nonnull)callback;
- (void) removeAiEventListener:(HwAiEventCallback _Nonnull)callback;
- (void) removeAllAiEventListeners;

- (void) addAiSettingUpdateListener:(HwAiSettingUpdateCallback _Nonnull)callback;
- (void) removeAiSettingUpdateListener:(HwAiSettingUpdateCallback _Nonnull)callback;
- (void) removeAllAiSettingUpdateListeners;

- (void) addGenerateAiMeetingRequestListener:(HwGenerateAiMeetingRequestCallback _Nonnull)callback;
- (void) removeGenerateAiMeetingRequestListener:(HwGenerateAiMeetingRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiMeetingRequestListeners;

- (void) addGenerateAiHealthAnalysisRequestListener:(HwGenerateAiHealthAnalysisRequestCallback _Nonnull)callback;
- (void) removeGenerateAiHealthAnalysisRequestListener:(HwGenerateAiHealthAnalysisRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiHealthAnalysisRequestListeners;
- (void) setAiHealthAnalysisResultWithResult:(HwHealthAnalysisResult *_Nullable)result
                                        code:(int)code
                                         msg:(NSString *_Nullable)msg;


- (void) addGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiTranslateRequestListeners;

- (void) addGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiAgentResultRequestListeners;

- (void) addAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAllAiAnswerHandlerListeners;

#pragma mark - 穆斯林朝拜
- (void) setMuslimWorshipSwitches:(NSArray<HwMuslimWorshipSwitch *> *_Nonnull)swList
                                               callback:(HwBoolCallback _Nullable)callback;
- (void) getMuslimWorshipSwitchesWithCallback:(HwMuslimWorshipSwitchesCallback _Nonnull)callback;

- (void) setPrayerBeadsSwitch:(HwPrayerBeadsSwitch *_Nonnull)sw
                     callback:(HwBoolCallback _Nullable)callback;
- (void) setPrayerBeadsSwitchState:(BOOL)on
                          callback:(HwBoolCallback _Nullable)callback;
- (void) setPrayerBeadsSwitchStartHour:(NSInteger)startHour
                           startMinute:(NSInteger)startMinute
                              callback:(HwBoolCallback _Nullable)callback;
- (void) setPrayerBeadsSwitchEndHour:(NSInteger)endHour
                           endMinute:(NSInteger)endMinute
                            callback:(HwBoolCallback _Nullable)callback;

- (void) setPrayerBeadsSwitchInterval:(NSTimeInterval)interval
                             callback:(HwBoolCallback _Nullable)callback;

- (void) setPrayerBeadsSwitchInteractiveType:(HwPrayerBeadsInteractiveType)type
                                    callback:(HwBoolCallback _Nullable)callback;

- (void) getPrayerBeadsSwitchWithCallback:(HwHwPrayerBeadsSwitchCallback _Nonnull)callback;

- (void) getWorshipCompassStyleWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (void) setWorshipCompassStyle:(NSInteger)style
                       callback:(HwBoolCallback _Nullable)callback;
- (void) getCollectedAllahIndexsWithCallback:(HwCollectedAllahIndexsCallback _Nonnull)callback;
- (void) setCollectedAllahIndexs:(NSArray<NSNumber *> *_Nonnull)list
                        callback:(HwBoolCallback _Nullable)callback;

- (void) setPrayerAlertTime:(NSArray<HwMuslimDayAlert *> *_Nonnull)dayAlertList
                   callback:(HwBoolCallback _Nullable)callback;
- (void) getPrayerAlertTimeWithCallback:(HwBoolCallback _Nullable)callback;

- (void) setAiSubscriptionInfoWithType:(NSInteger) type
                             startTime:(NSTimeInterval)startTime
                               endTime:(NSTimeInterval)endTime
                             leftCount:(NSInteger) leftCount;
- (void) setAiVoicePlayResultWithCode:(NSInteger)code
                                  msg:(NSString *_Nullable)msg;

- (void) addAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAllAiVoicePlayRequestListeners;

- (void) addAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAllAiSubscriptionInfoRequestListeners;
@end
