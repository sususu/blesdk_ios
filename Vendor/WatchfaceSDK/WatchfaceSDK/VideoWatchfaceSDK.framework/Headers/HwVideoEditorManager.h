//
//  HwVideoEditorManager.h
//  VideoWatchfaceSDK
//
//  Created by huawo01 on 2024/8/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwVideoEditorManager : NSObject

+ (instancetype) sharedInstance;

//Watch screen width
@property (nonatomic, assign) CGFloat watchWidth;
//Watch screen Height
@property (nonatomic, assign) CGFloat watchHeight;

- (NSURL *)getGifDirectoryURL;

- (NSURL *)convertVideoToGif:(NSURL *)videoURL startTime:(int)startTime endTime:(int)endTime;

@end

NS_ASSUME_NONNULL_END
