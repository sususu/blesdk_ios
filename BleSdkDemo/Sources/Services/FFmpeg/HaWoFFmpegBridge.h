#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Thin wrapper around HaWoFit's vendored FFmpeg 2.8 `ffmpeg_main`.
@interface HaWoFFmpegBridge : NSObject

/// Runs the same CLI entry as HaWoFit (`ffmpeg_main`).
/// Arguments should match HaWoFit argv (including leading `"ffmpeg"`).
/// @return exit code from ffmpeg (0 = success). Does not throw on failure.
+ (int)runWithArguments:(NSArray<NSString *> *)arguments;

@end

NS_ASSUME_NONNULL_END
