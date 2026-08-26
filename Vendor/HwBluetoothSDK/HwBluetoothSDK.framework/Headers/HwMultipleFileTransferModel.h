#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MultipleFileTransferPhotoType) {
    MultipleFileTransferPhotoTypePNG = 0x00,
    MultipleFileTransferPhotoTypeJPG = 0x01,
};

typedef NS_ENUM(NSInteger, MultipleFileTransferMusicType) {
    MultipleFileTransferMusicTypeMP3 = 0x00,
    MultipleFileTransferMusicTypeWAV = 0x01,
};

NS_ASSUME_NONNULL_BEGIN

/// 一份待下发的杰理文件资源；不保存会话、通知或蓝牙状态。
@interface HwMultipleFileTransferModel : NSObject

@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, assign) MultipleFileTransferPhotoType photoType;
@property (nonatomic, assign) MultipleFileTransferMusicType musicType;

@end

NS_ASSUME_NONNULL_END
