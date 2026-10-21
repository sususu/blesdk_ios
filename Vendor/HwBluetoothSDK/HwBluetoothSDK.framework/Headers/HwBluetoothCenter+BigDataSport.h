//
//  HwBluetoothCenter+BigDataSport.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/9/8.
//

#import "HwBluetoothCenter.h"
#import "HwBluetoothCenter+Sport.h"
#import "HwBluetoothCenter+Workout.h"

@interface HwBluetoothCenter (BigDataSport)

#pragma mark - Workout
- (void)getWorkoutsBigDataWithCallback:(HwWorkoutsCallback _Nullable)callback;

#pragma mark - sleep
- (void)getSleepBigDataWithCallback:(HwSleepInfoArrayCallback _Nullable)callback;

#pragma mark - HeartRate
- (void)getHeartRateBigDataWithCallback:(HwHeartRateInfoArrayCallback _Nullable)callback;

#pragma mark - RestingHeartRate
- (void)getRestingHeartRateBigDataWithCallback:(HwHeartRateInfoArrayCallback _Nullable)callback;

#pragma mark - Stress
- (void)getStressBigDataWithCallback:(HwStressCallback _Nullable)callback;

#pragma mark - BloodOxygen
- (void)getBloodOxygenBigDataWithCallback:(HwSpo2sCallback _Nullable)callback;

#pragma mark - Sprot
- (void)getSportDetailBigDataWithCallback:(HwActivitiesCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable)delSportBigDataWithCallback:(HwBoolCallback _Nullable)callback;

#pragma mark - AI record
- (void)getAiRecordBigDataWithCallback:(HwDataCallback _Nonnull)callback;

#pragma mark - Hrv
- (void)getHrvBigDataWithCallback:(HwHrvCallback _Nonnull)callback;

#pragma mark - Breaths
- (void)getBreathsBigDataWithCallback:(HwBreathsCallback _Nonnull)callback;
- (void)delBreathsBigDataWithCallback:(HwBoolCallback _Nullable )callback;

#pragma mark - SkinTemperature
- (void)getSkinTemperatureBigDataWithCallback:(HwTemperatureCallback _Nonnull)callback;
- (void)delSkinTemperatureBigDataWithCallback:(HwBoolCallback _Nullable )callback;

#pragma mark - BodyTemperature
- (void)getBodyTemperatureBigDataWithCallback:(HwTemperatureCallback _Nonnull)callback;
- (void)delBodyTemperatureBigDataWithCallback:(HwBoolCallback _Nullable )callback;

@end

