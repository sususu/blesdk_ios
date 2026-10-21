//
//  HwSwitchModel.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/2/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwFeatureSwitchType) {
    HwFeatureSwitchTypeAntiLost = 0x00,/**< 防丢开关  [antilost switch]*/
    HwFeatureSwitchTypeAutoSync = 0x01,/**< 自动同步开关 [auto-sync switch]*/
    HwFeatureSwitchTypeSleep = 0x02,/**< 睡眠开关 [sleep switch]*/
    HwFeatureSwitchTypeAutoSleep = 0x03,/**< 自动睡眠监测开关 [auto-sleep switch]*/
    HwFeatureSwitchTypeCallsRemind = 0x04,/**< 来电提醒开关 [calls remind]*/
    HwFeatureSwitchTypeMissCallsRemind = 0x05,/**< 未接来电提醒开关 [miss calls remind]*/
    HwFeatureSwitchTypeMessageRemind = 0x06,/**< 短信提醒开关 [message remind]*/
    HwFeatureSwitchTypeSocialRemind = 0x07,/**< 社交提醒开关 [social remind]*/
    HwFeatureSwitchTypeEmailRemind = 0x08,/**< 邮件提醒开关 [email remind]*/
    HwFeatureSwitchTypeCalendarRemind = 0x09,/**< 日历提醒开关 [calendar remind]*/
    HwFeatureSwitchTypeLongSitRemind = 0x0A,/**< 久坐提醒开关 [long sit remind]*/
    HwFeatureSwitchTypeEnergySaving = 0x0B,/**< 超低功耗功能开关 [energy saving switch]*/
    HwFeatureSwitchTypeTwice = 0x0C, /**< 二次提醒开关 [twice remind switch]*/
    HwFeatureSwitchTypeBell = 0x0D, /**< 铃声开关[bell remind] */
    HwFeatureSwitchTypeHandUpActive = 0x0E, /**<  抬手亮屏开关 [handup active switch]*/
    HwFeatureSwitchTypeGoalAchieve = 0x0F, /**< 目标达成开关 [goal achieve switch]*/
    HwFeatureSwitchTypeRealtimeHeartRateUpload = 0x10, /* device upload heartRate data switch,
                                                 once turn on,
                                                 and heartRateMonitor is on too,
                                                 heartRate data will keep uploading HR data to SDK which you can get them from callback of addHeartRateBmpListenerWithCallback API*/
    HwFeatureSwitchTypeSuperAlarm = 0x11, /* super alarm */
    HwFeatureSwitchTypeHeartRateMonitor = 0x12, /* heartRate monitor switch */
    HwFeatureSwitchTypeThreeAxisSensor = 0x13,
    HwFeatureSwitchTypePanVibration = 0x14, /*滑动震动开关 [Pan vibration switch] */
    HwFeatureSwitchTypeFatigueDetection = 0x15,  /*疲劳度检测开关 [Fatigue detection switch] */
    HwFeatureSwitchTypeTouchVibration = 0x16, /*点击震动开关 [Touch vibration switch] */
    HwFeatureSwitchTypeDoubleClickBack = 0x17, /*双击返回开关 [Double click back switch] */
    HwFeatureSwitchTypeScreenAlwaysOn = 0x18,  /*屏幕常亮开关 [screen always on switch] */
    HwFeatureSwitchTypeSportModel = 0x19, /*设备运动模式开关 [Watch sport model switch] */
    HwFeatureSwitchTypeMonitorBloodPressure = 0x1A, /*血压检测开关 [Monitor Blood Pressure switch] */
    HwFeatureSwitchTypeMovementNotify = 0x1B, /*机芯表盘勿扰开关 [Movement Watch Notify switch] */
    HwFeatureSwitchTypeAlwaysOnDisplay = 0x1C, /* 息屏显示 */
    HwFeatureSwitchTypeSpO2Switch = 0x1D,
    HwFeatureSwitchTypeLowBatteryReminder = 0x1F /* 低电量提醒开关 [low battery reminder] */
};

@interface HwFeatureSwitch : NSObject

@property(nonatomic, assign) BOOL S;
@property(nonatomic, assign) HwFeatureSwitchType type;

+ (HwFeatureSwitch *) modelWithSwitch:(BOOL)S type:(HwFeatureSwitchType)type;

@end

NS_ASSUME_NONNULL_END
