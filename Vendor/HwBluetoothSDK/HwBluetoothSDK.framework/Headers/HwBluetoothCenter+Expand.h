//
//  HwBluetoothCenter+Expand.h
//  HwBluetooth
//
//  Created by Su on 2018/4/5.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"
#import "HwBluetoothDeviceRequestManager.h"

@class CLLocation;

@interface HwBluetoothCenter (Expand)

/**
 增加设备请求拍照事件监听 [add listener of device requesting for taking photo]
 
 @param callback 回调
 */
- (void) addCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeAllCameraEventCallbacks;

- (void) addCameraImageEventCallback:(HwCameraImageEventCallback _Nonnull)callback;
- (void) removeCameraImageEventCallback:(HwCameraImageEventCallback _Nonnull)callback;
- (void) removeAllCameraImageEventCallbacks;

- (void) addCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeAllCameraDelayEventCallbacks;

/*! @brief
 this command will make device enter taking photo screen

 @param callback success or not callback
 @return ble task
 */
- (HwBluetoothTask *_Nullable) deviceEnterCameraControlCallback:(HwBoolCallback _Nonnull)callback;

/*! @brief
 this command will make device exit taking photo screen
 
 @param callback success or not callback
 @return ble task
 */
- (HwBluetoothTask *_Nullable) deviceExitCameraControlCallback:(HwBoolCallback _Nonnull)callback;

/**
 增加设备寻找手机的请求事件监听 [add listener of finding my phone request]
 
 @param callback 回调
 */
- (void) addSearchPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;

/**
 移除设备寻找手机 [remove listener of finding my phone]
 */
- (void) removeSearchPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;
- (void) removeAllSearchPhoneCallbacks;
- (HwBluetoothTask *_Nullable) responseSearchPhone;

/**
 发送命令告知手表，停止搜索手机。

 @param callback 回调
 */
- (HwBluetoothTask *_Nullable) stopSearchingPhoneWithCallback:(HwBoolCallback _Nonnull)callback;


/**
 增加设备事件通知监听 [add listener of device notify event]
 
 @param callback 回调
 */
- (void) addDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
/**
 移除监听 remove listener of 'addDeviceEventNotifyListenerWithCallback'
 */
- (void) removeDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
- (void) removeAllDeviceEventCallbacks;

- (void) addDeviceControlCallback:(HwDeviceControlCallback _Nonnull)callback;
- (void) removeDeviceControlCallback:(HwDeviceControlCallback _Nonnull)callback;
- (void) removeAllDeviceControlCallbacks;


- (void) addDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeAllDevicePairStateCallbacks;

- (void) addWorkoutRealtimeDataUpdatedCallback:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
- (void) removeWorkoutRealtimeDataUpdatedCallback:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
- (void) removeAllWorkoutRealtimeDataUpdatedCallbacks;

- (void) addTimedMeasureCallback:(HwTimedMeasureCallback _Nonnull)callback;
- (void) removeTimedMeasureCallback:(HwTimedMeasureCallback _Nonnull)callback;

- (void) addHeartrateValueChangedCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeHeartrateValueChangedCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllHeartrateValueChangedCallbacks;

- (void) addStressValueChangedCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeStressValueChangedCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllStressValueChangedCallbacks;

- (void) addSpo2ValueChangedCallback:(HwSpo2ValueChangedCallback _Nonnull)callback;
- (void) removeSpo2ValueChangedCallback:(HwSpo2ValueChangedCallback _Nonnull)callback;
- (void) removeAllSpo2ValueChangedCallbacks;


@end
