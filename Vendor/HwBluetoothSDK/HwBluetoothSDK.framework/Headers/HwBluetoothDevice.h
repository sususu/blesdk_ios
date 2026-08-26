//
//  HwBluetoothDevice.h
//  HwBluetooth
//
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothCallback.h"

// ================== main ======================
extern NSString *HwBDMainServiceUUID;
extern NSString *HwBD_CY_MainServiceUUID;
extern NSString *HwBD8001CharacteristicMainWriteUUID;
extern NSString *HwBD8002CharacteristicNotificationUUID;

// ================== meida ====================
extern NSString *HwBDMediaServiceUUID;
extern NSString *HwBD8003CharacteristicMainWriteUUID;
extern NSString *HwBD8004CharacteristicNotificationUUID;

// ================== file ====================
extern NSString *HwBD8005CharacteristicMainWriteUUID;
extern NSString *HwBD8006CharacteristicNotificationUUID;

// ================== heart ====================
extern NSString *HwBD_StandardHeartRateServiceUUID;
extern NSString *HwBD_StandardHeartRateCharacteristicUUID;

// ================== OTA ====================
extern NSString *HwBD_OTAServiceUUID;
extern NSString *HwBD_OTACharacteristicNotificationUUID;
extern NSString *HwBD_OTACharacteristicWriteUUID;
extern NSString *HwBD_OTADUFVersion;

extern NSString *HwBD_OtaV2ServiceUUID;
extern NSString *HwBD_OtaV2CharacteristicNotificationUUID;
extern NSString *HwBD_OtaV2CharacteristicWriteUUID;

// userInfo : {data:NSData}
extern NSString *HwBD_8001DidUpdateValueNotification;
extern NSString *HwBD_8002DidUpdateValueNotification;
extern NSString *HwBD_8003DidUpdateValueNotification;
extern NSString *HwBD_8004DidUpdateValueNotification;
extern NSString *HwBD_8006DidUpdateValueNotification;
extern NSString *HwBD_DidUpdateValueNotification;
extern NSString *HwBD_DidUpdateValueLoggerNotification;
extern NSString *HwBD_DidWriteValueLoggerNotification;
extern NSString *HwBD_OtaV2DidUpdateValueNotification;

// 心率值来的通知
// userInfo : bpm:NSNumber
extern NSString *HwBD_HeartRateDidUpdateValueNotification;

extern NSString *HwBluetoothDeviceRSSIUpdateNotification;
extern NSString *HwBluetoothDeviceReadyNotification;

@class HwBluetoothData;
@class HwBluetoothDevice;

@protocol HwBluetoothDeviceDelegate<NSObject>
@optional
- (void) bluetoothDeviceWriteBackData:(NSData *)data fromCharacteristicUUID:(NSString *)uuid;
- (void) bluetoothDevice:(HwBluetoothDevice *)bluetoothDevice didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

@end

@protocol HwBluetoothDeviceRssiUpdateDelegate <NSObject>

- (void) bluetoothDevice:(HwBluetoothDevice *)bluetoothDevice didUpdateRSSI:(NSInteger)rssi;

@end

@interface HwBluetoothDevice : NSObject<NSCoding, NSCopying>

@property(nonatomic, weak) id<HwBluetoothDeviceDelegate> delegate;
@property(nonatomic, assign, readonly) BOOL connected;

@property(nonatomic, strong, readonly) NSNumber *rssi;
@property(nonatomic, strong, readonly) CBPeripheral *peripheral;
@property(nonatomic, strong, readonly) NSDictionary<NSString *, id> *advertisementData;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *macAddress;
@property(nonatomic, copy) NSString *uuid;

// 如果peripheral的名字为null。返回也为nil
+ (HwBluetoothDevice *) deviceWithPeripheral:(CBPeripheral *)peripheral
                                        rssi:(NSNumber *)rssi
                           advertisementData:(NSDictionary<NSString *, id> *)advertisementData;
+ (HwBluetoothDevice *) deviceWithMac:(NSString *)mac;
+ (HwBluetoothDevice *) deviceWithName:(NSString *)name;
+ (HwBluetoothDevice *) deviceWithUUID:(NSString *)uuid;

/**
 如果peripheral的名字为null。返回也为nil
 
 @param peripheral p
 @param rssi r
 @return device
 */
- (HwBluetoothDevice *) initWithPeripheral:(CBPeripheral *)peripheral
                                      rssi:(NSNumber *)rssi
                         advertisementData:(NSDictionary<NSString *, id> *)advertisementData;

- (void) updateWithPeripheral:(CBPeripheral *)peripheral
                         rssi:(NSNumber *)rssi
            advertisementData:(NSDictionary<NSString *, id> *)advertisementData;

- (void) updateMac:(NSString *)mac
              rssi:(NSNumber *)rssi;

#pragma mark - public methods
- (void) getReadyWithCallback:(HwDeviceRWReadyCallback)callback;

- (void) writeDataModel:(HwBluetoothData *)data;

- (void) writeData:(NSData *)data toCharactertic:(NSString *)charactericUUID;

- (void) dataModel:(HwBluetoothData *)data failedWithError:(NSError *)error;

- (BOOL) hasService:(NSString *)serviceUUID;
- (BOOL) hasCharacteristic:(NSString *)characteristicUUID;
- (BOOL) writeData:(NSData *)data toCharacteristic:(NSString *)characteristicUUID;
- (BOOL) readDataForCharacteristic:(NSString *)characteristicUUID;

#pragma mark - ota
- (void) writeDataToOTANotificationCharacteristic:(NSData *)data;
- (void) writeDataToOTAWriteCharacteristic:(NSData *)data;
- (void) writeDataTo8001WriteCharacteristic:(NSData *)data;
- (void) writeDataTo8005WriteCharacteristic:(NSData *)data;
- (void) writeDataToOtaV2WriteCharacteristic:(NSData *)data;

#pragma mark - RSSI
/**
 Read RSSI every interval. When the interval is 0, it is only read once.
 @param delegate will callback ``` - (void) bluetoothDevice:(HwBluetoothDevice *)bluetoothDevice didUpdateRSSI:(NSInteger)rssi ``` when RSSI updates
 */
- (void) readRSSIWithAutoUpdateInterval:(NSTimeInterval)timeInterval
                               delegate:(id<HwBluetoothDeviceRssiUpdateDelegate>)delegate;

/**
 Read RSSI every interval. When the interval is 0, it is only read once.
 @param callback will callback when RSSI updates
 */
- (void) readRSSIWithAutoUpdateInterval:(NSTimeInterval)timeInterval
                         updateCallback:(void(^)(HwBluetoothDevice *device, NSInteger rssi))callback;

- (void) stopReadRSSI;

#pragma mark - utils
- (NSUInteger) MTU;

- (void) disconnect;

@end
