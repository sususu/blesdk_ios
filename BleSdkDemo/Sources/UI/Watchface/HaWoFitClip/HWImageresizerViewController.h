#import <UIKit/UIKit.h>
#import "JPImageresizerConfigure.h"
#import "JPImageresizerView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HWImageresizerViewControllerBackBlock)(NSURL *gifURL);

/// HaWoFit-aligned video crop page (JPImageresizerView + SAVideoRangeSlider + preview).
@interface HWImageresizerViewController : UIViewController

@property (nonatomic, copy) NSURL *videoURL;
@property (nonatomic, strong) JPImageresizerConfigure *configure;
@property (nonatomic, copy, nullable) HWImageresizerViewControllerBackBlock backBlock;

/// Dial size used for ffmpeg scale=W:H (HaWoFit Watch.product).
@property (nonatomic, assign) CGFloat dialWidth;
@property (nonatomic, assign) CGFloat dialHeight;
@property (nonatomic, assign) BOOL isRoundDial;
/// Max clip length in seconds (HaWoFit Watch.videoTime, demo default 5).
@property (nonatomic, assign) int maxClipSeconds;

@end

NS_ASSUME_NONNULL_END
