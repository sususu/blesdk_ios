//
//  HwHeartRate.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwHeartRate
 @brief 心率数据模型[heartrate models]
 */
@interface HwHeartRate : NSObject
/*! @brief
 索引[index]
 */
@property(nonatomic, assign) NSUInteger index;
/*! @brief
 时间点[interval time]
 */
@property(nonatomic, assign) NSTimeInterval time;
/*! @brief
 心率值[heartrate value]
 */
@property(nonatomic, assign) NSUInteger bmp;

@property(nonatomic, assign) BOOL resting;

@end

NS_ASSUME_NONNULL_END
