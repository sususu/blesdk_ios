/*!
 @header HwBluetoothError.h
 
 @author sujiang on 2018/4/13.
 @copyright  2021年 huawo. All rights reserved.
 */
#ifndef HwBluetoothError_h
#define HwBluetoothError_h

#import <Foundation/Foundation.h>

static NSString *const HwConnectionErrorDomain = @"HwConnectionErrorDomain";
static NSString *const HwSearchDevicesErrorDomain = @"HwSearchDevicesErrorDomain";
static NSString *const HwDisconnectDeviceErrorDomain = @"HwDisconnectDeviceErrorDomain";
static NSString *const HwDataErrorDomain = @"HwDataErrorDomain";
static NSString *const HwRequestErrorDomain = @"HwRequestErrorDomain";
static NSString *const HwDeviceErrorDomain = @"HwDeviceErrorDomain";


#pragma mark - CODE

/*!
 蓝牙SDK错误码
 
 - HwBCCodeBLEUnavailable: 蓝牙不可用
 - HwBCCodeBLEDisconnected: 连接断开
 - HwBCCodeBLEConnecting: 正在连接
 - HwBCCodeBLEException: 蓝牙异常，手机系统bug，导致无法扫描出外设服务和特征
 - HwBCCodeRequestTimeout: 蓝牙任务超时
 - HwBCCodeRequestFailed: 蓝牙任务请求失败
 - HwBCCodeConnectTimeout: 连接超时
 - HwBCCodeSearchTimeout: 搜索超时
 - HwBCCodeDisconnectTimeout: 断连超时
 - HwBCCodeInvalidDevice: 连接不存在的设备
 - HwBCCodeConnectRepeat: 重复连接
 - HwBCCodeConnectOverrided: 连接覆盖
 - HwBCCodeDataFormatError: 设备回传数据解析错误
 - HwBCCodeParamsError: 请求参数错误
 - HwBCCodeTaskCancelError: 任务被取消
 - HwBCCodeBindCancelByUserError: 用户取消绑定
 - HwBCCodeBindDeviceBindedError: 设备已被绑定
 - HwBCCodeBindDeviceResetError: 设备重置失败
 - HwBCCodeBindDeviceSameUID = 63,
 - HwBCCodePowerLowError: 设备电量过低错误
 - HwBCCodeDeviceUnsuport: 设备不支持
 - HwBCCodeOtaError: ota出错
 - HwBCCodeRequestOverrided: 请求被覆盖
 - HwBCCodeEncryptedMD5Error: MD5 加密失败
 */
typedef NS_ENUM(NSInteger, HwBCCode)
{
    /**
     BLE is not available
     */
    HwBCCodeBLEUnavailable = 9,      // 设备不可用，蓝牙未打开
    /**
     BLE is disconnected
     */
    HwBCCodeBLEDisconnected = 13,
    /**
     There is already a connection task working
     */
    HwBCCodeBLEConnecting = 12,   // 正在连接
    /**
     Something of iPhone's goes wrong, which causes BLE exception, device can not be re connected
     In this case, Users can only recover by turning on or off Bluetooth or restarting their phone
     */
    HwBCCodeBLEException = 11,      // 蓝牙异常，手机系统bug，导致无法扫描出外设服务和特征
    /**
     BLE task timeout
     */
    HwBCCodeRequestTimeout = 14,
    /**
     BLE task failed with data error
     */
    HwBCCodeRequestFailed = 15,
    /**
     BLE connect timeout
     */
    HwBCCodeConnectTimeout = 20,
    /**
     BLE scanning device timeout
     */
    HwBCCodeSearchTimeout = 21,
    /**
     Disconnect device timeout
     */
    HwBCCodeDisconnectTimeout = 22,
    /**
     Unable to identify device
     */
    HwBCCodeInvalidDevice = 27,
    /**
     Simultaneously initiated two connections to the same device
     */
    HwBCCodeConnectRepeat = 28,
    /**
     The connection has been overwritten by other connection tasks
     */
    HwBCCodeConnectOverrided = 29,
    /**
     Data parsing error
     */
    HwBCCodeDataFormatError = 30,
    /**
     parameter error
     */
    HwBCCodeParamsError = 31,
    /**
     BLE task is canceled
     */
    HwBCCodeTaskCancelError = 32,
    /**
     Binding device is canceled
     */
    HwBCCodeBindCancelByUserError = 60,
    /**
     Binding device failed
     */
    HwBCCodeBindDeviceBindedError = 61,
    /**
     Binding device reset failed
     */
    HwBCCodeBindDeviceResetError = 62,
    /**
     Binding device is the same as the currently bound devices
     */
    HwBCCodeBindDeviceSameUID = 63,
    /**
     device is exercising and starting a new workout
     */
    HwBCCodeWorkoutAlreadyStarted = 64,
    /**
     Device is charging, can not start workout
     */
    HwBCCodeDeviceIsCharging = 65,
    /**
     Device is in saving battery mode, can not start workout
     */
    HwBCCodeDeviceSavingMode = 66,
    /**
     Device is in breath-training mode [呼吸训练模式中]
     */
    HwBCCodeInBreathTrain = 86,
    /**
     Device low power, can not start workout
     */
    HwBCCodePowerLowError = 80,
    /**
     ota failed
     */
    HwBCCodeOtaError = 90,
    /**
     Same BLE request, the older one will be overrided
     */
    HwBCCodeRequestOverrided = 100,
    /**
     BLE task failed
     */
    HwBCCodeDeviceUnsuport = 256,
    /**
     Do not care about this code
     */
    HwBCCodeEncryptedMD5Error = 823
};

#endif /* HwBluetoothCMDDefine_h */
