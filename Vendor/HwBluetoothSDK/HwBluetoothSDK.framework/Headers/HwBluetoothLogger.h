//
//  HwBluetoothLogger.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwBluetoothLogLevel) {
    HwBluetoothLogLevelDebug = 0,
    HwBluetoothLogLevelInfo,
    HwBluetoothLogLevelWarn,
    HwBluetoothLogLevelError,
    HwBluetoothLogLevelNone,
};

@protocol HwBluetoothLoggerProtocol <NSObject>

@required
- (void) d:(NSString *)msg;
- (void) i:(NSString *)msg;
- (void) w:(NSString *)msg;
- (void) e:(NSString *)msg;

@end

@interface HwConsoleLogger : NSObject<HwBluetoothLoggerProtocol>

@end

@interface HwBluetoothLogger : NSObject

+ (HwBluetoothLogger *) sharedInstance;

@property(nonatomic, assign) BOOL logOn;
@property(nonatomic, assign) HwBluetoothLogLevel minimumLogLevel;

- (void) setLogger:(id<HwBluetoothLoggerProtocol>)logger;
- (void) setLogTag:(NSString *)tag;

+ (void) d:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void) i:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void) w:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void) e:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end

NS_ASSUME_NONNULL_END
