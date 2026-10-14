//
//  HwVibrationSettings.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwVibrationSettings
 @brief 设备震动开关与强度设置 [device vibration on/off and intensity]
 */
@interface HwVibrationSettings : NSObject

/*! @brief 震动开关 [vibration on/off] */
@property(nonatomic, assign, getter=isOn) BOOL on;

/*! @brief 震动强度 [vibration intensity] */
@property(nonatomic, assign) NSInteger intensity;

@end

typedef void (^HwVibrationSettingsCallback)(HwVibrationSettings *_Nullable settings, NSError *_Nullable error);

NS_ASSUME_NONNULL_END
