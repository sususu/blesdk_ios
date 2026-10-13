#import "HWImageresizerViewController.h"
#import "HwVideoClipPreview.h"
#import "SAVideoRangeSlider.h"
#import "HaWoFFmpegBridge.h"
#import <AVFoundation/AVFoundation.h>

#define JPMargin 16.0

@interface HWImageresizerViewController () <SAVideoRangeSliderDelegate>
@property (nonatomic, weak) JPImageresizerView *imageresizerView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) SAVideoRangeSlider *mySAVideoRangeSlider;
@property (nonatomic, strong) UIActivityIndicatorView *busy;
@property (nonatomic, assign) int startTime;
@property (nonatomic, assign) int endTime;
@property (nonatomic, assign) BOOL isExporting;
@end

@implementation HWImageresizerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = self.configure.bgColor ?: UIColor.blackColor;
    self.startTime = 0;
    self.endTime = self.maxClipSeconds > 0 ? self.maxClipSeconds : 5;
    if (self.dialWidth <= 0) self.dialWidth = 466;
    if (self.dialHeight <= 0) self.dialHeight = 466;
    if (self.maxClipSeconds <= 0) self.maxClipSeconds = 5;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithImage:[UIImage imageNamed:@"icon_complete"]
                                             style:UIBarButtonItemStylePlain
                                             target:self
                                             action:@selector(saveItemClick)];
    if (!self.navigationItem.rightBarButtonItem.image) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(saveItemClick)];
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(cancelClick)];

    [self setupImageresizerView];
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.font = [UIFont systemFontOfSize:14];
        _tipsLabel.textColor = [UIColor colorWithRed:178/255.0 green:178/255.0 blue:178/255.0 alpha:1];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 0;
        NSString *fmt = NSLocalizedString(@"wfs_video_trim_tip", @"Drag to select a clip within %d seconds");
        _tipsLabel.text = [NSString stringWithFormat:fmt, self.maxClipSeconds];
    }
    return _tipsLabel;
}

- (void)setupImageresizerView {
    CGFloat safeBottom = 0;
    CGFloat statusNav = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *w = UIApplication.sharedApplication.windows.firstObject;
        safeBottom = w.safeAreaInsets.bottom;
        statusNav = w.safeAreaInsets.top + 44;
    } else {
        statusNav = 64;
    }

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(JPMargin, JPMargin, JPMargin, JPMargin);
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height;
    self.configure.viewFrame = CGRectMake(0, 0, screenW, screenH - 100 - statusNav - safeBottom);

    if (self.isRoundDial) {
        self.configure.isRoundResize = YES;
    } else {
        self.configure.isShowMidDots = NO;
        self.configure.frameType = JPClassicFrameType;
        self.configure.isRoundResize = NO;
        if (self.dialHeight > 0) {
            self.configure.resizeWHScale = self.dialWidth / self.dialHeight;
        }
    }
    self.configure.contentInsets = contentInsets;

    __weak typeof(self) weakSelf = self;
    self.configure.fixStartBlock = ^{
        [weakSelf showBusy:YES];
    };
    self.configure.fixCompleteBlock = ^(NSURL * _Nonnull cacheURL) {
        [weakSelf showBusy:NO];
    };
    self.configure.fixErrorBlock = ^(NSURL * _Nullable cacheURL, JPImageresizerErrorReason reason) {
        [weakSelf showBusy:NO];
    };

    JPImageresizerView *imageresizerView =
    [JPImageresizerView imageresizerViewWithConfigure:self.configure
                           imageresizerIsCanRecovery:^(BOOL isCanRecovery) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (self.isRoundDial) {
            if (!isCanRecovery) {
                [self.imageresizerView recoveryToRoundResize];
            }
        } else {
            if (!isCanRecovery) {
                [self.imageresizerView recoveryByCurrentResizeWHScale];
            }
        }
    } imageresizerIsPrepareToScale:^(BOOL isPrepareToScale) {
    }];
    [self.view addSubview:imageresizerView];
    self.imageresizerView = imageresizerView;

    [self.view addSubview:self.tipsLabel];
    self.tipsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.tipsLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.tipsLabel.topAnchor constraintEqualToAnchor:imageresizerView.bottomAnchor constant:5],
        [self.tipsLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.tipsLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    ]];

    CGFloat sliderY = screenH - safeBottom - 120;
    self.mySAVideoRangeSlider = [[SAVideoRangeSlider alloc]
                                 initWithFrame:CGRectMake(30, sliderY, screenW - 60, 35)
                                 videoUrl:self.videoURL];
    [self.mySAVideoRangeSlider setPopoverBubbleSize:200 height:25];
    self.mySAVideoRangeSlider.delegate = self;
    self.mySAVideoRangeSlider.minGap = 1;
    self.mySAVideoRangeSlider.maxGap = self.maxClipSeconds;
    [self.view addSubview:self.mySAVideoRangeSlider];

    self.busy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.busy.hidesWhenStopped = YES;
    self.busy.color = UIColor.whiteColor;
    self.busy.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.busy];
    [NSLayoutConstraint activateConstraints:@[
        [self.busy.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.busy.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

#pragma mark - SAVideoRangeSliderDelegate

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    [self setupTimeLeftPosition:leftPosition rightPosition:rightPosition];
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    [self setupTimeLeftPosition:leftPosition rightPosition:rightPosition];
}

- (void)setupTimeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    CGFloat picW = self.mySAVideoRangeSlider.picWidth;
    if (picW <= 0) return;
    self.startTime = (int)(leftPosition / picW);
    self.endTime = (int)(rightPosition / picW);
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat averagePosition = self.startTime;
        CMTime time = CMTimeMakeWithSeconds(averagePosition, self.imageresizerView.playerView.videoObj.timescale);
        CMTime tolerance = CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC);
        [self.imageresizerView.playerView.player seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance];
    });
}

#pragma mark - Actions

- (void)cancelClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveItemClick {
    [self showBusy:YES];
    __weak typeof(self) weakSelf = self;
    [self.imageresizerView cropVideoWithCacheURL:[self setupCacheURL:@"mov"]
                                      errorBlock:^(NSURL *cacheURL, JPImageresizerErrorReason reason) {
        __strong typeof(weakSelf) self = weakSelf;
        self.isExporting = NO;
        [self showBusy:NO];
        [self showAlert:NSLocalizedString(@"wfs_gif_fail", @"Failed")];
    } progressBlock:^(float progress) {
        weakSelf.isExporting = YES;
    } completeBlock:^(JPImageresizerResult *result) {
        __strong typeof(weakSelf) self = weakSelf;
        [self showBusy:NO];
        self.isExporting = NO;
        [self setupHwVideoClipPreview:result.cacheURL];
    }];
}

- (void)setupHwVideoClipPreview:(NSURL *)url {
    if (!url) {
        [self showAlert:NSLocalizedString(@"wfs_gif_fail", @"Failed")];
        return;
    }
    [self showBusy:YES];
    int start = self.startTime;
    int end = self.endTime;
    CGFloat w = self.dialWidth;
    CGFloat h = self.dialHeight;
    BOOL round = self.isRoundDial;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSURL *gifUrl = [self convertVideoToGif:url startTime:start endTime:end width:w height:h];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showBusy:NO];
            if (!gifUrl || ![[NSFileManager defaultManager] fileExistsAtPath:gifUrl.path]) {
                [self showAlert:NSLocalizedString(@"wfs_gif_fail", @"Failed")];
                return;
            }
            HwVideoClipPreview *clipPreview = [[HwVideoClipPreview alloc] init];
            __weak typeof(self) weakSelf = self;
            [clipPreview showViewWithURL:gifUrl useBtnBtnBlock:^{
                __strong typeof(weakSelf) self = weakSelf;
                if (self.backBlock) self.backBlock(gifUrl);
                [self.navigationController popViewControllerAnimated:YES];
            } hideViewBlock:^{
            } isRoundDial:round];
        });
    });
}

- (NSURL *)setupCacheURL:(NSString *)extension {
    NSString *folderPath = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"%.0lf.%@", [[NSDate date] timeIntervalSince1970], extension];
    NSString *cachePath = [folderPath stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:cachePath];
}

- (NSURL *)convertVideoToGif:(NSURL *)videoURL
                   startTime:(int)startTime
                     endTime:(int)endTime
                       width:(CGFloat)width
                      height:(CGFloat)height {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *gifDir = [docs URLByAppendingPathComponent:@"gif" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:gifDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *toFile = [[gifDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif", NSUUID.UUID.UUIDString]] path];

    int duration = MAX(1, endTime - startTime);
    // Same argv as HaWoFit HWImageresizerViewController.convertVideoToGif
    NSArray<NSString *> *args = @[
        @"ffmpeg",
        @"-ss", [NSString stringWithFormat:@"%d", startTime],
        @"-i", videoURL.path ?: @"",
        @"-t", [NSString stringWithFormat:@"%d", duration],
        @"-b:v", @"1M",
        @"-g:v", @"20",
        @"-r", @"12",
        @"-fs", @"1MB",
        @"-vf", [NSString stringWithFormat:@"scale=%.0f:%.0f", width, height],
        toFile,
    ];
    int code = [HaWoFFmpegBridge runWithArguments:args];
    if (code != 0) return nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:toFile]) return nil;
    return [NSURL fileURLWithPath:toFile];
}

- (void)showBusy:(BOOL)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (on) [self.busy startAnimating];
        else [self.busy stopAnimating];
        self.view.userInteractionEnabled = !on;
    });
}

- (void)showAlert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
