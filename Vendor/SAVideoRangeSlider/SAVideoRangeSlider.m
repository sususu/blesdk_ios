//
//  SAVideoRangeSlider.m
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Copyright (c) 2013 Andrei Solovjev - http://solovjev.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SAVideoRangeSlider.h"
#import "HaWoFitClipCompat.h"

@interface SAVideoRangeSlider ()<UIScrollViewDelegate>

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) UIScrollView *bgView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) SASliderLeft *leftThumb;
@property (nonatomic, strong) SASliderRight *rightThumb;
@property (nonatomic) CGFloat frame_width;
@property (nonatomic) int durationSeconds;
//@property (nonatomic) int picWidth;
@property (nonatomic) CGFloat offsetx;
@property (nonatomic) BOOL isScroll;
@property (nonatomic) int difference;
@property (nonatomic, strong) SAResizibleBubble *popoverBubble;

@end

@implementation SAVideoRangeSlider


#define SLIDER_BORDERS_SIZE 6.0f
#define BG_VIEW_BORDERS_SIZE 3.0f


- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        _frame_width = frame.size.width;
        _picWidth = 25;
        //返回大于或者等于指定表达式的最小整数
        int thumbWidth = ceil(frame.size.width*0.05);
        
        _bgView = [[UIScrollView alloc] initWithFrame:CGRectMake(thumbWidth-BG_VIEW_BORDERS_SIZE, 0, frame.size.width-(thumbWidth*2)+BG_VIEW_BORDERS_SIZE*2 + 10, frame.size.height)];
        _bgView.layer.borderColor = [UIColor clearColor].CGColor;
        _bgView.layer.borderWidth = BG_VIEW_BORDERS_SIZE;
        // 隐藏水平滚动条
        [_bgView setShowsHorizontalScrollIndicator:NO];
        // 隐藏垂直滚动条
        [_bgView setShowsVerticalScrollIndicator:NO];
        // 禁止弹动
        [_bgView setBounces:NO];
        _bgView.delegate = self;
        [self addSubview:_bgView];
        
        _videoUrl = videoUrl;
        
        _topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, SLIDER_BORDERS_SIZE)];
        _topBorder.backgroundColor = RGB(51, 51, 51);// [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
        [self addSubview:_topBorder];
        
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-SLIDER_BORDERS_SIZE, frame.size.width, SLIDER_BORDERS_SIZE)];
        _bottomBorder.backgroundColor = RGB(51, 51, 51);//[UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
        [self addSubview:_bottomBorder];
        
        //创建一个左边拖动的View,解决按不到的问题,thumbWidth+10
        _leftThumb = [[SASliderLeft alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        _leftThumb.contentMode = UIViewContentModeLeft;
        _leftThumb.userInteractionEnabled = YES;
        _leftThumb.clipsToBounds = YES;
        _leftThumb.backgroundColor = [UIColor clearColor];
        _leftThumb.layer.borderWidth = 0;
        [self addSubview:_leftThumb];
        
        
        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        [_leftThumb addGestureRecognizer:leftPan];
        
        _rightThumb = [[SASliderRight alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        _rightThumb.contentMode = UIViewContentModeRight;
        _rightThumb.userInteractionEnabled = YES;
        _rightThumb.clipsToBounds = YES;
        _rightThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:_rightThumb];
        
        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        [_rightThumb addGestureRecognizer:rightPan];
        
        //初始化左右的位置
        _rightPosition = frame.size.width;
        _leftPosition = 0;
        
        _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _centerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_centerView];
        
        //创建中心的view,加入手势
        UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
        [_centerView addGestureRecognizer:centerPan];
        
        _popoverBubble = [[SAResizibleBubble alloc] initWithFrame:CGRectMake(0, -50, 100, 50)];
        _popoverBubble.alpha = 1;
        _popoverBubble.backgroundColor = [UIColor clearColor];
        [self addSubview:_popoverBubble];
        
        _bubleText = [[UILabel alloc] initWithFrame:_popoverBubble.frame];
        _bubleText.font = [UIFont systemFontOfSize:10];
        _bubleText.backgroundColor = [UIColor clearColor];
        _bubleText.textColor = [UIColor whiteColor];
        _bubleText.textAlignment = NSTextAlignmentCenter;
        [_popoverBubble addSubview:_bubleText];
        
        [self getMovieFrame];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

//设置时间泡泡的大小
-(void)setPopoverBubbleSize: (CGFloat) width height:(CGFloat)height{
    
    CGRect currentFrame = _popoverBubble.frame;
    currentFrame.size.width = width;
    currentFrame.size.height = height;
    currentFrame.origin.y = -height;
    _popoverBubble.frame = currentFrame;
    
    currentFrame.origin.x = 0;
    currentFrame.origin.y = 0;
    _bubleText.frame = currentFrame;
    
}

//设置最大剪裁时间
-(void)setMaxGap:(NSInteger)maxGap {
    _leftPosition = 0;
    _rightPosition = _picWidth * maxGap;
    if (_picWidth * maxGap > _durationSeconds * _picWidth) {
        _rightPosition = _durationSeconds * _picWidth;
    }
    _maxGap = maxGap;
    [self setTimeLabel:NO];
    if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:rightPosition:)]){
        [_delegate videoRange:self didChangeLeftPosition:self.leftPosition + self.offsetx rightPosition:self.rightPosition + self.offsetx];
    }
}

//设置最小剪裁时间
-(void)setMinGap:(NSInteger)minGap {
    _leftPosition = 0;
    _rightPosition = _picWidth * minGap;
    _minGap = minGap;
}

//通知界面刷新截选得时间
- (void)delegateNotification {
    if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:rightPosition:)]){
        [_delegate videoRange:self didChangeLeftPosition:self.leftPosition + self.offsetx rightPosition:self.rightPosition + self.offsetx];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    self.offsetx = offset.x;
    self.isScroll = YES;
    [self setTimeLabel:NO];
    [self delegateNotification];
}

#pragma mark - Gestures
- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        if (_durationSeconds == 1) {
            return;
        }
        self.isScroll = NO;
        CGPoint translation = [gesture translationInView:self];
        _leftPosition += translation.x;
//        NSLog(@"handleLeftPan----_leftPosition= %lf,_rightPosition = %lf,_picWidth * _durationSeconds = %d",_leftPosition,_rightPosition,_picWidth * _durationSeconds);
        
        if (_leftPosition < 0) {
            _leftPosition = 0;
        }
        CGFloat inset = _leftThumb.frame.size.width;
        
        if (_rightPosition-_leftPosition <= _picWidth + inset) {
            _leftPosition -= translation.x;
        }
        
        if ((self.maxGap > 0) && (self.rightPosition / _picWidth -self.leftPosition / _picWidth > self.maxGap)) {
            _leftPosition -= translation.x;
        }
        
        if ((self.minGap > 0) && ((self.rightPosition + inset) / _picWidth - self.leftPosition / _picWidth < self.minGap)) {
            _leftPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        [self setNeedsLayout];
        [self delegateNotification];
    }
    _popoverBubble.alpha = 1;
    [self setTimeLabel:NO];
}


- (void)handleRightPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        if (_durationSeconds == 1) {
            return;
        }
        self.isScroll = NO;
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        
        NSLog(@"handleRightPan----_leftPosition= %lf,_rightPosition = %lf,_picWidth * _durationSeconds = %d",_leftPosition,_rightPosition,_picWidth * _durationSeconds);
        
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (_rightPosition > _frame_width) {
            _rightPosition = _frame_width;
        }
                
        CGFloat inset = _leftThumb.frame.size.width;
        if (_rightPosition > _picWidth * _durationSeconds + inset) {
            _rightPosition -= translation.x;
        }

        if (_rightPosition-_leftPosition <= _picWidth + inset){
            _rightPosition -= translation.x;
        }
        
        if ((self.maxGap > 0) && (self.rightPosition / _picWidth - self.leftPosition / _picWidth > self.maxGap)) {
            _rightPosition -= translation.x;
        }
        
        if ((self.minGap > 0) && ((self.rightPosition + inset) / _picWidth - self.leftPosition / _picWidth < self.minGap)) {
            _rightPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        [self setNeedsLayout];
        [self delegateNotification];
    }
    _popoverBubble.alpha = 1;
    [self setTimeLabel:NO];
}


- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        if (_durationSeconds == 1) {
            return;
        }
        self.isScroll = NO;
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        _rightPosition += translation.x;
        
//        NSLog(@"handleCenterPan----_leftPosition= %lf,_rightPosition = %lf,_picWidth * _durationSeconds = %d",_leftPosition,_rightPosition,_picWidth * _durationSeconds);
        
        CGFloat inset = _leftThumb.frame.size.width;
        if (_rightPosition > _frame_width || _leftPosition < 0 || _rightPosition > (_durationSeconds * _picWidth + inset)){
            _leftPosition -= translation.x;
            _rightPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        [self setNeedsLayout];
        [self delegateNotification];
        
    }
    _popoverBubble.alpha = 1;
    [self setTimeLabel:YES];
}

- (void)layoutSubviews {
    CGFloat inset = _leftThumb.frame.size.width / 2;
    
    _leftThumb.center = CGPointMake(_leftPosition+inset, _leftThumb.frame.size.height/2);
    _rightThumb.center = CGPointMake(_rightPosition-inset, _rightThumb.frame.size.height/2);
    
    _topBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, 0, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    _bottomBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _bgView.frame.size.height-SLIDER_BORDERS_SIZE, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    _centerView.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _centerView.frame.origin.y, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width, _centerView.frame.size.height);
    
    CGRect frame = _popoverBubble.frame;
    frame.origin.x = _centerView.frame.origin.x+_centerView.frame.size.width/2-frame.size.width/2;
    _popoverBubble.frame = frame;
}

#pragma mark - Video
- (void)getMovieFrame {
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:_videoUrl options:options];

    //得到url的资源,转为asset
//    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:_videoUrl options:nil];
    //初始化AVAssetImageGenerator
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width, _bgView.frame.size.height);
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 600); // 设置帧率
    // 获取视频的原始尺寸
    AVAssetTrack *track = [[myAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize naturalSize = track.naturalSize;
    // 设置渲染尺寸为视频的原始尺寸
    videoComposition.renderSize = naturalSize;
    _picWidth = naturalSize.width / (naturalSize.height / self.frame.size.height);
    // HaWoFit used Watch.videoTime; demo uses maxGap (seconds) instead.
    NSInteger gapSec = self.maxGap > 0 ? self.maxGap : 5;
    if (gapSec * _picWidth >= self.frame.size.width - _picWidth / 2.0) {
        _picWidth = _picWidth / 2.0;
    }

    // 创建视频指令
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [myAsset duration]); // 设置时间范围

    // 创建视频层指令，并设置变换
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[[myAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]];
    [layerInstruction setTransform:CGAffineTransformIdentity atTime:kCMTimeZero]; // 设置变换
    instruction.layerInstructions = @[layerInstruction]; // 将层指令添加到视频指令

    videoComposition.instructions = @[instruction]; // 将视频指令添加到视频合成

    // 现在你可以将videoComposition赋值给my_videoComposition_object
    self.imageGenerator.videoComposition = videoComposition;

    self.imageGenerator.videoComposition = videoComposition;
    self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        
    //得到秒数
    CMTime duration = myAsset.duration;
    _durationSeconds = roundf(CMTimeGetSeconds(duration));
    // 当视频较短时，确保缩略图总宽度至少填满滚动视图宽度
    if (_durationSeconds > 0) {
        CGFloat minContentWidth = _bgView.frame.size.width;
        CGFloat currentContentWidth = _picWidth * _durationSeconds;
        if (currentContentWidth < minContentWidth) {
            _picWidth = minContentWidth / _durationSeconds;
        }
    }
    // 设置滚动范围
    self.bgView.contentSize = CGSizeMake(_picWidth * _durationSeconds, _bgView.frame.size.height);
    // 如果内容宽度仍小于组件宽度，收敛初始右拖拽位置以与内容对齐
    if (_picWidth * _durationSeconds < _frame_width) {
        _rightPosition = _picWidth * _durationSeconds;
        [self setNeedsLayout];
    }
        
    //通过view的宽得到预览图的张数
    int picsCnt = _durationSeconds;
    NSLog(@"%d",picsCnt);
        
    //创建一个可变数组
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    int time4Pic = 0;
    //得到每张预览图应该有的CMTime
    //获取帧率
    CGFloat fps =[[[myAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] nominalFrameRate];
    for (int i=0; i<picsCnt; i++){
        CMTime time =CMTimeMakeWithSeconds(i, fps);
        NSLog(@"时间结构体");
        CMTimeShow(time);
        NSValue *value =[NSValue valueWithCMTime:time];
        [allTimes addObject:value];
    }
        
    NSArray *times = allTimes;
    __block int i = 0;
    
    @weakify(self)
    //根据CMTime 取出image
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
          completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                              AVAssetImageGeneratorResult result, NSError *error) {
        @strongify(self);
        if (result == AVAssetImageGeneratorSucceeded) {
     
            UIImage *videoScreen = [[UIImage alloc] initWithCGImage:image];
            //这里修改了预览图加载慢的问题,放到主线程加载
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
                tmp.contentMode = UIViewContentModeScaleAspectFill;
//                tmp.contentMode = UIViewContentModeScaleAspectFit;
                tmp.layer.minificationFilter = kCAFilterTrilinear;
                [tmp.layer setNeedsDisplay];
                tmp.clipsToBounds = YES;
                CGRect currentFrame = tmp.frame;
                currentFrame.origin.x = i*self.picWidth;
                
                tmp.frame = CGRectMake(i*self.picWidth, 0, self.picWidth, self.bgView.frame.size.height);
                i++;
                [self.bgView addSubview:tmp];
            });
        }
        if (result == AVAssetImageGeneratorFailed) {
                NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        if (result == AVAssetImageGeneratorCancelled) {
                NSLog(@"Canceled");
        }
    }];
   
}

#pragma mark - Properties

//刷新label的时间方法
- (void) setTimeLabel:(BOOL)isCenter {
    self.bubleText.text = [self trimIntervalStr:isCenter];
}

//显示截取时间的秒数
- (NSString *)trimDurationStr {
    int delta = floor(self.rightPosition - self.leftPosition) / _picWidth;
    return [NSString stringWithFormat:@"%d", delta];
}

//获得时间
- (NSString *)trimIntervalStr:(BOOL)isCenter {
    NSLog(@"计算时间：self.leftPosition = %lf,self.rightPosition = %lf,self.offsetx = %lf, _picWidth = %d",self.leftPosition,self.rightPosition,self.offsetx,_picWidth);
    BOOL isLf = NO;
    CGFloat inset = _leftThumb.frame.size.width / 2.0;
    
    if (self.rightPosition - self.leftPosition - _picWidth -inset <= _picWidth && self.rightPosition - self.leftPosition - _picWidth > 0) {
        isLf = YES;
    }
    
    if (isCenter || self.isScroll) {
        isLf = NO;
    }
    
    NSString *from = [self timeToStr:(self.leftPosition + self.offsetx) / _picWidth isLf:isLf];
    NSString *to = [self timeToStr:(self.rightPosition + self.offsetx) / _picWidth isLf:NO];
    [self getDifferenceFrom:from to:to];
    return [NSString stringWithFormat:@"%@ - %@", from, to];
}


- (void)getDifferenceFrom:(NSString *)from to:(NSString *)to {
 
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];

    NSDate *fromDate = [formatter dateFromString:from];
    NSDate *toDate = [formatter dateFromString:to];

    NSTimeInterval difference = [toDate timeIntervalSinceDate:fromDate];
    self.difference = difference;
    NSLog(@"相差的秒数: %f", difference);

}

#pragma mark - Helpers
//获得时间
- (NSString *)timeToStr:(CGFloat)time isLf:(BOOL)isLf {
    // time - seconds
    NSInteger min = 0;
    NSInteger sec = 0;
    if (isLf) {
        sec = ceil(time - min * 60);
        if (sec == _durationSeconds) {
            sec = _durationSeconds - 1;
        }
        if (self.leftPosition < 1) {
            sec = floor(time - min * 60);
        }
    } else {
        sec = floor(time - min * 60);
    }
    
    if (sec > _durationSeconds) {
        sec = _durationSeconds;
    }
    
    min = floor(time / 60);
    NSString *minStr = [NSString stringWithFormat:min >= 10 ? @"%ld" : @"0%ld", min];
    NSString *secStr = [NSString stringWithFormat:sec % 60 >= 10 ? @"%ld" : @"0%ld", sec % 60];
    return [NSString stringWithFormat:@"%@:%@", minStr, secStr];
}

@end
