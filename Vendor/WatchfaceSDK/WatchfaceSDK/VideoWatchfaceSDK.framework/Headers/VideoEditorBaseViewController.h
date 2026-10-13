//
//  HWImageresizerViewController.h
//  WearlinkSDKSample
//
//  Created by huawo01 on 2024/3/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 gifFliePath：gifFliePath of animated gif after cropping. Because every time the app starts the sandbox path, it needs to be spliced ​​by itself, Documents directory + gifFliePath
 isSuccess：Whether cropping is successful + gifFliePath
 */
typedef void (^HWImageresizerViewControllerBackBlock)(NSString *gifFliePath,BOOL isSuccess);

@interface VideoEditorBaseViewController : UIViewController

//URL
@property (nonatomic, copy) NSURL *videoURL;
//The maximum number of seconds that can be edited
@property (nonatomic, assign) int videoTime;
//Watch screen width
@property (nonatomic, assign) CGFloat watchWidth;
//Watch screen Height
@property (nonatomic, assign) CGFloat watchHeight;
//Callback after cropping
@property (nonatomic, copy) HWImageresizerViewControllerBackBlock backBlock;
//1: Dark mode 2: Light mode 3: Get system theme mode
@property (nonatomic, assign) NSInteger themeType;

@property (nonatomic, copy) NSString *exporting;
@property (nonatomic, copy) NSString *effectPreview;
@property (nonatomic, copy) NSString *cancel;
@property (nonatomic, copy) NSString *confirm;

@end

NS_ASSUME_NONNULL_END
