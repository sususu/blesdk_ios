//
//  HwCommonDefines.h
//  Pods-HwBluetoothSDK_Example
//
//  Created by HuaWo on 2022/6/13.
//

#ifndef HwCommonDefines_h
#define HwCommonDefines_h

#import <Foundation/Foundation.h>
#import "HwBluetoothEnums.h"
#import "NSDate+HwSDK.h"
#import "HwBluetoothLogger.h"

@class HwBluetoothDevice;
@class HwBluetoothData;
@class HwGpsStatus;
@class HwPAI;
@class HwVO2max;
@class HwBodyState;
@class HwStanding;
/**
 扫描设备，发现设备的回调，
 如果NSError不为空，说明扫描设备出现错误
 
 @param devices 设备列表
 @param error 错误信息
 */
typedef void (^HwSearchDevicesCallback)(NSArray<HwBluetoothDevice *> *devices, NSError *error);
typedef void (^HwStopSearchingDevicesCallback)(void);
typedef void (^HwStopSearchingDevicesForConnectionCallback)(NSError *error);
typedef BOOL (^HwSearchDevicesForConnectionCallback)(NSArray<HwBluetoothDevice *> *devices, NSError *error);
typedef void (^HwConnectCallback)(NSError *error);
typedef void (^HwConnectedCallback)(HwBluetoothDevice *device);
typedef void (^HwBluetoothStateChangedCallback)(HwBluetoothState state);
typedef void (^HwBluetoothConnectionStateChangedCallback)(HwBluetoothConnectionState connectionState);

typedef void (^HwBCRequestCallback)(HwBluetoothData *dataModel, NSError *error);
typedef void (^HwTaskErrorHandler)(HwBluetoothData *dataModel);
typedef void (^HwBCVoidCallback)(void);
typedef void (^HwFailedCallback)(NSInteger code);
typedef void (^HwBoolCallback)(BOOL b, NSError *error);
typedef void (^HwBCAddressBookCallback)(BOOL b, NSError *error, NSInteger index);
typedef void (^HwBCIntegerCallback)(NSInteger n, NSError *error);
typedef void (^HwDataCallback)(NSData *data, NSError *error);
typedef void (^HwBCFloatCallback)(float f, NSError *error);
typedef void (^HwStringCallback)(NSString *str, NSError *error);
typedef void (^HwBCDictionaryCallback)(NSDictionary *dic, NSError *error);
typedef void (^HwBCArrayCallback)(NSArray *array, NSError *error);
typedef void (^HwBCStringArrayCallback)(NSArray<NSString *> *strArray, NSError *error);
typedef void (^HwBCDictionaryArrayCallback)(NSArray<NSDictionary *> *dicArray, NSError *error);
typedef void (^HwDateCallback)(NSDate *date, NSError *error);
typedef void (^HwBCDataCallback)(NSDate *data, NSError *error);
typedef void (^HwBCOtaStatusCallback)(NSUInteger allSize, NSData *crcData, NSUInteger recvSize, NSError *error);
typedef void (^HwBCCompressStatusCallback)(NSUInteger method, int param, NSError *error);
typedef void (^HwGpsStatusCallback)(HwGpsStatus *gpsStatus, NSError *error);
typedef void (^HwDevicePasscodeCallback)(BOOL b, NSError *error, NSString *passcode);
typedef void (^HwPAIsCallback)(NSArray<HwPAI *> * _Nullable paiArr, NSError *_Nullable error);
typedef void (^HwVO2maxsCallback)(NSArray<HwVO2max *> * _Nullable vo2maxArr, NSError *_Nullable error);
typedef void (^HwBodyStateCallback)(HwBodyState * _Nullable bodyState, NSError *_Nullable error);
typedef void (^HwStandingDatasCallback)(NSArray<HwStanding *> * _Nullable standingDatas, NSError *_Nullable error);
/**
 完成初始化
 扫描完成服务和特征之后
 可以发送数据了
 
 @param error 如果错误了，那就不行
 */
typedef void (^HwDeviceRWReadyCallback)(NSError * _Nullable error);


#pragma mark - common data

#endif /* HwCommonDefines_h */
