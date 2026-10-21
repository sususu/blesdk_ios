//
//  HwStanding.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2026/8/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwStanding : NSObject

@property(nonatomic, assign) NSUInteger index;
@property(nonatomic, assign) NSTimeInterval time;
@property(nonatomic, assign) BOOL match;

@end

NS_ASSUME_NONNULL_END
