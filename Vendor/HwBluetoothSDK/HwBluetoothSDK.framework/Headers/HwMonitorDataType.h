//
//  HwMonitorDataType.h
//  HwBluetoothSDK
//
//  即时测量数据类型，取值与 Android DataType 对齐
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwMonitorDataType) {
    HwMonitorDataTypeHeartRate = 0x01,
    HwMonitorDataTypeStress = 0x02,
    HwMonitorDataTypeSpO2 = 0x03,
    HwMonitorDataTypeHRV = 0x04,
    HwMonitorDataTypeSkinTemperature = 0x05,
    HwMonitorDataTypeBodyTemperature = 0x06,
    HwMonitorDataTypeRespiratoryRate = 0x07,
    HwMonitorDataTypeUnknown = 0xff,
};

NS_INLINE HwMonitorDataType HwMonitorDataTypeFromValue(NSInteger value) {
    switch (value) {
        case HwMonitorDataTypeHeartRate:
        case HwMonitorDataTypeStress:
        case HwMonitorDataTypeSpO2:
        case HwMonitorDataTypeHRV:
        case HwMonitorDataTypeSkinTemperature:
        case HwMonitorDataTypeBodyTemperature:
        case HwMonitorDataTypeRespiratoryRate:
            return (HwMonitorDataType)value;
        default:
            return HwMonitorDataTypeUnknown;
    }
}

NS_ASSUME_NONNULL_END
