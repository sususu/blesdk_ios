/*!
 @header HwBluetoothCenter+Sport.h
 
 @author sujiang on 2018/4/21.
 @copyright  2018年[year] sujiang. All rights reserved.
 */
#import "HwBluetoothCenter.h"
#import "HwGoal.h"
#import "HwDeviceDefines.h"
#import "HwActivity.h"
#import "HwSleepPoint.h"
#import "HwHeartRate.h"
#import "HwActive.h"
#import "HwSpo2.h"
#import "HwHrv.h"
#import "HwStress.h"
#import "HwSleep.h"
#import "HwBloodPressure.h"
#import "HwPAI.h"
#import "HwVO2max.h"
#import "HwBodyState.h"
#import "HwCommonDefines.h"

extern NSString * _Nonnull HwKeySportIndex;
// cache key for sport state at timestamp
extern NSString * _Nonnull HwKeySportType;
extern NSString * _Nonnull HwKeySportTime;
extern NSString * _Nonnull HwKeyStep;
extern NSString * _Nonnull HwKeyDistance;
extern NSString * _Nonnull HwKeyCalorie;
extern NSString * _Nonnull HwKeyStaticCalorie;
extern NSString * _Nonnull HwKeyDuration;
// cache key for average heartRate value
extern NSString * _Nonnull HwKeyAvgHeartRate;


extern NSString * _Nonnull HwKeySleepIndex;
extern NSString * _Nonnull HwKeySleepTime;
extern NSString * _Nonnull HwKeySleepStatus;

extern NSString * _Nonnull HwKeyL38iHeartRateIndex;
extern NSString * _Nonnull HwKeyL38iHeartRateTime;
extern NSString * _Nonnull HwKeyL38iHeartRateBmp;

extern NSString * _Nonnull HwKeyAutoSleepStartHour;
extern NSString * _Nonnull HwKeyAutoSleepStartMin;
extern NSString * _Nonnull HwKeyAutoSleepEndHour;
extern NSString * _Nonnull HwKeyAutoSleepEndMin;
extern NSString * _Nonnull HwkeyAutoSleepWeek;

#pragma mark - main
/*!
 @brief 运动相关API接口[API port for sport]
 */
@interface HwBluetoothCenter (Sport)

#pragma mark - goal 目标[goal]

extern NSString * _Nonnull HwKeyGoalStep;
extern NSString * _Nonnull HwKeyGoalCaloris;
extern NSString * _Nonnull HwKeyGoalDistance;
extern NSString * _Nonnull HwKeyGoalSleep;
extern NSString * _Nonnull HwKeyGoalDuration;

typedef void (^HwGoalInfoCallback)(HwGoal * _Nullable goal, NSError * _Nullable error);

/*! @brief
 设置目标值[set goal value]
 
 @param type 类型[type]
 @param goal 目标值[gole]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setGoalWithType:(HwGoalType)type
                                          goal:(NSInteger)goal
                                      callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 获取目标值[gain goal value]
 
 @param callback 字典回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getGoalInfoWithCallback:(HwBCDictionaryCallback _Nullable )callback;

/*! @brief
 获取目标值[gain goal value]
 
 @param callback 数据模型回调[data models callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getGoalInfoModelWithCallback:(HwGoalInfoCallback _Nullable )callback;


#pragma mark - sport

#pragma mark - hearRate
extern NSString * _Nonnull HwKeyHeartRateIndex;
extern NSString * _Nonnull HwKeyHeartRateTime;
extern NSString * _Nonnull HwKeyHeartRateBmp;
extern NSString * _Nonnull HwKeyHeartRateResting;

extern NSString * _Nonnull HwKeyHeartRateMin;
extern NSString * _Nonnull HwKeyHeartRateMax;
extern NSString * _Nonnull HwKeyHeartRateWarningSwitch;

extern NSString * _Nonnull HwKeyHeartRateFatigueIndex;
extern NSString * _Nonnull HwKeyHeartRateFatigueTime;
extern NSString * _Nonnull HwKeyHeartRateFatigueValue;
extern NSString * _Nonnull HwKeyHeartRateStressValue;
extern NSString * _Nonnull HwKeyHeartRateBloodOxygenValue;

typedef void (^HwNewestHeartRateCallback)(HwHeartRate *_Nullable heartrate, NSError *_Nullable error);
typedef void (^HwHeartRateInfoArrayCallback)(NSArray<HwHeartRate *> *_Nullable heartRateArray, NSError *_Nullable error);


/*! @brief
 set device activity tracking state

 @param enable YES : tracking 、 NO : stop tracking
 @param callback bool callback
 @return task
 */
- (HwBluetoothTask *_Nullable) setActivityTrackingEnable:(BOOL)enable
                                                callback:(HwBoolCallback _Nullable )callback;

/*! @brief
 get activity tracking state
 YES : tracking
 NO : stop tracking

 @param callback bool callback
 @return task
 */
- (HwBluetoothTask *_Nullable) getActivityTrackingState:(HwBoolCallback _Nullable )callback;

typedef void (^HwSportAndSleepNumCallback)(NSUInteger sportNum, NSUInteger sleepNum, NSError *_Nullable error);
typedef void (^HwHealthDataCountCallback)(NSUInteger activityCount, NSUInteger sleepPointCount, NSUInteger heartrateCount, NSUInteger hrfCount, NSError *_Nullable error);
typedef void (^HwBpCountCallback)(NSUInteger bpCount, NSError *_Nullable error);
typedef void (^HwHealthDataCountForLSCallback)(NSUInteger activityCount, NSUInteger activeCount, NSUInteger sleepPointCount, NSUInteger heartrateCount, NSUInteger stressCount, NSUInteger spo2Count, NSError *_Nullable error);
typedef void (^HwActivitiesCallback)(NSArray<HwActivity *> * _Nullable sportArr, NSError *_Nullable error);
typedef void (^HwSleepsCallback)(NSArray<HwSleep *> * _Nullable sleepArr, NSError *_Nullable error);
typedef void (^HwActivesCallback)(NSArray<HwActive *> * _Nullable activeArr, NSError *_Nullable error);
typedef void (^HwStressCallback)(NSArray<HwStress *> * _Nullable stressArr, NSError *_Nullable error);
typedef void (^HwHrvCallback)(NSArray<HwHrv *> * _Nullable hrvArr, NSError *_Nullable error);
typedef void (^HwSpo2sCallback)(NSArray<HwSpo2 *> * _Nullable spo2Arr, NSError *_Nullable error);
typedef void (^HwBpsCallback)(NSArray<HwBloodPressure *> * _Nullable bpArr, NSError *_Nullable error);

/*! @brief
 获取设备中的运动和睡眠个数[gain the sport and sleep number of the device]
 
 @param callback 运动睡眠个数回调[sport and sleep  number callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getSportAndSleepNumWithCallback:(HwSportAndSleepNumCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getActivityNumWithCallback:(HwHealthDataCountCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getActivityNumForLSWithStartTime:(NSTimeInterval)startTime
                                                        endTime:(NSTimeInterval)endTime
                                                       callback:(HwHealthDataCountForLSCallback _Nullable)callback;

/*! @brief
 根据运动个数去获取运动详情[gain the sport details based on the sport number]
 
 @param sportNum 运动个数[sport number]
 @param callback 运动详情字典形式回调sport detail dictionarycallback
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getSportInfo:(NSUInteger)sportNum callback:(HwBCDictionaryArrayCallback _Nullable)callback;

/*! @brief
 根据运动个数去获取运动详情[gain the sport details based on the sport number]
 
 @param sportNum 运动个数[sport number]
 @param callback 运动模型回调[sport model callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getSportInfoModels:(NSUInteger)sportNum callback:(HwActivitiesCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getSportNumForLSWithStartTime:(NSTimeInterval)startTime
                                                     endTime:(NSTimeInterval)endTime
                                                    callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getSleepNumForLSWithStartTime:(NSTimeInterval)startTime
                                                     endTime:(NSTimeInterval)endTime
                                                    callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getActiveNumForLSWithStartTime:(NSTimeInterval)startTime
                                                      endTime:(NSTimeInterval)endTime
                                                     callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getHeartrateNumForLSWithStartTime:(NSTimeInterval)startTime
                                                         endTime:(NSTimeInterval)endTime
                                                        callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getStressNumForLSWithStartTime:(NSTimeInterval)startTime
                                                      endTime:(NSTimeInterval)endTime
                                                     callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getSpo2NumForLSWithStartTime:(NSTimeInterval)startTime
                                                    endTime:(NSTimeInterval)endTime
                                                   callback:(HwHealthDataCountForLSCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getBpNumWithCallback:(HwBpCountCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getPAINumWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getVO2maxNumWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (HwBluetoothTask *_Nullable) getSportsWithStartTime:(NSTimeInterval)startTime
                                              endTime:(NSTimeInterval)endTime
                                                count:(NSInteger)count
                                             callback:(HwActivitiesCallback _Nonnull)callback;

/*! @brief
 获取设备是否正在睡眠的状态，1 表示正在睡眠，0表示不在睡眠
 */
- (HwBluetoothTask *_Nullable) getSleepStateWithCallback:(HwBCIntegerCallback _Nonnull)callback;

- (HwBluetoothTask *_Nullable) getSleepsWithStartTime:(NSTimeInterval)startTime
                                              endTime:(NSTimeInterval)endTime
                                                count:(NSInteger)count
                                             callback:(HwSleepsCallback _Nonnull)callback;

- (HwBluetoothTask *_Nullable) getHeartratesWithStartTime:(NSTimeInterval)startTime
                                                  endTime:(NSTimeInterval)endTime
                                                    count:(NSInteger)count
                                                 callback:(HwHeartRateInfoArrayCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getActivesWithStartTime:(NSTimeInterval)startTime
                                               endTime:(NSTimeInterval)endTime
                                                 count:(NSInteger)count
                                              callback:(HwActivesCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getStressWithStartTime:(NSTimeInterval)startTime
                                              endTime:(NSTimeInterval)endTime
                                                count:(NSInteger)count
                                             callback:(HwStressCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getSpo2WithStartTime:(NSTimeInterval)startTime
                                            endTime:(NSTimeInterval)endTime
                                              count:(NSInteger)count
                                           callback:(HwSpo2sCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getBpWithCount:(NSInteger)count
                                     callback:(HwBpsCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getPAIsWithCount:(NSInteger)count
                                       callback:(HwPAIsCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delPAIsWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getVO2maxsWithCount:(NSInteger)count
                                          callback:(HwVO2maxsCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) delVO2maxsWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getBodyStateWithCallback:(HwBodyStateCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) deleteBpWithCallback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getNewestHeartrateWithCallback:(HwNewestHeartRateCallback _Nullable)callback;

/*! @brief sport detail data
 
 Get the sport detail data stored on the device

@param callback  include error or  sport detail data

*/
- (void) getSportDetailDataWithCallback:(HwActivitiesCallback _Nullable)callback;

/*! @brief
 删除手表中运动数据[delete sport data in device]
 
 @param callback 成功与否的回调[callback of delete successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteSportInfoWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - sleep
typedef void (^HwSleepInfoArrayCallback)(NSArray<HwSleepPoint *> * _Nullable sleepArray, NSError *_Nullable error);

// 运动时间单位为分种[the unit of sport time is minute]
 
/*! @brief
 根据睡眠个数获取睡眠详情[obtain the sleep details based on the sleep numbers]
 
 @param sleepNum 睡眠个数[sleep number]
 @param callback 字典形式回调[dictionarycallback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getSleepInfo:(NSUInteger)sleepNum callback:(HwBCDictionaryArrayCallback _Nullable)callback;


/*! @brief sleep detail data
Get the sleep detail data stored on the device
@param callback  include error or sleep detail data
*/
- (void) getSleepDetailWithCallback:(HwSleepInfoArrayCallback _Nullable)callback;


/*! @brief
 根据睡眠个数获取睡眠详情[obtail the sleep details based on the sleep numbers]
 
 @param sleepNum 睡眠个数[sleep numbers]
 @param callback 模型形式回调[models callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getSleepInfoModels:(NSUInteger)sleepNum callback:(HwSleepInfoArrayCallback _Nullable)callback;

/*! @brief
 删除设备中的睡眠详情[delete the sleep details of device]
 
 @param callback 成功与否回调[callback of deleting successfully or not ]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteSleepInfoWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取自动睡眠信息详情[get autosleep details]
 
 @param callback 详情看字典字段[check dictionary field for the details]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getAutoSleepTimeInfoWithCallback:(HwBCDictionaryCallback _Nullable)callback;

/*! @brief
 设置自动睡眠信息[set autosleep]
 
 @param startHour 开始小时[starthour]
 @param startMin 开始分钟[startmin]
 @param endHour 结束小时[endhour]
 @param endMin 结束分钟[endmin]
 @param callback 成功与否回调[callback successfully or not ]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setAutoSleepTimeInfoWithStartHour:(int)startHour
                                               startMin:(int)startMin
                                                endHour:(int)endHour
                                                 endMin:(int)endMin
                                               callback:(HwBoolCallback _Nullable)callback;
/*! @brief
向设备发送睡眠评分[send score for your sleeping]
@param callback 是否回调[call back or not]
@return 任务[task]
*/
- (HwBluetoothTask *_Nullable) setSleepCore:(NSInteger)score callback:(HwBoolCallback _Nullable)callback;

#pragma mark - long sit

typedef void (^HwLongSitAlertCallback)(BOOL S,
                                       NSUInteger span,
                                       NSUInteger startHour,
                                       NSUInteger startMin,
                                       NSUInteger endHour,
                                       NSUInteger endMin,
                                       HwWeek week,
                                       NSError *_Nullable error);

/*! @brief
 获取长坐提醒详情
 
 @param callback 详情回调
 @return 任务
 */
- (HwBluetoothTask *_Nullable) getLongSitAlertInfoWithCallback:(HwLongSitAlertCallback _Nullable)callback;

/*! @brief
 设置静坐（久坐）提醒[set alert to sedentary]
 
 @param S 开关[off and on]
 @param span 检测时间间隔[check the span ]
 @param startHour 开始小时（0-23）[starthour]
 @param startMin 开始分钟（0-59）[start minute]
 @param endHour 结束小时（0-23）[endour]
 @param endMin 结束分钟（0-59）[end minute]
 @param week 星期几（周一到周日）[week]
 @param callback 回调[callback]
 @return task
 */
- (HwBluetoothTask *_Nullable) setLongSitAlertSwitch:(BOOL)S
                                                span:(NSUInteger)span
                                           startHour:(NSUInteger)startHour
                                            startMin:(NSUInteger)startMin
                                             endHour:(NSUInteger)endHour
                                              endMin:(NSUInteger)endMin
                                                week:(HwWeek)week
                                            callback:(HwBoolCallback _Nullable)callback;

/*! @brief
Get heart rate data from device

@param callback  NSArray<HwHeartRate *> or error

*/

- (void) getHeartRateDetailWithCallback:(HwHeartRateInfoArrayCallback _Nullable)callback;


/*! @brief
 获取设备中的心率个数[get the heartrate number of the device]
 
 @param callback 个数回调[number callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateNumWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 根据心率个数获取设备中的心率详情[get the heartrate detail based on the heartrate numbers]
 
 @param num 心率个数[heartrate numbers]
 @param callback 详情回调[detail callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateInfo:(NSUInteger)num callback:(HwBCDictionaryArrayCallback _Nullable)callback;

/*! @brief
 根据心率个数获取设备中的心率详情[get the heartrate detail based on the heartrate numbers]
 
 @param num 心率个数[heartrate numbers]
 @param callback 详情回调[detail callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateInfoModels:(NSUInteger)num callback:(HwHeartRateInfoArrayCallback _Nullable)callback;


/*! @brief
 删除心率详情[delete heartrate detail]
 
 @param callback 成功与否回调[callback successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteHeartRateWithCallback:(HwBoolCallback _Nullable)callback;

/**
 获取心率变异性个数[get the heartrate fatigue number of the device]

 @param callback 个数回调[number callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateFatigueNumWithCallback:(HwBCIntegerCallback _Nullable)callback;

/**
 根据心率疲劳度个数获取设备中的心率疲劳度详情[get the heartrate fatigue detail based on the heartrate fatigue numbers]
 
 @param num 心率疲劳度个数[heartrate fatigue numbers]
 @param callback 详情回调[detail callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateFatigueInfo:(NSUInteger)num callback:(HwBCDictionaryArrayCallback _Nullable)callback;

/**
 删除心率疲劳度详情[delete heartrate fatigue detail]
 
 @param callback 成功与否回调[callback successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteHeartRateFatigueWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置手表自动检测心率时间间隔[set the time span of the heartrate auto-check]
 
 @param span 每隔多少分钟产生一笔心率数据，有效值有：0、5、10、15、30、45、60[how often a new heartrate will be produced, effective value: 0 ,5,10,15,30,45,60]
 其中0表示关闭['0' is off]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) autoDetectHeartRateWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取手表当前自动间隔心率的时间间隔（分种）[get the time span of the heartrate]
 回调中的整型单位是分种[unit of callback is minute]
 @param callback 回调(NSInteger, NSError)
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getAutoDetectHeartRateSpanWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 获取心率警告的值[get the value of the heartrate alert]
 
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getHeartRateWarningValueWithCallback:(HwBCDictionaryCallback _Nullable)callback;

/*! @brief
 设置血氧自动检测值
 
 @param span 检测时间间隔[check the span ]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) autoDetectBloodOxygenWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取血氧自动检测的值[Get the value of the automatic blood oxygen test]
 
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getAutoDetectBloodOxygenSpanWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置低血氧提醒
 
 @param span 低血氧提醒罚值[check the span ]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setBloodOxygenAlertWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取低血氧提醒的值[Get the value of the blood oxygen alert]
 
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getBloodOxygenAlertWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置压力自动检测值
 
 @param span 检测时间间隔[check the span ]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) autoDetectStressWithSpan:(int)span callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取压力自动检测的值[Gets the value of the automatic pressure detection]
 
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getAutoDetectStressSpanWithCallback:(HwBCIntegerCallback _Nullable)callback;

/*! @brief
 设置心率警告值[set the heartrate alert value]
 
 @param max 最大值[the max]
 @param min 最小值[the min]
 @param off 开关[on and off]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setHeartRateWarningValueWithMax:(NSInteger)max
                                                           min:(NSInteger)min
                                                     switchOff:(BOOL)off
                                                      callback:(HwBoolCallback _Nullable)callback;


- (HwBluetoothTask *_Nullable) setHeartRateRealtimeUploadSwitch:(BOOL)S
                                                       callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getHeartRateRealtimeUploadSwitchWithCallback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setHeartRateMonitorSwitch:(BOOL)S
                                                callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getHeartRateMonitorSwitchWithCallback:(HwBoolCallback _Nullable)callback;


/// 快速回传心率数据
/// @param num 心率数据条数
/// @param callback 返回心率字典数组
- (HwBluetoothTask *_Nullable) quickGetHeartRateInfo:(NSUInteger)num callback:(HwBCDictionaryArrayCallback _Nullable)callback;

/// 快速回传心率数据
/// @param num 心率数据条数
/// @param callback 返回心率model数组
- (HwBluetoothTask *_Nullable) quickGetHeartRateInfoModels:(NSUInteger)num callback:(HwHeartRateInfoArrayCallback _Nullable)callback;

/**
 删除压力详情
 
 @param callback 成功与否回调[callback successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteStressWithCallback:(HwBoolCallback _Nullable)callback;

/**
 删除血氧详情
 
 @param callback 成功与否回调[callback successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteBloodOxygenWithCallback:(HwBoolCallback _Nullable)callback;

/**
 删除hrv详情
 
 @param callback 成功与否回调[callback successfully or not]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteHrvWithCallback:(HwBoolCallback _Nullable)callback;


#pragma mark - calorie
// 基础卡路里（非运动状态下，自动生成的卡路里）[basic calorie(under non-sport situation, autogeneration calorie )]

/*! @brief
 获取静态卡路里开关[get static calorie switch]
 
 @param callback 开关回调[switch callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getCalorisAutoStateWithCallback:(HwBoolCallback _Nullable)callback;

/*! @brief
 设置静态卡路里开关[set static calorie switch]
 
 @param state 开关[switch]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setCalorisAutoState:(BOOL)state
                                          callback:(HwBoolCallback _Nullable)callback;

/*! @brief
 获取心率变异性HRV开关
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getAutoTrackHRVWithCallback:(HwBoolCallback _Nullable)callback;
/*! @brief
 设置心率变异性HRV开关
 
 @param status 开关[switch]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) setAutoHRVWithStatus:(int)status callback:(HwBoolCallback _Nullable)callback;

#pragma mark - stop upload
// 中断设备上传数据，zetime不支持[stop upload the data,zetime nonsupport]
- (HwBluetoothTask *_Nullable) stopGettingAllInfoWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) stopGettingSportInfoWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) stopGettingSleepInfoWithCallback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) stopGettingHeartRateInfoWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - bpm

@end
