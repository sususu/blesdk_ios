//
//  HwBluetoothCenter+SimpleFileTransfer.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/11/13.
//

#import "HwBluetoothCenter.h"
#import "HwSimpleFileTransferModel.h"

typedef void(^SftLogBlock)(NSString *logMessage);

@interface HwBluetoothCenter (SimpleFileTransfer)

- (void)startSimpleFileTransfer:(HwSimpleFileTransferModel *)transferModel
                    readyCallback:(HwBoolCallback)readyCallback
                 progressCallback:(HwBCFloatCallback)progressCallback
                   finishCallback:(HwBoolCallback)finishCallback;

- (void)setSftLogBlock:(SftLogBlock)logBlock;

@end

