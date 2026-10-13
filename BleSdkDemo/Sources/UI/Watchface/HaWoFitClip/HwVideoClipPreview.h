#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^VideoClipPreviewUseBtnBtnBlock)(void);
typedef void (^HideViewBlock)(void);

/// HaWoFit HwVideoClipPreview — GIF preview overlay with Use / Cancel.
@interface HwVideoClipPreview : UIView

- (void)showViewWithURL:(NSURL *)videPathUrl
         useBtnBtnBlock:(VideoClipPreviewUseBtnBtnBlock)useBtnBtnBlock
          hideViewBlock:(HideViewBlock)hideViewBlock
             isRoundDial:(BOOL)isRoundDial;

- (void)hideView;

@end

NS_ASSUME_NONNULL_END
