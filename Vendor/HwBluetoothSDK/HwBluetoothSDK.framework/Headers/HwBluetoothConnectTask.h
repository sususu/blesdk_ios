//
//  HwBluetoothConnectTask.h
//  Pods
//
//  Created by HuaWo on 2022/6/13.
//

#import <Foundation/Foundation.h>
#import "HwCommonDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class HwBluetoothDevice;
@interface HwBluetoothConnectTask : NSObject

@property(nonatomic, copy) NSString *bleName;
@property(nonatomic, strong) HwBluetoothDevice *device;
@property(nonatomic, copy) HwConnectCallback callback;

@end

NS_ASSUME_NONNULL_END
