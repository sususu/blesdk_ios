/*!
 @header HwBluetoothCenter+Device.h
 
 @author sujiang on 2018/4/21.
 @copyright  2021年 huawo. All rights reserved.
 */
#import "HwBluetoothCenter.h"
#import "HwDeviceDefines.h"
#import "HwTimeFaceStyleModel.h"
#import "HwVibrationModel.h"
#import "HwDontDisturbModel.h"
#import "HwTimeZone.h"
#import "HwWeatherInfo.h"
#import "HwLocalizeTimeZone.h"
#import "HwMenstrual.h"
#import "HwContact.h"
#import "HwBluetoothDeviceRequestManager.h"
#import "HwPhysiologicalPeriodSetting.h"
#import "HwSedentaryReminderForLS16.h"
#import "HwQrCard.h"
#import "HwDeviceBullet.h"
#import "HwAiAgent.h"

#pragma mark - define

#pragma mark - class
/*!
 @brief 设备相关API接口 API of the device
 */
@interface HwBluetoothCenter (Device)

#pragma mark - 手表基本信息 basic info about watch

/*! @brief
 Get features that watch supported
 */
- (HwBluetoothTask *_Nullable) getDeviceFeaturesWithCallback:(HwDataCallback _Nonnull)callback;

#pragma mark - 猎声获取版本信息
/*! @brief
 Get for version information
 */
- (HwBluetoothTask *_Nullable) getVersionForLSWithCallback:(HwDataCallback _Nonnull)callback;

/*! @brief
 获取SN号
 Querying the SN
 */
- (HwBluetoothTask *_Nonnull) getDeviceSNWithCallback:(HwStringCallback _Nonnull)callback;

/*! @brief
 获取设备是否支持相册
 Get Device album support
 */
- (HwBluetoothTask *_Nullable) getDeviceAlbumSupportWithCallback:(HwBoolCallback _Nonnull)callback;

/*! @brief
 获取GPS固件版本号和AGPS数据的有效时间段
 Get the GPS firmware version number and the valid period of AGPS data
 */
- (HwBluetoothTask *_Nullable) getDeviceGpsStatusWithCallback:(HwGpsStatusCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) setDeviceGpsInfoWithClipType:(NSString *_Nonnull)clipType secretKey:(NSString *_Nonnull)secretKey callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setCurrentGpsLocationWithLatitude:(double)latitude
                                                       longitude:(double)longitude
                                                       timestamp:(NSTimeInterval)timestamp
                                                        callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setCurrentGpsOrNetLocationWithLatitude:(double)latitude
                                                            longitude:(double)longitude
                                                            timestamp:(NSTimeInterval)timestamp
                                                             callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备的ID get ID of the watch
 
 @param callback 字符串回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getDeviceIdWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
获取设备的Mac地址 get Mac address of the watch

@param callback 字符串回调
@return task
*/
- (HwBluetoothTask *_Nullable) getDeviceMacAddressWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 获取固件版本号 get firmware version no.
 
 @param callback string 回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getFirmwareVersionWithCallback:(HwStringCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getFirmwareVersionForTAWithCallback:(HwStringCallback _Nullable)callback;

/*! @brief
 获取设备信息 Get device info
 
 @param type 信息类型 info type
 @param callback 回调 callback
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getDeviceInfoForType:(NSInteger)type
                                           callback:(HwStringCallback _Nullable)callback;

/*! @brief
 获取设备类型 get device type
 
 @param callback 字符串回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getDeviceTypeWithCallback:(HwStringCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getDeviceInfoWithCallback:(HwDeviceInfoCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getDeviceWatchfaceVersionWithCallback:(HwBCIntegerCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getDeviceProtocolVersionWithCallback:(HwBCIntegerCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDeviceMapAuthCode:(NSString *_Nonnull)authCode
                                               uuid:(NSString *_Nonnull)uuid
                                           callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDeviceMapTheme:(HwMapTheme)theme
                                        callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDeviceMapCenterWithLongitude:(double)longitude
                                                      latitude:(double)latitude
                                                      callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDeviceMapRangeWithLongitude:(double)longitude
                                                     latitude:(double)latitude
                                                  maxLongitude:(double)maxLongitude
                                                  minLongitude:(double)minLongitude
                                                   maxLatitude:(double)maxLatitude
                                                   minLatitude:(double)minLatitude
                                                     callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDeviceBullets:(NSArray<HwDeviceBullet *> *_Nullable)bullets
                                             on:(BOOL)on
                                       callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 开始绑定设备 starting to pairing with watch
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) startBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) startBindDeviceNoConfirmWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 开始有确认的绑定流程 starting to pairing with watch
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) startConfirmBindWithUID:(NSString *_Nonnull)uid
                                           isNewDevice:(BOOL)isNewDevice
                                              callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getDeviceUIDWithCallback:(HwStringCallback _Nonnull)callback;


/*! @brief
 开始以二维码方式 绑定设备 starting to pairing with watch using QRCODE
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) startQRBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;


/*! @brief
 结束绑定设备 End pairing
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) endBindDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备的绑定状态 get bind state of device

 @param callback bindState
 @return task
 */
- (HwBluetoothTask *_Nullable) getBindStateWithCallback:(void(^_Nonnull)(HwBindState bindState, NSError * _Nullable error))callback;




/*! @brief
 设置设备时间 Set time format of watch
 
 @param is24H 是否24小时制 if time format is 24H
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setDeviceTimeWith24H:(BOOL)is24H
                                           callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置时间到设备上 [set time to device]
 
 @param time 时间
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setDeviceTime:(NSDate *_Nonnull)time
                                    callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置时间到设备上 [set time to device]
 
 注：思澈不同步12/24小时制
 
 @param time 时间
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setSifliDeviceTime:(NSDate *)time
                                         callback:(HwBoolCallback)callback;

- (HwBluetoothTask *_Nullable) setDeviceTime:(NSDate *_Nonnull)time
                                       is24H:(BOOL)is24H
                                    callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备上的时间格式
 
 @param callback 是否是24小时制回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getDeviceTimeWith24HCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备上的时间 [get time from device]
 
 @param callback 时间回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getDeviceTimeWithCallback:(HwDateCallback _Nullable)callback;

/*! @brief
 关闭设备 [shutdown watch]
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) shutdownDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 重启设备 [reset watch]
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) restartDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 强行让设备退出OTA [reset watch]
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) forceOutOTADeviceWithCallback:(HwBoolCallback _Nullable)callback;


/**
 解绑指令 [unbind watch]，目的是为了让设备端断连BT(经典蓝牙)
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask * _Nullable) unbindDeviceWithCallback:(HwBoolCallback _Nullable)callback;
/**
 查询BT开关状态
 */
- (HwBluetoothTask * _Nullable)queryBtSwitchStatusWithCallback:(HwBoolCallback _Nullable)callback;
/**
 设置BT开关
 */
- (HwBluetoothTask * _Nullable)setBtSwitchStatus:(BOOL)status callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *)setBtSwitchStatus:(BOOL)status autoConnect:(BOOL)autoConnect callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) updateLocalizeTimeZones:(NSArray <HwLocalizeTimeZone *> *_Nonnull)localizeTimeZones  callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setLocalizeTimeZone:(HwLocalizeTimeZone *_Nonnull)timezone callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) removeLocalizeTimezoneById:(NSInteger)Id
                                        callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) delAllWorldClockCitiesWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) delWorldClockCities:(NSArray *_Nonnull)idList
                                          callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getLocalizeTimeZonesWithCallback:(void(^_Nullable)(NSArray<HwLocalizeTimeZone *> *timeZones, NSError * _Nullable error))callback;

/**
 Set world clock city and country
 */
- (HwBluetoothTask *_Nullable) setWorldClockCityAndCountry:(HwLocalizeTimeZone *_Nonnull)timezone callback:(HwBoolCallback _Nullable)callback;
/**
 Edit world clock city and country
 */
- (HwBluetoothTask *_Nullable) editWorldClockCitiesAndCountries:(NSArray <HwLocalizeTimeZone *> *_Nonnull)localizeTimeZones  callback:(HwBoolCallback _Nullable)callback;
/**
 Remove world clock city and country
 */
- (HwBluetoothTask *_Nullable) removeWorldClockCitiesAndCountriesById:(NSInteger)Id
                                        callback:(HwBoolCallback _Nullable)callback;
/**
 Get world clock city and country
 */
- (HwBluetoothTask *_Nullable) getWorldClockCitiesAndCountriesCallback:(void(^_Nullable)(NSArray<HwLocalizeTimeZone *> *timeZones, NSError * _Nullable error))callback;

- (HwBluetoothTask *_Nullable) findDeviceWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 手表设置 [watch setting]

/*! @brief
 重置设备 [reset watch]
 
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) resetDeviceWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 亮度 [brightness]

/*! @brief
 设置手表的亮度 [set brightness of device]
 
 @param value 0 ～ 100
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setBrightnessValue:(NSInteger)value callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 获取手表的亮度 [get brightness of device]
 
 @param callback integer回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getBrightnessValueWithCallback:(HwBCIntegerCallback _Nullable )callback;

#pragma mark - 语言 [language]

/*! @brief
 设置手表的语言类型 [set language of device]
 
 @param language 语言类型
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setLanguage:(HwLanguage)language callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 获取语言类型 [get language type]
 
 @param callback 语言类型回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getLanguageWithCallback:(HwLanguageCallback _Nullable )callback;

/*! @brief
 获取设备支持的语言类型数组 [get Device Supported languages type]
 
 @param callback 语言类型回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getDeviceSupportedLanguages:(HwSupportedLanguagesCallback _Nullable )callback;

#pragma mark - watch time face style

typedef void (^HwWatchfaceIdChangedCallback)(NSInteger Id);
typedef void (^HwWatchfaceNameChangedCallback)(NSString *_Nullable name);
typedef void (^HwCurrentWeatherUnitChangedCallback)(HwWeatherUnit unit);
typedef void (^HwUnitUpdateChangedCallback)(HwUnitStyle unit);
typedef void (^HwGpsShouldUpdateCallback)(long validStartTime, long validEndTime);

- (HwBluetoothTask *_Nullable) setWatchfaceWithId:(NSInteger)Id
                                         callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getWatchfaceIdWithCallback:(HwBCIntegerCallback _Nonnull)callback;

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

- (HwBluetoothTask *_Nullable) setTimeFormat:(HwTimeFormat)timeFormat
                                    callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getTimeFormatWithCallback:(void(^_Nonnull)(HwTimeFormat timeFormat, NSError *_Nullable error))callback;

- (HwBluetoothTask *_Nullable) setSosName:(NSString *_Nullable)name
                              phoneNumber:(NSString *_Nullable)phoneNumber
                                 callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置手表时间界面样式
 
 @param model 样式模型
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setTimeFaceStyleWithModel:(HwTimeFaceStyleModel *_Nonnull)model
                                               callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 设置时间界面样式，如果设备不支持那个样式，传入-1
 
 @param dateStyle 日期样式
 @param timeStyle 时间样式
 @param batteryStyle 电池样式
 @param lunarStyle 农历样式
 @param screenStyle 屏幕样式
 @param backgroundStyle 背景样式
 @param heartRateStyle 心率样式
 @param usernameStyle 用户名样式
 @param callback 成功与否的回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setTimeFaceStyleWithDateStyle:(HwDateStyle)dateStyle
                                                   timeStyle:(HwTimeStyle)timeStyle
                                                batteryStyle:(HwBatteryStyle)batteryStyle
                                                  lunarStyle:(HwLunarStyle)lunarStyle
                                                 screenStyle:(HwScreenStyle)screenStyle
                                             backgroundStyle:(NSInteger)backgroundStyle
                                              heartRateStyle:(HwHeartRateStyle)heartRateStyle
                                               usernameStyle:(HwUsernameStyle)usernameStyle
                                                    callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取时间界面样式
 
 @param callback 样式回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) getTimeFaceStyleWithCallback:(HwTimeFaceStyleCallback _Nullable)callback;

#pragma mark - 自定义表盘 [custom watch face]

/*! @brief
 获取设备中，所有自定义表盘的crc值 [get all the crc value of customerized watch faces in the watch]
 
 @param callback NSArray<NSData *> * callback
 @return task
 */
- (HwBluetoothTask *_Nullable) getAllCustomWatchFaceCrcsWithCallback:(HwBCArrayCallback _Nullable )callback;

/*! @brief
 获取设备中，所有自定义表盘的Id [get all the ID of the customerized watch faces in the watch]
 
 @param callback NSArray<NSNumber *> * callback
 @return task
 */
- (HwBluetoothTask *_Nullable) getAllCustomWatchFaceIDsWithCallback:(HwBCArrayCallback _Nullable )callback;



/*! @brief
 获取自定义表盘在设备中的信息 [get customerized watch face information from device,such as index and address]
 索引、地址等
 
 @param crcData crc值（2位）
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) getCustomWatchFaceInfoByCrcData:(NSData *_Nonnull)crcData
                                                     callback:(HwCustomWatchFaceInfoCallback _Nullable )callback;

/*! @brief
 get a store address for picture on watch
 this method will callback an index and address allocated by watch for the picture on watch's disk
 
 @param ID picture's ID（2 bit）
 @param callback if index == 0x00, means watch had already stored the picture of this ID. don't need to OTA again
 @return bluetooth task
 */
- (HwBluetoothTask *_Nullable) getCustomWatchFaceInfoByID:(NSUInteger)ID
                                                callback:(HwCustomWatchFaceInfoCallback _Nullable )callback;

+ (NSData *_Nonnull) createOnlineWatchFaceDataAddress:(NSData *_Nonnull)address
                                      picData:(NSData *_Nonnull)picData;

+ (NSData *_Nonnull) createWatchFaceOtaDataWithIndex:(NSInteger)index
                                     address:(NSData *_Nonnull)address
                                     picData:(NSData *_Nonnull)picData
                                     crcData:(NSData *_Nonnull)crcData;

/*! @brief
 根据ID，删除设备中自定义的表盘信息 [delete watch face according to ID]
 
 @param ID ID
 @param callback 回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) deleteCustomWatchFacePicWithID:(NSUInteger)ID
                                                     callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 根据crc值，删除设备中自定义的表盘信息 [delete watch face according to crc value]
 crc 2 bit length
 
 @param crcData crc值
 @param callback 回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) deleteCustomWatchFacePicWithCrc:(NSData *_Nonnull)crcData
                                                      callback:(HwBoolCallback _Nullable)callback;
/*! @brief
 根据crc值，删除设备中自定义的表盘信息 [delete watch face according to crc value]
 crc 4 bit length
 
 @param crcData crc值
 @param callback 回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) deleteCustomWatchFacePicWithCrc4:(NSData *_Nonnull)crcData
                                                       callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 删除所有自定义表盘 [delete all the watch faces ]
 
 @param callback 成功与否回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) deleteAllCustomWatchFacePicWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 震动 [vibration]


/*! @brief
 获取设备上的震动类型 [get vibration type from device]
 
 @param callback 回到
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getVibrationWithCallback:(HwVibrationArrayCallback _Nullable)callback;

/*! @brief
 设置震动类型 [set vibration type]
 
 @param vibration 震动数据模型
 @param callback 回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) setVibration:(HwVibrationModel *_Nonnull)vibration
                                   callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置震动类型 [set vibration type]
 
 @param type 类型
 @param state 状态
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setVibrationType:(HwVibrationType)type
                                          state:(HwVibrationState)state
                                       callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取震动强度 [get vibration intensity]
 
 @param callback 震动强度回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getVibrationStrengthWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置震动强度 [set vibration intensity]
 
 @param strength 强度
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setVibrationStrength:(NSInteger)strength
                                           callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置震动类型的震动强度
 
 @param type 类型
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setVibrationStrengthWithType:(HwVibrationStrengthType)type
                                                   callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) startSpO2MonitoringWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) stopSpO2MonitoringWithCallback:(HwBoolCallback _Nullable)callback;

//设备断开BLE连接
- (HwBluetoothTask *_Nullable) setDeviceBleDisconnectionWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - weather

- (HwBluetoothTask *_Nullable) setWeatherInfoWithCity:(NSString *_Nonnull)city
                                          weatherInfo:(HwWeatherInfo *_Nonnull)weatherInfo
                                             forecast:(NSArray<HwWeatherInfo *> *_Nullable)forecasts
                                             callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getWeatherUnitWithCallback:(void(^_Nullable)(HwWeatherUnit unit, NSError * _Nullable error))callback;

- (HwBluetoothTask *_Nullable) setWeatherUnit:(HwWeatherUnit)unit
                                     callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取系统的语言类型（非蓝牙指令）[get system language]
 
 @return 语言类型
 */
- (HwLanguage) getSystemLanguageType;

#pragma mark - 查询设备状态
- (HwBluetoothTask *_Nullable)getDeviceUpgradeStatusWithCallback:(void(^_Nullable)(HwDeviceUpgradeState state, NSError * _Nullable error))callback;
#pragma mark - 手机匹配弹框操作
//查询匹配的状态
- (HwBluetoothTask *_Nullable)getPairStateWithCallback:(HwBoolCallback _Nullable)callback;
//设置
- (HwBluetoothTask *_Nullable)requestDeviceToPairWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 获取BT连接状态
- (HwBluetoothTask *_Nullable)getBtConnectionStateWithCallback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setAppState:(HwAppState)state
                                  callback:(HwBoolCallback _Nullable)callback;

#pragma mark - power

/*! @brief
 获取设备电量 [get device battery volumn]
 
 @param callback 回调0-100
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getBatteryWithCallback:(HwBCIntegerCallback _Nullable)callback;
#pragma mark - power state

/*! @brief
 获取设备电量的状态
 
 @param callback 回调 0 1 2 3
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getBatteryStateWithCallback:(HwBatteryStateCallback _Nonnull)callback;

#pragma mark - volumn

/*! @brief
 获取设备的音量 [get device voice volumn]
 
 @param callback 音量回调0-100
 @return 任务
 */
- (HwBluetoothTask *_Nullable) getVolumnWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置设备的音量 [set device voice volumn]
 
 @param volumn 音量0-100
 @param callback 成功与否的回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setVolumn:(NSInteger)volumn callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 亮屏时间 [screen timeout durartion]
// 获取设备亮屏时间（1-20秒）
// zetime不支持
- (HwBluetoothTask *_Nullable) getScreenOnTimeWithCallback:(HwBCIntegerCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setScreenOnTime:(NSInteger)second
                                      callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备灭屏时间，单位为 秒 [get screen timeout durartion]
 
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) getScreenOffTimeWithCallback:(HwBCIntegerCallback _Nullable)callback;

/**
 设置设备灭屏时间 [set screen timeout durartion]
 
 @param second 秒
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) setScreenOffTime:(NSInteger)second
                                       callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 设置贪睡时间间隔 [set snooze durartion]
/*! @brief
 设置贪睡时间（分钟）[set snooze durartion(minutes)]
 
 @param value 多少分钟 [how many minutes]
 @param callback 成功与否 [success or not]
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) setSnoozeValue:(NSInteger)value
                            callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取设备设置的贪睡时间（分钟）[get snooze durartion(minutes)]
 
 @param callback 整型回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) getSnoozeValueWithCallback:(HwBCIntegerCallback _Nullable)callback;


#pragma mark - 设置事件时间提醒间隔 [set Even Remind interval]
/*! @brief
获取设备事件时间提醒间隔（秒）[get Even Remind interval(second)]
@prram evenType HwEvenRemindType
@param callback 整型回调
@return 任务 task
*/
- (HwBluetoothTask *_Nullable) getEvenRemindIntervalByType:(HwEvenRemindType)evenType
                                     withCallback:(HwBCIntegerCallback _Nullable)callback;
/*! @brief
设置设备事件时间提醒间隔（秒）[set Even Remind interval(second)]
@prram evenType HwEvenRemindType
@prram span 间隔时间（s）
@param callback 整型回调
@return 任务 task
*/
- (HwBluetoothTask *_Nullable) setEvenRemindIntervalByType:(HwEvenRemindType)evenType
                                                  WithSpan:(NSInteger)span
                                                  callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 勿打扰模式
- (HwBluetoothTask *_Nullable) getDontDisturbWithCallback:(HwDontDisturbCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDontDisturbModel:(HwDontDisturbModel *_Nonnull)model
                                          callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDontDisturbState:(BOOL)state
                                         startHour:(NSInteger)startHour
                                          startMin:(NSInteger)startMin
                                           endHour:(NSInteger)endHour
                                            endMin:(NSInteger)endMin
                                          callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 寻找设备

/*! @brief
 开始寻找设备 [start searching device]
 
 @param callback 成功与否回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) searchDeviceWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 停止寻找设备 [stop searching device]
 
 @param callback 成功与否回调
 @return 任务 task
 */
- (HwBluetoothTask *_Nullable) stopSearchingDeviceWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - 设置生理周期(0x33)
/// 设置生理周期
/// @param periods 想要传递的周期
/// @param callback 回调
- (HwBluetoothTask *_Nullable)setMenstrualPeriods:(NSArray<HwMenstrual *> *_Nonnull)periods
                                         callback:(HwBoolCallback _Nullable)callback;
#pragma mark - 设置生理期(0x32)
- (HwBluetoothTask *_Nullable)setNewMenstrualPeriods:(NSArray<HwMenstrual *> *_Nonnull)periods
                                            callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setPhysiologicalPeriodSetting:(HwPhysiologicalPeriodSetting *_Nonnull)setting callback:(HwBoolCallback _Nullable)callback;

#pragma mark - 设置生理期提醒(思澈平台)
/// 设置生理周期
/// @param periods 想要传递的提醒
/// @param callback 回调
- (HwBluetoothTask *_Nullable)setPhysiologicalPeriodSettingV2:(HwPhysiologicalPeriodSetting *_Nonnull)setting
                                      callback:(HwBoolCallback _Nullable)callback;


#pragma mark - 设备屏锁密码
- (HwBluetoothTask *_Nullable) setDevicePasscode:(NSString *_Nonnull)passcode
                                        callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setDevicePasscode:(NSString *_Nonnull)passcode
                                              on:(BOOL)on
                                        callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getDeviceSwitchPasscodeWithCallback:(HwDevicePasscodeCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) clearDevicePasscodeWithCallback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getDevicePasscodeWithCallback:(HwStringCallback _Nullable)callback;

#pragma mark - 设备数据
- (HwBluetoothTask *_Nullable) clearDeviceDataWithCallback:(HwBoolCallback _Nullable)callback;


- (HwBluetoothTask *_Nullable) setContactWithContacts:(NSArray<HwContact *> *_Nonnull)contacts
                                    callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setContactV2WithContacts:(NSArray<HwContact *> *_Nonnull)contacts
                                    callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getContactsWithCallback:(void(^_Nonnull)(NSArray<HwContact *> *_Nullable contacts, NSError *_Nullable error))callback;

#pragma mark - SedentaryReminder
typedef void (^HwSedentaryReminderForLS16Callback)(HwSedentaryReminderForLS16 *_Nullable reminder, NSError *_Nullable error);

- (HwBluetoothTask *_Nullable) setSedentaryReminderForLS16:(HwSedentaryReminderForLS16 *_Nonnull)sr callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getSedentaryReminderForLS16WithCallback:(HwSedentaryReminderForLS16Callback _Nonnull)callback;


- (HwBluetoothTask *_Nullable) heartbeat:(HwBoolCallback _Nonnull)callback;

#pragma mark - Qrcode Card
typedef void (^HwQrcodeCardsCallback)(NSArray<HwQrCard *> *_Nullable cards, NSError *_Nullable error);
- (HwBluetoothTask *_Nullable) addQrcodeCard:(HwQrCard *_Nonnull)card
                                    callback:(HwBoolCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) editQrcodeCard:(HwQrCard *_Nonnull)card
                                     callback:(HwBoolCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getQrcodeCardsWithCallback:(HwQrcodeCardsCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getQrcodeCardContentById:(NSInteger)Id
                                               callback:(HwStringCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delQrcodeCardById:(NSInteger)Id
                                        callback:(HwBoolCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delAllQrcodeCardsWithCallback:(HwBoolCallback _Nonnull)callback;

- (HwBluetoothTask *_Nullable) setElectronicCardSorts:(NSArray *_Nonnull)cardSorts callback:(HwBoolCallback _Nonnull)callback;

#pragma mark - 相册
- (HwBluetoothTask *_Nullable) getAlbumFilesCountWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getAlbumFilesIdListWithCallback:(HwBCArrayCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delAlbumFiles:(NSArray *_Nullable)idList
                                    callback:(HwBoolCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delAllAlbumFilesWithCallback:(HwBoolCallback _Nonnull)callback;


- (HwBluetoothTask *_Nullable) getMusicAvailableStorageWithCallback:(HwAvailableStorageCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getOfflineMapAvailableStorageWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getCoustomInterfaceAvailableStorageWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (void) addDeviceMusicStorageChangedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeDeviceMusicStorageChangedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeAllDeviceMusicStorageChangedListeners;
#pragma mark - 高原关爱
- (HwBluetoothTask *_Nullable) setPlateauCareWithInterval:(NSInteger)interval
                                                 callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getPlateauCareWithCallback:(HwBCIntegerCallback _Nonnull)callback;

#pragma mark - AI智能体
- (HwBluetoothTask *_Nullable) setAiAgentsWithAiAgents:(NSArray<HwAiAgent *> * _Nonnull)aiAgents
                                              callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getAiAgentsWithCallback:(void(^_Nonnull)(NSArray<HwAiAgent *> *_Nullable aiAgents, NSError *_Nullable error))callback;

#pragma mark - 蓝牙对讲机
/*! @brief
 设置蓝牙对讲机名称
 
 @param name 名称
 @param callback bool回调
 @return task
 */
- (HwBluetoothTask *_Nullable) setWalkieTalkieName:(NSString *_Nonnull)name
                                          callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取蓝牙对讲机名称
 
 @param callback string回调
 @return task
 */
- (HwBluetoothTask *_Nullable) getWalkieTalkieNameWithCallback:(HwStringCallback _Nonnull)callback;

@end


