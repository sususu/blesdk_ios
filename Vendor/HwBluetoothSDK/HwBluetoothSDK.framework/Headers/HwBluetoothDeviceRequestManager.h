//
//  HwBluetoothDeviceRequestManager.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/7.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HwGoalValue.h"
#import "HwCameraImage.h"
#import "HwDeviceDefines.h"
#import "HwMonitorDataType.h"
#import "HwWorkout.h"

@class HwWorkoutRealtimeData;
#pragma mark - Camera
typedef NS_ENUM(NSInteger, HwCameraEvent)
{
    HwCameraEventShot = 0x00,
    HwCameraEventExit = 0x01,
    HwCameraEventEnter = 0x02,
    HwCameraEventDelayShot = 0x03
};
typedef void (^HwCameraEventCallback)(HwCameraEvent event);
typedef void (^HwCameraDelayEventCallback)(HwCameraEvent event, NSInteger delay, NSInteger photoNum);
typedef void (^HwCameraImageEventCallback)(HwCameraEvent event, HwCameraImage *cameraImage, NSInteger delay, NSInteger photoNum);

#pragma mark - Search iPhone
typedef NS_ENUM(NSInteger, HwSearchPhoneState)
{
    HwSearchPhoneStateSearching = 0x00,
    HwSearchPhoneStateStop = 0x01
};

typedef void (^HwSearchPhoneCallback)(HwSearchPhoneState state);


/**
 设备通知手表事件 (Device notify APP event)

 - HwDeviceEventCalibrationHourPointer: 设备正在进行时针校准 device is collating hour hand
 - HwDeviceEventCalibrationMinutePointer: 设备正在进行分针校准 device is collating minute hand
 - HwDeviceEventExitCalibration: 设备退出了较时   device quit calibration
 - HwDeviceEventUploadData: 设备请求APP上传数据到 strava device ask APP to upload data to Strava
 */
typedef NS_ENUM(NSInteger, HwDeviceEvent)
{
    HwDeviceEventCalibrationHourPointer = 0x03,
    HwDeviceEventCalibrationMinutePointer = 0x04,
    HwDeviceEventExitCalibration = 0x05,
    HwDeviceEventUploadData = 0x06,
    HwDeviceEventSyncWeather = 0x07,
    HwDeviceEventSyncAgps = 0x08,
    HwDeviceEventHeartRateMonitorFailed = 0x09,
    HwDeviceEventOtaBeat = 0x0b,
    HwDeviceEventSyncLocation = 0x13,
    HwDeviceEventSyncPhoneCalendars = 0x14,
};

typedef NS_ENUM(NSInteger, HwAiType)
{
    HwAiTypeWatchface = 0x00,
    HwAiTypeQnI = 0x01,
    HwAiTypeTranslate = 0x02,
    HwAiTypeAgent = 0x03,
    HwAiTypeMeeting = 0x04,
    HwAiTypeHealthAnalysis = 0x05,
    HwAiTypeUnknown = 0xff
};

typedef void (^HwDeviceEventCallback)(HwDeviceEvent type);
typedef void (^HwDeviceControlCallback)(BOOL success);

// 设备配对状态通知回调
typedef void (^HwDevicePairStateCallback)(NSInteger pairState);
typedef void (^HwWorkoutRealtimeDataUpdatedCallback)(HwWorkoutRealtimeData *_Nonnull realtimeData);
typedef void (^HwWorkoutStateUpdatedCallback)(BOOL stopped);
typedef void (^HwWorkoutTypeRecognitionCallback)(NSInteger cate);

typedef NS_ENUM(NSInteger, HwReminderNotifyType) {
    HwReminderNotifyTypeLowBattery = 0x01,
    HwReminderNotifyTypeSedentary = 0x02,
    HwReminderNotifyTypeMenstrualFertile = 0x03,
    HwReminderNotifyTypeMenstrualPeriod = 0x04,
    HwReminderNotifyTypeDrinkWater = 0x05,
    HwReminderNotifyTypeWashHand = 0x06,
    HwReminderNotifyTypeCustomMeeting = 0x07,
    HwReminderNotifyTypeCustomSleep = 0x08,
    HwReminderNotifyTypeCustomSchedule = 0x09,
    HwReminderNotifyTypeCustomWorkout = 0x0A,
    HwReminderNotifyTypeCustomMedicine = 0x0B,
    HwReminderNotifyTypeCustomMeal = 0x0C,
    HwReminderNotifyTypeCustomBill = 0x0D,
    HwReminderNotifyTypeCustom = 0x0E,
    HwReminderNotifyTypeGoalStep = 0x0F,
    HwReminderNotifyTypeGoalDistance = 0x10,
    HwReminderNotifyTypeGoalCalorie = 0x11,
    HwReminderNotifyTypeGoalDuration = 0x12,
    HwReminderNotifyTypeDailyLowHeartRate = 0x13,
    HwReminderNotifyTypeDailyHighHeartRate = 0x14,
    HwReminderNotifyTypeWorkoutHighHeartRate = 0x15,
    HwReminderNotifyTypeWorkoutGoalStep = 0x16,
    HwReminderNotifyTypeWorkoutGoalCalorie = 0x17,
    HwReminderNotifyTypeWorkoutGoalDistance = 0x18,
    HwReminderNotifyTypeWorkoutGoalDuration = 0x19,
    HwReminderNotifyTypeAlarm = 0x1a,
    HwReminderNotifyTypeUnknown = 0xFF
};
typedef void (^HwReminderNotifyCallback)(HwReminderNotifyType type, NSData *_Nullable datas);

static inline HwReminderNotifyType HwReminderNotifyTypeFromValue(NSInteger value)
{
    switch (value) {
        case HwReminderNotifyTypeLowBattery:
        case HwReminderNotifyTypeSedentary:
        case HwReminderNotifyTypeMenstrualFertile:
        case HwReminderNotifyTypeMenstrualPeriod:
        case HwReminderNotifyTypeDrinkWater:
        case HwReminderNotifyTypeWashHand:
        case HwReminderNotifyTypeCustomMeeting:
        case HwReminderNotifyTypeCustomSleep:
        case HwReminderNotifyTypeCustomSchedule:
        case HwReminderNotifyTypeCustomWorkout:
        case HwReminderNotifyTypeCustomMedicine:
        case HwReminderNotifyTypeCustomMeal:
        case HwReminderNotifyTypeCustomBill:
        case HwReminderNotifyTypeCustom:
        case HwReminderNotifyTypeGoalStep:
        case HwReminderNotifyTypeGoalDistance:
        case HwReminderNotifyTypeGoalCalorie:
        case HwReminderNotifyTypeGoalDuration:
        case HwReminderNotifyTypeDailyLowHeartRate:
        case HwReminderNotifyTypeDailyHighHeartRate:
        case HwReminderNotifyTypeWorkoutHighHeartRate:
        case HwReminderNotifyTypeWorkoutGoalStep:
        case HwReminderNotifyTypeWorkoutGoalCalorie:
        case HwReminderNotifyTypeWorkoutGoalDistance:
        case HwReminderNotifyTypeWorkoutGoalDuration:
        case HwReminderNotifyTypeAlarm:
            return (HwReminderNotifyType)value;
        default:
            return HwReminderNotifyTypeUnknown;
    }
}
typedef void (^HwBatteryStateCallback)(NSInteger battery, BOOL charging, BOOL savingMode, NSError *_Nullable error);
typedef void (^HwBatteryStateChangedCallback)(NSInteger battery, BOOL charging, BOOL savingMode);
typedef void (^HwWatchfaceIdChangedCallback)(NSInteger Id);
typedef void (^HwWatchfaceNameChangedCallback)(NSString *_Nonnull name);
typedef void (^HwCurrentWeatherUnitChangedCallback)(HwWeatherUnit unit);
typedef void (^HwUnitUpdateChangedCallback)(HwUnitStyle unit);
typedef void (^HwGpsShouldUpdateCallback)(long validStartTime, long validEndTime);
typedef void (^HwIntValueChangedCallback)(NSInteger val);
typedef void (^HwFloatValueChangedCallback)(float val);
typedef void (^HwNotProperlyWornCallback)(void);
typedef void (^HwMonitorStateChangedCallback)(HwMonitorDataType type);
typedef void (^HwSpo2ValueChangedCallback)(NSInteger val,long time);
typedef void (^HwTimedMeasureCallback)(HwMonitorDataType type, double value, long time);
typedef void (^HwGoalUpdatedCallback)(HwGoalType type, NSInteger val);
typedef void (^HwGoalsUpdatedCallback)(NSArray<HwGoalValue *> *_Nonnull goalValues);
typedef void (^HwHealthDataUpdatedCallback)(NSInteger step, NSInteger distance, NSInteger calories, NSInteger duration, NSInteger activeCount);
typedef void (^HwSpO2StateUpdatedCallback)(BOOL monitoring);
typedef void (^HwRequestGpsLocationCallback)(BOOL requestGps);
typedef void (^HwAppStatusRequestCallback)(void);
typedef void (^HwStartRecordingCallback)(int type, int language, int outputLanguage);
typedef void (^HwEndRecordingCallback)(int type);
//typedef void (^HwGenerateAiWatchfaceRequestCallback)(void);
typedef void (^HwGenerateAiAnswerRequestCallback)(void);
typedef void (^HwGenerateAiTranslateRequestCallback)(void);
typedef void (^HwGenerateAiAgentResultRequestCallback)(void);
typedef void (^HwAiWatchfaceEnterOrExitCallback)(BOOL enter);
typedef void (^HwAiAnswerEnterOrExitCallback)(BOOL enter);
//typedef void (^HwGenerateAiWatchfacePreviewRequestCallback)(void);
typedef void (^HwGenerateAiWatchfacePreviewRequestCallback)(NSInteger type);//0 静态表盘  1 动态表盘
typedef void (^HwGenerateAiWatchfaceRequestCallback)(NSInteger type);
typedef void (^HwGenerateAiMeetingRequestCallback)(NSDate *_Nullable meetingTime, NSInteger contentType);

@class HwHealthData;
typedef void (^HwGenerateAiHealthAnalysisRequestCallback)(HwHealthData *_Nullable healthData);
typedef void (^HwAiSettingUpdateCallback)(HwAiType type, int param1, int param2, int param3);
typedef void (^HwAiEventCallback)(BOOL enter, HwAiType type, int param1, int param2, int param3);
typedef void (^HwAiAnswerHandlerCallback)(BOOL play);
typedef void (^HwAvailableStorageCallback)(NSInteger available, NSInteger total, NSError *_Nullable error);
typedef void (^HwAiVoicePlayRequestCallback)(NSInteger state, NSInteger language, NSInteger volumn, NSString *_Nullable crc);
typedef void (^HwAiSubscriptionInfoRequestCallback)(NSString *_Nullable mac);

/*!
 蓝牙任务管理类
 */
@interface HwBluetoothDeviceRequestManager : NSObject

+ (HwBluetoothDeviceRequestManager *_Nonnull)sharedInstance;

- (void) addCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeCameraEventCallback:(HwCameraEventCallback _Nonnull)callback;
- (void) removeAllCameraEventCallbacks;

- (void) addCameraImageEventCallback:(HwCameraImageEventCallback _Nonnull)callback;
- (void) removeCameraImageEventCallback:(HwCameraImageEventCallback _Nonnull)callback;
- (void) removeAllCameraImageEventCallbacks;

- (void) addCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeCameraDelayEventCallback:(HwCameraDelayEventCallback _Nonnull)callback;
- (void) removeAllCameraDelayEventCallbacks;

- (void) addSearchPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;
- (void) removeSearchPhoneCallback:(HwSearchPhoneCallback _Nonnull)callback;
- (void) removeAllSearchPhoneCallbacks;

- (void) addDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
- (void) removeDeviceEventCallback:(HwDeviceEventCallback _Nonnull)callback;
- (void) removeAllDeviceEventCallbacks;

- (void) addDeviceControlCallback:(HwDeviceControlCallback _Nonnull)callback;
- (void) removeDeviceControlCallback:(HwDeviceControlCallback _Nonnull)callback;
- (void) removeAllDeviceControlCallbacks;

- (void) addDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeDevicePairStateCallback:(HwDevicePairStateCallback _Nonnull)callback;
- (void) removeAllDevicePairStateCallbacks;

- (void) addDeviceBatteryStateCallback:(HwBatteryStateChangedCallback _Nonnull)callback;
- (void) removeDeviceBatteryStateCallback:(HwBatteryStateChangedCallback _Nonnull)callback;
- (void) removeAllDeviceBatteryStateCallbacks;

- (void) addWorkoutRealtimeDataUpdatedCallback:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
- (void) removeWorkoutRealtimeDataUpdatedCallback:(HwWorkoutRealtimeDataUpdatedCallback _Nonnull)callback;
- (void) removeAllWorkoutRealtimeDataUpdatedCallbacks;

- (void) addWorkoutStateUpdatedCallback:(HwWorkoutStateUpdatedCallback _Nonnull)callback;
- (void) removeWorkoutStateUpdatedCallback:(HwWorkoutStateUpdatedCallback _Nonnull)callback;
- (void) removeAllWorkoutStateUpdatedCallbacks;

- (void) addWorkoutTypeRecognitionCallback:(HwWorkoutTypeRecognitionCallback _Nonnull)callback;
- (void) removeWorkoutTypeRecognitionCallback:(HwWorkoutTypeRecognitionCallback _Nonnull)callback;
- (void) removeAllWorkoutTypeRecognitionCallbacks;

- (void) addReminderNotifyCallback:(HwReminderNotifyCallback _Nonnull)callback;
- (void) removeReminderNotifyCallback:(HwReminderNotifyCallback _Nonnull)callback;
- (void) removeAllReminderNotifyCallbacks;

- (void) addSpO2StateUpdatedCallback:(HwSpO2StateUpdatedCallback _Nonnull)callback;
- (void) removeSpO2StateUpdatedCallback:(HwSpO2StateUpdatedCallback _Nonnull)callback;
- (void) removeAllSpO2StateUpdatedCallbacks;

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

- (void) addWatchfaceIdChangedCallback:(HwWatchfaceIdChangedCallback _Nonnull)callback;
- (void) removeWatchfaceIdChangedCallback:(HwWatchfaceIdChangedCallback _Nonnull)callback;
- (void) removeAllWatchfaceIdChangedCallbacks;

- (void) addDeviceRequestGpsLocationListener:(HwRequestGpsLocationCallback _Nonnull)callback;
- (void) removeDeviceRequestGpsLocationListener:(HwRequestGpsLocationCallback _Nonnull)callback;
- (void) removeAllDeviceRequestGpsLocationListeners;

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

- (void) addNotProperlyWornCallback:(HwNotProperlyWornCallback _Nonnull)callback;
- (void) removeNotProperlyWornCallback:(HwNotProperlyWornCallback _Nonnull)callback;
- (void) removeAllNotProperlyWornCallbacks;

- (void) addMonitorStateChangedCallback:(HwMonitorStateChangedCallback _Nonnull)callback;
- (void) removeMonitorStateChangedCallback:(HwMonitorStateChangedCallback _Nonnull)callback;
- (void) removeAllMonitorStateChangedCallbacks;

- (void) addRealtimeHRVUpdateCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeRealtimeHRVUpdateCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllRealtimeHRVUpdateCallbacks;

- (void) addRealtimeRPMUpdateCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeRealtimeRPMUpdateCallback:(HwIntValueChangedCallback _Nonnull)callback;
- (void) removeAllRealtimeRPMUpdateCallbacks;

- (void) addRealtimeSkinTemperatureUpdateCallback:(HwFloatValueChangedCallback _Nonnull)callback;
- (void) removeRealtimeSkinTemperatureUpdateCallback:(HwFloatValueChangedCallback _Nonnull)callback;
- (void) removeAllRealtimeSkinTemperatureUpdateCallbacks;

- (void) addGoalUpdatedCallback:(HwGoalUpdatedCallback _Nonnull)callback;
- (void) removeGoalUpdatedCallback:(HwGoalUpdatedCallback _Nonnull)callback;
- (void) removeAllGoalUpdatedCallbacks;

- (void) addGoalsUpdatedCallback:(HwGoalsUpdatedCallback _Nonnull)callback;
- (void) removeGoalsUpdatedCallback:(HwGoalsUpdatedCallback _Nonnull)callback;
- (void) removeAllGoalsUpdatedCallbacks;

- (void) addHealthDataUpdatedCallback:(HwHealthDataUpdatedCallback _Nonnull)callback;
- (void) removeHealthDataUpdatedCallback:(HwHealthDataUpdatedCallback _Nonnull)callback;
- (void) removeAllHealthDataUpdatedCallbacks;

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

- (void) addGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiTranslateRequestListeners;

- (void) addGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiAgentResultRequestListeners;

- (void) addAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAllAiAnswerHandlerListeners;

- (void) addAvailableStroageUpdatedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeAvailableStroageUpdatedListener:(HwAvailableStorageCallback _Nonnull)callback;
- (void) removeAllAvailableStroageUpdatedListeners;

- (void) addAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAllAiVoicePlayRequestListeners;

- (void) addAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAllAiSubscriptionInfoRequestListeners;

- (void) deviceDataComeFromHeartRate:(NSData *_Nullable)data;
- (void) deviceDatasComeFrom8004:(NSData *_Nullable)data;

@end
