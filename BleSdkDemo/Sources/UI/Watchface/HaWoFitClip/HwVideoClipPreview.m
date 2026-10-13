#import "HwVideoClipPreview.h"
#import <ImageIO/ImageIO.h>

@interface HwVideoClipPreview ()
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *videoImageView;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *useBtn;
@property (nonatomic, copy) NSURL *videPathUrl;
@property (nonatomic, copy) VideoClipPreviewUseBtnBtnBlock useBtnBtnBlock;
@property (nonatomic, copy) HideViewBlock hideViewBlock;
@property (nonatomic, assign) BOOL isRoundDial;
@end

@implementation HwVideoClipPreview

- (void)showViewWithURL:(NSURL *)videPathUrl
         useBtnBtnBlock:(VideoClipPreviewUseBtnBtnBlock)useBtnBtnBlock
          hideViewBlock:(HideViewBlock)hideViewBlock
             isRoundDial:(BOOL)isRoundDial {
    self.useBtnBtnBlock = useBtnBtnBlock;
    self.hideViewBlock = hideViewBlock;
    // Normalize to file URL — HaWoFit sometimes used URLWithString:path which breaks loaders.
    if (videPathUrl.isFileURL) {
        self.videPathUrl = videPathUrl;
    } else if (videPathUrl.path.length) {
        self.videPathUrl = [NSURL fileURLWithPath:videPathUrl.path];
    } else {
        self.videPathUrl = videPathUrl;
    }
    self.isRoundDial = isRoundDial;

    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) { window = w; break; }
    }
    self.frame = window.bounds;
    self.alpha = 0;
    [window addSubview:self];
    [self createUI];

    [UIView animateWithDuration:0.25 animations:^{ self.alpha = 1; }];
}

- (void)createUI {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];

    CGFloat screenW = self.bounds.size.width;
    CGFloat screenH = self.bounds.size.height;
    CGFloat bgW = screenW - 80;
    CGFloat bgH = 326;
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake((screenW - bgW) / 2.0,
                                                           (screenH - bgH) / 2.0,
                                                           bgW, bgH)];
    self.bgView.backgroundColor = UIColor.whiteColor;
    self.bgView.layer.cornerRadius = 16;
    self.bgView.layer.masksToBounds = YES;
    [self addSubview:self.bgView];

    CGFloat imgSideW = self.isRoundDial ? 188 : 152;
    CGFloat imgSideH = self.isRoundDial ? 188 : 186;
    // Match HaWoFit: imageView is sibling of bgView, constrained to its top/center.
    self.videoImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenW - imgSideW) / 2.0,
                                                                        CGRectGetMinY(self.bgView.frame) + 18,
                                                                        imgSideW, imgSideH)];
    self.videoImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.videoImageView.clipsToBounds = YES;
    self.videoImageView.layer.cornerRadius = self.isRoundDial ? 94 : 40;
    self.videoImageView.layer.masksToBounds = YES;
    self.videoImageView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];

    UIImage *gif = [self animatedImageFromGIF:self.videPathUrl];
    if (!gif) {
        // Fallback: path load / first frame
        NSData *data = [NSData dataWithContentsOfURL:self.videPathUrl];
        if (data) gif = [UIImage imageWithData:data];
        if (!gif) gif = [UIImage imageWithContentsOfFile:self.videPathUrl.path];
    }
    self.videoImageView.image = gif;
    if (gif.images.count > 1) {
        [self.videoImageView startAnimating];
    }
    [self addSubview:self.videoImageView];

    self.useBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.useBtn.frame = CGRectMake(20, bgH - 8 - 46 - 4 - 44, bgW - 40, 44);
    self.useBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.55 blue:1 alpha:1];
    self.useBtn.layer.cornerRadius = 22;
    self.useBtn.layer.masksToBounds = YES;
    [self.useBtn setTitle:NSLocalizedString(@"wfs_video_use_gif", @"Use") forState:UIControlStateNormal];
    [self.useBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.useBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.useBtn addTarget:self action:@selector(useBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.useBtn];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelBtn.frame = CGRectMake(20, bgH - 8 - 46, bgW - 40, 46);
    [self.cancelBtn setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:[UIColor colorWithWhite:0.45 alpha:1] forState:UIControlStateNormal];
    self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.cancelBtn];
}

- (UIImage *)animatedImageFromGIF:(NSURL *)url {
    if (!url) return nil;
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data.length) {
        // Retry via path in case URL scheme was wrong.
        data = [NSData dataWithContentsOfFile:url.path];
    }
    if (!data.length) return nil;

    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!src) return [UIImage imageWithData:data];

    size_t count = CGImageSourceGetCount(src);
    if (count == 0) {
        CFRelease(src);
        return [UIImage imageWithData:data];
    }
    if (count == 1) {
        CGImageRef cg = CGImageSourceCreateImageAtIndex(src, 0, NULL);
        UIImage *img = cg ? [UIImage imageWithCGImage:cg] : [UIImage imageWithData:data];
        if (cg) CGImageRelease(cg);
        CFRelease(src);
        return img;
    }

    NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t i = 0; i < count; i++) {
        CGImageRef cg = CGImageSourceCreateImageAtIndex(src, i, NULL);
        if (!cg) continue;
        [frames addObject:[UIImage imageWithCGImage:cg]];
        CGImageRelease(cg);

        double delay = 0.1;
        CFDictionaryRef props = CGImageSourceCopyPropertiesAtIndex(src, i, NULL);
        if (props) {
            CFDictionaryRef gif = CFDictionaryGetValue(props, kCGImagePropertyGIFDictionary);
            if (gif) {
                CFNumberRef unclamped = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                CFNumberRef clamped = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                if (unclamped) CFNumberGetValue(unclamped, kCFNumberDoubleType, &delay);
                else if (clamped) CFNumberGetValue(clamped, kCFNumberDoubleType, &delay);
            }
            CFRelease(props);
        }
        // Clamp near-zero delays (common in ffmpeg GIFs) — same idea as SDWebImage.
        if (delay < 0.011) delay = 0.1;
        duration += delay;
    }
    CFRelease(src);
    if (frames.count == 0) return [UIImage imageWithData:data];
    if (duration <= 0) duration = frames.count * 0.08;
    return [UIImage animatedImageWithImages:frames duration:duration];
}

- (void)hideView {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)useBtnClick {
    if (self.useBtnBtnBlock) self.useBtnBtnBlock();
    [self hideView];
}

- (void)cancelBtnClick {
    if (self.hideViewBlock) self.hideViewBlock();
    [self hideView];
}

@end
