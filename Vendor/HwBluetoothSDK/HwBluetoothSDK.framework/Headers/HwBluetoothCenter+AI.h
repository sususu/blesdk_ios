//
//  HwBluetoothCenter+Expand.h
//  HwBluetooth
//
//  Created by Su on 2018/4/5.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"
#import "HwBluetoothDeviceRequestManager.h"
#import "HwMeeting.h"
#import "HwHealthData.h"
#import "HwHealthAnalysisResult.h"

@interface HwBluetoothCenter (AI)

- (HwBluetoothTask *_Nullable)setAppStatus:(HwAppState)appStatus;

- (HwBluetoothTask *_Nullable) setStartRecordingResultWithCode:(int)code
                                                        andMsg:(NSString *_Nullable)msg;

- (HwBluetoothTask *_Nullable) setEndRecordingResultWithCode:(int)code
                                                      andMsg:(NSString *_Nullable)msg;

- (void) setRecordToTextResultWithResult:(NSString *_Nullable)result
                                    code:(int)code
                                  andMsg:(NSString *_Nullable)msg;

- (void) setAiAnswerResultWithResult:(NSString *_Nullable)result
                                code:(int)code
                              andMsg:(NSString *_Nullable)msg;

- (void) setAiTranslateResultWithResult:(NSString *_Nullable)result
                                   code:(int)code
                                    msg:(NSString *_Nullable)msg;

- (void) setAiAgentResultWithResult:(NSString *_Nullable)result
                               code:(int)code
                                msg:(NSString *_Nullable)msg;

- (void) setAiMeetingResult:(HwMeeting *_Nullable)meeting
                       type:(NSInteger)type
                       code:(int)code
                        msg:(NSString *_Nullable)msg;
- (void) notifyAiMeetingHandling;

- (void) setAiHealthAnalysisResult:(HwHealthAnalysisResult *_Nullable)result
                              code:(int)code
                               msg:(NSString *_Nullable)msg;


- (HwBluetoothTask *_Nullable) setAiWatchfacePreviewWithPreviewName:(NSString *_Nullable)previewName
                                                               code:(int)code
                                                             andMsg:(NSString *_Nullable)msg;

- (HwBluetoothTask *_Nullable) setAiWatchfaceResultWithWatchfaceName:(NSString *_Nullable)watchfaceName
                                                                code:(int)code
                                                              andMsg:(NSString *_Nullable)msg;
- (HwBluetoothTask *_Nullable) getAiRecordDataWithCallback:(HwDataCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getMeetingRecordDataWithCallback:(HwDataCallback _Nonnull)callback;


- (HwBluetoothTask *_Nullable) setAiSubscriptionInfoWithType:(NSInteger) type
                                                   startTime:(NSTimeInterval)startTime
                                                     endTime:(NSTimeInterval)endTime
                                                   leftCount:(NSInteger) leftCount;
- (HwBluetoothTask *_Nullable) setAiVoicePlayResultWithCode:(NSInteger)code
                                                        msg:(NSString *_Nullable)msg;

- (void) addAiWatchfaceEnterOrExitListener:(HwAiWatchfaceEnterOrExitCallback _Nonnull)callback;
- (void) removeAiWatchfaceEnterOrExitListener:(HwAiWatchfaceEnterOrExitCallback _Nonnull)callback;
- (void) removeAllAiWatchfaceEnterOrExitListeners;

- (void) addAiAnswerEnterOrExitListener:(HwAiAnswerEnterOrExitCallback _Nonnull)callback;
- (void) removeAiAnswerEnterOrExitListener:(HwAiAnswerEnterOrExitCallback _Nonnull)callback;
- (void) removeAllAiAnswerEnterOrExitListeners;

- (void) addAppStatusRequestListener:(HwAppStatusRequestCallback _Nonnull)callback;
- (void) removeAppStatusRequestListener:(HwAppStatusRequestCallback _Nonnull)callback;
- (void) removeAllAppStatusRequestListeners;

- (void) addStartRecordingRequestListener:(HwStartRecordingCallback _Nonnull)callback;
- (void) removeStartRecordingRequestListener:(HwStartRecordingCallback _Nonnull)callback;
- (void) removeAllStartRecordingRequestListeners;

- (void) addEndRecordingRequestListener:(HwEndRecordingCallback _Nonnull)callback;
- (void) removeEndRecordingRequestListener:(HwEndRecordingCallback _Nonnull)callback;
- (void) removeAllEndRecordingRequestListeners;

- (void) addGenerateAiWatchfaceRequestListener:(HwGenerateAiWatchfaceRequestCallback _Nonnull)callback;
- (void) removeGenerateAiWatchfaceRequestListener:(HwGenerateAiWatchfaceRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiWatchfaceRequestListeners;

- (void) addGenerateAiAnswerRequestListener:(HwGenerateAiAnswerRequestCallback _Nonnull)callback;
- (void) removeGenerateAiAnswerRequestListener:(HwGenerateAiAnswerRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiAnswerRequestListeners;

- (void) addGenerateAiWatchfacePreviewRequestListener:(HwGenerateAiWatchfacePreviewRequestCallback _Nonnull)callback;
- (void) removeGenerateAiWatchfacePreviewRequestListener:(HwGenerateAiWatchfacePreviewRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiWatchfacePreviewRequestListeners;

- (void) addAiEventListener:(HwAiEventCallback _Nonnull)callback;
- (void) removeAiEventListener:(HwAiEventCallback _Nonnull)callback;
- (void) removeAllAiEventListeners;

- (void) addAiSettingUpdateListener:(HwAiSettingUpdateCallback _Nonnull)callback;
- (void) removeAiSettingUpdateListener:(HwAiSettingUpdateCallback _Nonnull)callback;
- (void) removeAllAiSettingUpdateListeners;

- (void) addGenerateAiMeetingRequestListener:(HwGenerateAiMeetingRequestCallback _Nonnull)callback;
- (void) removeGenerateAiMeetingRequestListener:(HwGenerateAiMeetingRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiMeetingRequestListeners;

// 请求设备上传健康分析数据，由ai sdk负责监听处理
- (void)requestHealthAnalysisDataWithCallback:(HwBoolCallback _Nullable)callback;

- (void) addGenerateAiHealthAnalysisRequestListener:(HwGenerateAiHealthAnalysisRequestCallback _Nonnull)callback;
- (void) removeGenerateAiHealthAnalysisRequestListener:(HwGenerateAiHealthAnalysisRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiHealthAnalysisRequestListeners;

- (void) addGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeGenerateAiTranslateRequestListener:(HwGenerateAiTranslateRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiTranslateRequestListeners;

- (void) addGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeGenerateAiAgentResultRequestListener:(HwGenerateAiAgentResultRequestCallback _Nonnull)callback;
- (void) removeAllGenerateAiAgentResultRequestListeners;

- (void) addAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAiAnswerHandlerListener:(HwAiAnswerHandlerCallback _Nonnull)callback;
- (void) removeAllAiAnswerHandlerListeners;

- (void) addAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAiVoicePlayRequestListener:(HwAiVoicePlayRequestCallback _Nonnull)callback;
- (void) removeAllAiVoicePlayRequestListeners;

- (void) addAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAiSubscriptionInfoRequestListener:(HwAiSubscriptionInfoRequestCallback _Nonnull)callback;
- (void) removeAllAiSubscriptionInfoRequestListeners;

@end
