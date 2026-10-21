//
//  HwDrinkWaterRecord.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>
#import "HwDrinkWaterType.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwDrinkWaterRecord : NSObject

@property(nonatomic, assign) NSInteger recordId;
@property(nonatomic, assign) HwDrinkWaterType drinkType;
@property(nonatomic, assign) NSInteger amount;
@property(nonatomic, assign) NSTimeInterval time;

+ (NSArray<HwDrinkWaterRecord *> *)recordsFromData:(NSData *)data;
+ (NSData *)valueUnitBytesForRecord:(HwDrinkWaterRecord *)record;

@end

NS_ASSUME_NONNULL_END
