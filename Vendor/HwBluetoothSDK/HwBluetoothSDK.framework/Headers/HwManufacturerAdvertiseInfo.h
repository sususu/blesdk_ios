//
//  HwManufacturerAdvertiseInfo.h
//  HwBluetoothSDK
//
//  华沃厂商广播（Manufacturer Specific Data）解析结果。
//  解析失败或不存在时使用默认值。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 华沃厂商标识 */
FOUNDATION_EXPORT const NSInteger HwHuawoCompanyId;
/** 华沃厂商广播特征值 */
FOUNDATION_EXPORT const NSInteger HwHuawoFeatureValue;

@interface HwManufacturerAdvertiseInfo : NSObject

@property (nonatomic, assign, readonly) NSInteger manufacturerId;
@property (nonatomic, assign, readonly) NSInteger productType;
@property (nonatomic, assign, readonly) NSInteger productModel;
@property (nonatomic, assign, readonly) BOOL charging;
@property (nonatomic, assign, readonly) NSInteger batteryLevel;
@property (nonatomic, assign, readonly) BOOL valid;

+ (instancetype)emptyInfo;

/** CoreBluetooth 的 kCBAdvDataManufacturerData（含 2 字节厂商标识）。 */
+ (instancetype)infoWithManufacturerData:(NSData *_Nullable)manufacturerData;

@end

NS_ASSUME_NONNULL_END
