#import <Foundation/Foundation.h>

#import "HwBluetoothCallback.h"
#import "HwCommonDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class HwBluetoothCenter;
@class HwJieLiTransferChannel;

typedef NS_ENUM(NSUInteger, HwOtaLogLevel) {
    HwOtaLogLevelNone = 0,
    HwOtaLogLevelError = 1,
    HwOtaLogLevelInfo = 2,
    HwOtaLogLevelDebug = 3,
};

/// OTA V2 独立业务入口。实例由 HwBluetoothSDK 创建和持有，外部不要自行初始化。
@interface HwOtaV2Service : NSObject

/// 当前是否存在已被 Service 接受且尚未结束的 OTA V2 业务。
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;
@property (nonatomic, assign) HwOtaLogLevel logLevel;

/**
 启动 OTA V2。

 ready 在设备确认 header 后成功；progress 范围为 0~1；finish 在资源清理完成后调用。
 每条 OTA 命令按 send -> 完整响应加入共享严格 FIFO；实际写入后由共享 Channel 统一管理 60 秒超时。
 当已有任务运行时，新任务会通过 ready 和 finish 返回错误码 3002，旧任务不受影响。
 */
- (void)startWithBinData:(NSData *)binData
           readyCallback:(HwBoolCallback _Nullable)readyCallback
        progressCallback:(HwBCFloatCallback _Nullable)progressCallback
          finishCallback:(HwBoolCallback _Nullable)finishCallback;

/// 取消当前任务；任务未运行时为幂等空操作。
- (void)stop;

/// 供 HwBluetoothSDK 组装依赖；业务方统一通过 HwBluetoothSDK.otaV2Service 使用。
- (instancetype)initWithBluetoothCenter:(HwBluetoothCenter *)center
                         transferChannel:(HwJieLiTransferChannel *)transferChannel NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
