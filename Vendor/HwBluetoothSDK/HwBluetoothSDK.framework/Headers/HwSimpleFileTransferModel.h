//
//  HwSimpleFileTransferModel.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/11/13.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SimpleFileTransferType) {
    SimpleFileTransferTypeWatchFace = 0x06
};

NS_ASSUME_NONNULL_BEGIN

@interface HwSimpleFileTransferModel : NSObject

@property(nonatomic, assign) SimpleFileTransferType transferType;
@property(nonatomic, strong) NSString *watchFaceID;
@property(nonatomic, strong) NSData *fileData;

@end

NS_ASSUME_NONNULL_END
