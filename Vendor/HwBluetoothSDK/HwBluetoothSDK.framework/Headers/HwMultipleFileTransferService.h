#import <Foundation/Foundation.h>

#import "HwBluetoothCallback.h"
#import "HwCommonDefines.h"
#import "HwMultipleFileTransferModel.h"

NS_ASSUME_NONNULL_BEGIN

@class HwBluetoothCenter;
@class HwJieLiTransferChannel;

typedef NS_ENUM(NSInteger, MultipleFileTransferType) {
    MultipleFileTransferTypeMusic = 0x01,
    MultipleFileTransferTypePhoto = 0x02,
    MultipleFileTransferTypeAIDialPreview = 0x03,
    MultipleFileTransferTypeOnlineDial = 0x04,
    MultipleFileTransferTypeCustomDialImage = 0x05,
    MultipleFileTransferTypeAIDialImage = 0x06,
};

typedef void(^MftLogBlock)(NSString *logMessage);

/// 杰理多文件传输的独立业务入口。实例由 HwBluetoothSDK 创建和持有。
@interface HwMultipleFileTransferService : NSObject

/// 当前是否有已被 Service 接受且尚未结束的多文件传输业务。
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;
@property (nonatomic, copy, nullable) MftLogBlock logBlock;

/**
 启动多文件传输。

 ready 只在设备允许下发时成功；progress 范围为 0~1；finish 在业务资源清理后调用。
 每条 MFT 命令按 send -> 完整响应加入共享严格 FIFO；实际写入后由共享 Channel 统一管理 60 秒超时。
 运行中再次启动时，新调用只会收到错误码 3002 的 finish，原会话不受影响。
 */
- (void)startWithFileModels:(NSArray<HwMultipleFileTransferModel *> *)fileModels
               transferType:(MultipleFileTransferType)transferType
              readyCallback:(HwBoolCallback _Nullable)readyCallback
           progressCallback:(HwBCFloatCallback _Nullable)progressCallback
             finishCallback:(HwBoolCallback _Nullable)finishCallback;

/// 从文件夹筛选符合类型的文件后启动，筛选规则与旧多文件传输保持一致。
- (void)startWithFilePath:(NSString *)filePath
             transferType:(MultipleFileTransferType)transferType
            readyCallback:(HwBoolCallback _Nullable)readyCallback
         progressCallback:(HwBCFloatCallback _Nullable)progressCallback
           finishCallback:(HwBoolCallback _Nullable)finishCallback;

/// 主动取消当前业务；业务未运行时为幂等空操作。
- (void)stop;

/// 供 HwBluetoothSDK 组装依赖；业务方统一通过 SDK 的 multipleFileTransferService 使用。
- (instancetype)initWithBluetoothCenter:(HwBluetoothCenter *)center
                         transferChannel:(HwJieLiTransferChannel *)transferChannel NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
