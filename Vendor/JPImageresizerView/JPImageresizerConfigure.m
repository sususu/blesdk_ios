//
//  JPImageresizerConfigure.m
//  JPImageresizerView
//
//  Created by 周健平 on 2018/4/22.
//

#import "JPImageresizerConfigure.h"
#import "HaWoFitClipCompat.h"

@implementation JPImageresizerConfigure

#pragma mark - Configure

+ (instancetype)defaultConfigure {
    JPImageresizerConfigure *configure = [[self alloc] init];
    configure
    .jp_viewFrame([UIScreen mainScreen].bounds)
    .jp_blurEffect(nil)
    .jp_frameType(JPConciseFrameType)
    .jp_animationCurve(JPAnimationCurveEaseOut)
    .jp_strokeColor(UIColor.whiteColor)
    .jp_bgColor(UIColor.blackColor)
    .jp_maskAlpha(0.75)
    .jp_resizeWHScale(0.0)
    .jp_isRoundResize(NO)
    .jp_maskImage(nil)
    .jp_isArbitrarily(YES)
    .jp_edgeLineIsEnabled(YES)
    .jp_contentInsets(UIEdgeInsetsMake(16, 16, 16, 16))
    .jp_borderImage(nil)
    .jp_borderImageRectInset(CGPointZero)
    .jp_maximumZoomScale(10.0)
    .jp_isShowMidDots(YES)
    .jp_isBlurWhenDragging(NO)
    .jp_isShowGridlinesWhenIdle(NO)
    .jp_isShowGridlinesWhenDragging(YES)
    .jp_gridCount(3)
    .jp_isLoopPlaybackGIF(NO)
    .jp_isCleanHistoryAfterInitial(YES);
    return configure;
}

+ (JPImageresizerConfigure *)lightBlurMaskTypeConfigure {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure
        .jp_blurEffect([UIBlurEffect effectWithStyle:UIBlurEffectStyleLight])
        .jp_bgColor(UIColor.whiteColor)
        .jp_maskAlpha(0.25)
        .jp_strokeColor([UIColor colorWithRed:(56.0 / 255.0) green:(121.0 / 255.0) blue:(242.0 / 255.0) alpha:1.0]);
    return configure;
}

+ (JPImageresizerConfigure *)darkBlurMaskTypeConfigure {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure
        .jp_blurEffect([UIBlurEffect effectWithStyle:UIBlurEffectStyleDark])
        .jp_bgColor(UIColor.blackColor)
        .jp_maskAlpha(0.25);
    return configure;
}

+ (instancetype)defaultConfigureWithImage:(UIImage *)image make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure.image = image;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)defaultConfigureWithImageData:(NSData *)imageData make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure.imageData = imageData;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)defaultConfigureWithVideoURL:(NSURL *)videoURL
                                        make:(JPImageresizerConfigureMakeBlock)make
                               fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                               fixStartBlock:(JPVoidBlock)fixStartBlock
                            fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                            fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure.videoURL = videoURL;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)defaultConfigureWithVideoAsset:(AVURLAsset *)videoAsset
                                          make:(JPImageresizerConfigureMakeBlock)make
                                 fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                                 fixStartBlock:(JPVoidBlock)fixStartBlock
                              fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                              fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self defaultConfigure];
    configure.videoAsset = videoAsset;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)lightBlurMaskTypeConfigureWithImage:(UIImage *)image make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self lightBlurMaskTypeConfigure];
    configure.image = image;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)lightBlurMaskTypeConfigureWithImageData:(NSData *)imageData make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self lightBlurMaskTypeConfigure];
    configure.imageData = imageData;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)lightBlurMaskTypeConfigureWithVideoURL:(NSURL *)videoURL
                                                  make:(JPImageresizerConfigureMakeBlock)make
                                         fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                                         fixStartBlock:(JPVoidBlock)fixStartBlock
                                      fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                                      fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self lightBlurMaskTypeConfigure];
    configure.videoURL = videoURL;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)lightBlurMaskTypeConfigureWithVideoAsset:(AVURLAsset *)videoAsset
                                                    make:(JPImageresizerConfigureMakeBlock)make
                                           fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                                           fixStartBlock:(JPVoidBlock)fixStartBlock
                                        fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                                        fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self lightBlurMaskTypeConfigure];
    configure.videoAsset = videoAsset;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)darkBlurMaskTypeConfigureWithImage:(UIImage *)image make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self darkBlurMaskTypeConfigure];
    configure.image = image;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)darkBlurMaskTypeConfigureWithImageData:(NSData *)imageData make:(JPImageresizerConfigureMakeBlock)make {
    JPImageresizerConfigure *configure = [self darkBlurMaskTypeConfigure];
    configure.imageData = imageData;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)darkBlurMaskTypeConfigureWithVideoURL:(NSURL *)videoURL
                                                 make:(JPImageresizerConfigureMakeBlock)make
                                        fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                                        fixStartBlock:(JPVoidBlock)fixStartBlock
                                     fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                                     fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self darkBlurMaskTypeConfigure];
    configure.videoURL = videoURL;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

+ (instancetype)darkBlurMaskTypeConfigureWithVideoAsset:(AVURLAsset *)videoAsset
                                                   make:(JPImageresizerConfigureMakeBlock)make
                                          fixErrorBlock:(JPImageresizerErrorBlock)fixErrorBlock
                                          fixStartBlock:(JPVoidBlock)fixStartBlock
                                       fixProgressBlock:(JPExportVideoProgressBlock)fixProgressBlock
                                       fixCompleteBlock:(JPExportVideoCompleteBlock)fixCompleteBlock {
    JPImageresizerConfigure *configure = [self darkBlurMaskTypeConfigure];
    configure.videoAsset = videoAsset;
    configure.fixErrorBlock = fixErrorBlock;
    configure.fixStartBlock = fixStartBlock;
    configure.fixProgressBlock = fixProgressBlock;
    configure.fixCompleteBlock = fixCompleteBlock;
    !make ? : make(configure);
    return configure;
}

#pragma mark - History

- (BOOL)isSavedHistory {
    return !JPCropHistoryIsNull(self.history);
}

- (void)cleanHistory {
    JPCropHistory history = self.history;
    if (JPCropHistoryIsNull(history)) return;
    history.viewFrame = CGRectNull;
    self.history = history;
}

#pragma mark - Setter

- (void)setImage:(UIImage *)image {
    _image = image;
    if (image) {
        _imageData = nil;
        _videoURL = nil;
        _videoAsset = nil;
    }
}

- (void)setImageData:(NSData *)imageData {
    _imageData = imageData;
    if (imageData) {
        _image = nil;
        _videoURL = nil;
        _videoAsset = nil;
    }
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    if (videoURL) {
        _image = nil;
        _imageData = nil;
        _videoAsset = nil;
    }
}

- (void)setVideoAsset:(AVURLAsset *)videoAsset {
    _videoAsset = videoAsset;
    if (videoAsset) {
        _image = nil;
        _imageData = nil;
        _videoURL = nil;
    }
}

#pragma mark - Block

- (JPImageresizerConfigure *(^)(CGRect))jp_viewFrame {
    @weakify(self);
    return ^(CGRect viewFrame) {
        @strongify(self);
        self.viewFrame = viewFrame;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(JPImageresizerFrameType))jp_frameType {
    @weakify(self);
    return ^(JPImageresizerFrameType frameType) {
        @strongify(self);
        self.frameType = frameType;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(JPAnimationCurve))jp_animationCurve {
    @weakify(self);
    return ^(JPAnimationCurve animationCurve) {
        @strongify(self);
        self.animationCurve = animationCurve;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIBlurEffect *))jp_blurEffect {
    @weakify(self);
    return ^(UIBlurEffect *blurEffect) {
        @strongify(self);
        self.blurEffect = blurEffect;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIColor *))jp_bgColor {
    @weakify(self);
    return ^(UIColor *bgColor) {
        @strongify(self);
        self.bgColor = bgColor;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(CGFloat))jp_maskAlpha {
    @weakify(self);
    return ^(CGFloat maskAlpha) {
        @strongify(self);
        self.maskAlpha = maskAlpha;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIColor *))jp_strokeColor {
    @weakify(self);
    return ^(UIColor *strokeColor) {
        @strongify(self);
        self.strokeColor = strokeColor;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(CGFloat))jp_resizeWHScale {
    @weakify(self);
    return ^(CGFloat resizeWHScale) {
        @strongify(self);
        self.resizeWHScale = resizeWHScale;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isRoundResize {
    @weakify(self);
    return ^(BOOL isRoundResize) {
        @strongify(self);
        self.isRoundResize = isRoundResize;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIImage *))jp_maskImage {
    @weakify(self);
    return ^(UIImage *maskImage) {
        @strongify(self);
        self.maskImage = maskImage;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isArbitrarily {
    @weakify(self);
    return ^(BOOL isArbitrarily) {
        @strongify(self);
        self.isArbitrarily = isArbitrarily;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_edgeLineIsEnabled {
    @weakify(self);
    return ^(BOOL edgeLineIsEnabled) {
        @strongify(self);
        self.edgeLineIsEnabled = edgeLineIsEnabled;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIEdgeInsets))jp_contentInsets {
    @weakify(self);
    return ^(UIEdgeInsets contentInsets) {
        @strongify(self);
        self.contentInsets = contentInsets;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isClockwiseRotation {
    @weakify(self);
    return ^(BOOL isClockwiseRotation) {
        @strongify(self);
        self.isClockwiseRotation = isClockwiseRotation;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(UIImage *))jp_borderImage {
    @weakify(self);
    return ^(UIImage *borderImage) {
        @strongify(self);
        self.borderImage = borderImage;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(CGPoint))jp_borderImageRectInset {
    @weakify(self);
    return ^(CGPoint borderImageRectInset) {
        @strongify(self);
        self.borderImageRectInset = borderImageRectInset;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(CGFloat))jp_maximumZoomScale {
    @weakify(self);
    return ^(CGFloat maximumZoomScale) {
        @strongify(self);
        self.maximumZoomScale = maximumZoomScale;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isShowMidDots {
    @weakify(self);
    return ^(BOOL isShowMidDots) {
        @strongify(self);
        self.isShowMidDots = isShowMidDots;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isBlurWhenDragging {
    @weakify(self);
    return ^(BOOL isBlurWhenDragging) {
        @strongify(self);
        self.isBlurWhenDragging = isBlurWhenDragging;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isShowGridlinesWhenIdle {
    @weakify(self);
    return ^(BOOL isShowGridlinesWhenIdle) {
        @strongify(self);
        self.isShowGridlinesWhenIdle = isShowGridlinesWhenIdle;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isShowGridlinesWhenDragging {
    @weakify(self);
    return ^(BOOL isShowGridlinesWhenDragging) {
        @strongify(self);
        self.isShowGridlinesWhenDragging = isShowGridlinesWhenDragging;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(NSUInteger))jp_gridCount {
    @weakify(self);
    return ^(NSUInteger gridCount) {
        @strongify(self);
        self.gridCount = gridCount;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isLoopPlaybackGIF {
    @weakify(self);
    return ^(BOOL isLoopPlaybackGIF) {
        @strongify(self);
        self.isLoopPlaybackGIF = isLoopPlaybackGIF;
        return self;
    };
}

- (JPImageresizerConfigure *(^)(BOOL))jp_isCleanHistoryAfterInitial {
    @weakify(self);
    return ^(BOOL isCleanHistoryAfterInitial) {
        @strongify(self);
        self.isCleanHistoryAfterInitial = isCleanHistoryAfterInitial;
        return self;
    };
}

@end
