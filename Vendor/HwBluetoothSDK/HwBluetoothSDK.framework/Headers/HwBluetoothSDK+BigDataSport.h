//
//  HwBluetoothSDK+BigDataSport.h
//  HwBluetoothSDK
//
//  JL 协议 BigData 健康数据同步 API（门面转发至 HwBluetoothCenter+BigDataSport）。
//

#import "HwBluetoothSDK.h"
#import "HwBluetoothCenter+Sport.h"
#import "HwWorkout.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothSDK (BigDataSport)

/// JL BigData：睡眠点
- (void)getSleepBigDataWithCallback:(HwSleepInfoArrayCallback _Nullable)callback;

/// JL BigData：心率
- (void)getHeartRateBigDataWithCallback:(HwHeartRateInfoArrayCallback _Nullable)callback;

/// JL BigData：静息心率
- (void)getRestingHeartRateBigDataWithCallback:(HwHeartRateInfoArrayCallback _Nullable)callback;

/// JL BigData：压力
- (void)getStressBigDataWithCallback:(HwStressCallback _Nullable)callback;

/// JL BigData：血氧
- (void)getBloodOxygenBigDataWithCallback:(HwSpo2sCallback _Nullable)callback;

/// JL BigData：步数/活动明细
- (void)getSportDetailBigDataWithCallback:(HwActivitiesCallback _Nonnull)callback;

/// JL BigData：锻炼记录
- (void)getWorkoutsBigDataWithCallback:(void (^_Nullable)(NSArray<HwWorkout *> *_Nullable workouts, NSError *_Nullable error))callback;

/// JL BigData：删除手表端步数 BigData
- (void)delSportBigDataWithCallback:(HwBoolCallback _Nullable)callback;

/// JL BigData：AI 录音数据
- (void)getAiRecordBigDataWithCallback:(HwDataCallback _Nonnull)callback;

/// JL BigData：Hrv
- (void)getHrvBigDataWithCallback:(HwHrvCallback _Nonnull)callback;

/// JL BigData：呼吸频率
- (void)getBreathsBigDataWithCallback:(HwBreathsCallback _Nonnull)callback;

/// JL BigData：皮肤温度
- (void)getSkinTemperatureBigDataWithCallback:(HwTemperatureCallback _Nonnull)callback;

/// JL BigData：体温温度
- (void)getBodyTemperatureBigDataWithCallback:(HwTemperatureCallback _Nonnull)callback;

@end

NS_ASSUME_NONNULL_END
