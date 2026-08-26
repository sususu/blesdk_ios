//
//  JLImageToWatchfaceHandler.m
//  AiSDK
//
//  Created by kingwear on 2026/2/11.
//

#import "JLImageToWatchfaceHandler.h"
#import "AiDeviceInfo.h"
#import "AiImageUtils.h"
#import "AiSDK.h"
#import "AiLogger.h"
#import "AiFileUtils.h"
#import "HwBluetoothSDK.h"
#import "JLBmpConvertKit/JLBmpConvertKit.h"
#import "WatchfaceSDK/WatchfaceSDK-Swift.h"

@interface JLImageToWatchfaceHandler()

@property(nonatomic, assign) BOOL isCanceled;
@property(nonatomic, strong) UIImage *backgroundImage;
@property(nonatomic, strong) AiDeviceInfo *deviceInfo;
@property(nonatomic, strong) SlifiCustomWatchface *watchface;

@end

@implementation JLImageToWatchfaceHandler

- (JLImageToWatchfaceHandler *) initWithImage:(UIImage *_Nonnull)image
                                        deviceInfo:(AiDeviceInfo *_Nonnull)deviceInfo
{
    self = [super init];
    if (self) {
        self.backgroundImage = image;
        self.deviceInfo = deviceInfo;
    }
    return self;
}

- (void)dealloc
{
    _backgroundImage = nil;
    _deviceInfo = nil;
    _watchface = nil;
}

- (void)cancel {
    self.isCanceled = YES;
}

- (void)generateDone:(NSString *)name
                code:(NSInteger)code
            errorMsg:(NSString *)errorMsg
{
    if (self.isCanceled) {
        return;
    }
    [[AiSDK sharedInstance] watchfaceSyncToDeviceCompleted:self.watchface code:code msg:errorMsg];
    _watchface = nil;
    _backgroundImage = nil;
    _deviceInfo = nil;
}

- (void)start {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.watchface = [self generateWithImage:self.backgroundImage deviceInfo:self.deviceInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncWatchface:self.watchface];
        });
    });
}

- (void) syncWatchface:(SlifiCustomWatchface *)watchface
{
    HwBluetoothDevice *device = [HwBluetoothCenter sharedInstance].connectedDevice;
    if (device == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AiLogger e:@"disconnected"];
            [self generateDone:nil code:HwBCCodeBLEDisconnected errorMsg:[[AiSDK sharedInstance] errorMsgWithCode:HwBCCodeBLEDisconnected]];
        });
        return;
    }
    
    [AiLogger i:@"Start sending watchface..."];
    
    NSMutableArray<HwMultipleFileTransferModel *> *fileModelArr = [NSMutableArray new];
    
    HwMultipleFileTransferModel *trModel = [HwMultipleFileTransferModel new];
    trModel.photoType = MultipleFileTransferPhotoTypeJPG;
    
    UIImage *resizeImage = [AiImageUtils generateFitSizeRoundedImage:self.backgroundImage
                                                               width:self.deviceInfo.width
                                                              height:self.deviceInfo.height
                                                        cornerRadius:self.deviceInfo.cornerRadius
                                                              opaque:true];
    
    NSData *imageData = UIImageJPEGRepresentation(resizeImage, 1);
    
    JLBmpConvertOption *opt = [[JLBmpConvertOption alloc] init];
    opt.convertType = JLBmpConvertType707N_ARGB;
    opt.pixelformat = JLBmpPixelformat_Auto;
    JLImageConvertResult *result = [JLBmpConvert convert:opt ImageData:imageData];
    trModel.fileData = result.outFileData;
    
    trModel.fileName = @"W0102000001";
    [fileModelArr addObject:trModel];
    
    [AiLogger e:@"will sync watchface to device size: %ld", trModel.fileData.length];
    
    [[HwBluetoothSDK sharedInstance].multipleFileTransferService
        startWithFileModels:fileModelArr
               transferType:MultipleFileTransferTypeAIDialImage
              readyCallback:^(BOOL b, NSError *error) {
        } progressCallback:^(float f, NSError *error) {
            [[AiSDK sharedInstance] watchfaceSyncProgressUpdated:f];
            [AiLogger i:@"watchface progress:%f", f];
        } finishCallback:^(BOOL b, NSError *error) {
            if (!b) {
                [AiLogger e:@"sync watchface to device failed: %@", @(error.code)];
                [self generateDone:nil
                               code:AiErrorMakeQjsWatchfaceFailed
                           errorMsg:[[AiSDK sharedInstance] errorMsgWithCode:AiErrorMakeQjsWatchfaceFailed]];
                return;
            }
            [self generateDone:watchface.name code:0 errorMsg:nil];
        }];
}

- (SlifiCustomWatchface *) generateWithImage:(UIImage *)image
                                  deviceInfo:(AiDeviceInfo *)deviceInfo
{
    SlifiCustomWatchface *watchface = [[SlifiCustomWatchface alloc] initWithWidth:deviceInfo.width height:deviceInfo.height];
    watchface.name = [[AiSDK sharedInstance] generateAiWatchfaceName];
    
    UIImage *bgImage = [AiImageUtils generateFitSizeImage:image width:deviceInfo.width height:deviceInfo.height];
    UIImage *preview = [AiImageUtils generateFitSizePreViewImage:image width:deviceInfo.width height:deviceInfo.height];
    
    bgImage = [AiImageUtils generateFitSizeRoundedImage:bgImage width:deviceInfo.width height:deviceInfo.height cornerRadius:deviceInfo.cornerRadius];
    preview = [AiImageUtils generateFitSizeRoundedImage:preview width:deviceInfo.thumbnailWidth height:deviceInfo.thumbnailHeight cornerRadius:deviceInfo.thumbnailCornerRadius];
    
    if (deviceInfo.needPreviewBorder) {
        // 创建与原图相同尺寸的图形上下文
        UIGraphicsBeginImageContextWithOptions(preview.size, NO, preview.scale);
        
        // 先绘制原始图片（完整尺寸）
        [preview drawInRect:CGRectMake(0, 0, preview.size.width, preview.size.height)];
        
        // 获取当前上下文
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // 设置边框参数,没有传就默认是1
        CGFloat borderWidth = (deviceInfo.previewBorderWidth == 0 ? 1.0 : deviceInfo.previewBorderWidth);
        UIColor *borderColor = (deviceInfo.previewBorderColor == nil ? UIColor.whiteColor : deviceInfo.previewBorderColor);
        
        // 创建矩形区域（向内缩进边框宽度的一半，确保边框在图片内部）
        CGRect rect = CGRectInset(CGRectMake(0, 0, preview.size.width, preview.size.height), borderWidth/2.0, borderWidth/2.0);
        
        // 绘制边框（在图片边缘内部绘制）
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, borderWidth);
        
        UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:deviceInfo.thumbnailCornerRadius];
        CGContextAddPath(context, borderPath.CGPath);
        CGContextStrokePath(context);
        
        // 获取处理后的图片（包含原始图片内容和边框）
        preview = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    watchface.backgroundImage = bgImage;
    watchface.thumbnailImage = preview;
    
    QjsTimeWidget *time = [[QjsTimeWidget alloc] initWithTintColor:[UIColor whiteColor]];
    NSInteger timeX = (deviceInfo.width - time.width) / 2;
    NSInteger timeY = 60;
    time.x = timeX;
    time.y = timeY;
    
    NSInteger y = timeY + time.height + 10;
    QjsDateWidget *date = [[QjsDateWidget alloc] initWithTintColor:[UIColor whiteColor]];
    QjsWeekWidget *week = [[QjsWeekWidget alloc] initWithTintColor:[UIColor whiteColor]];
    
    NSInteger x = (deviceInfo.width - date.width - week.width - 4) / 2;
    date.x = x;
    date.y = y;
    
    x = date.x + date.width + 4;
    week.x = x;
    week.y = y;
    
    [watchface addWidget:time];
    [watchface addWidget:date];
    [watchface addWidget:week];
    
    return watchface;
}

@end
